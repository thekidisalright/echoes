import AsyncStorage from "@react-native-async-storage/async-storage";
import * as SQLite from "expo-sqlite";
import type { Book, Bookmark, Chapter, LibrarySource } from "./models";
import { File } from "expo-file-system";

export const db = SQLite.openDatabaseAsync("echoes.db");
let initPromise: Promise<void> | null = null;
export function initStorage() {
  if (!initPromise) initPromise = initialize();
  return initPromise;
}

async function initialize() {
  const database = await db;
  await database.execAsync(`PRAGMA journal_mode=WAL;
    CREATE TABLE IF NOT EXISTS sources(id TEXT PRIMARY KEY, uri TEXT NOT NULL, name TEXT NOT NULL, lastScannedAt INTEGER NOT NULL, available INTEGER NOT NULL DEFAULT 1, importMode TEXT);
    CREATE TABLE IF NOT EXISTS books(id TEXT PRIMARY KEY, sourceId TEXT NOT NULL, title TEXT NOT NULL, author TEXT NOT NULL DEFAULT '', coverUri TEXT, lastPlayedAt INTEGER);
    CREATE TABLE IF NOT EXISTS chapters(id TEXT PRIMARY KEY, bookId TEXT NOT NULL, title TEXT NOT NULL, uri TEXT NOT NULL, chapterOrder INTEGER NOT NULL, trackNumber INTEGER, duration REAL);
    CREATE TABLE IF NOT EXISTS progress(bookId TEXT PRIMARY KEY, chapterId TEXT NOT NULL, position REAL NOT NULL, updatedAt INTEGER NOT NULL);
    CREATE TABLE IF NOT EXISTS bookmarks(id TEXT PRIMARY KEY, bookId TEXT NOT NULL, chapterId TEXT NOT NULL, position REAL NOT NULL, createdAt INTEGER NOT NULL);
    CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY, value TEXT NOT NULL);`);
  const bookColumns = await database.getAllAsync<{name:string}>("PRAGMA table_info(books)");
  const sourceColumns = await database.getAllAsync<{name:string}>("PRAGMA table_info(sources)");
  if (!sourceColumns.some(c => c.name === "importMode")) await database.execAsync("ALTER TABLE sources ADD COLUMN importMode TEXT");
  if (!bookColumns.some(c => c.name === "sourceId")) await database.execAsync("ALTER TABLE books ADD COLUMN sourceId TEXT NOT NULL DEFAULT ''");
  if (!bookColumns.some(c => c.name === "author")) await database.execAsync("ALTER TABLE books ADD COLUMN author TEXT NOT NULL DEFAULT ''");
  if (!bookColumns.some(c => c.name === "coverUri")) await database.execAsync("ALTER TABLE books ADD COLUMN coverUri TEXT");
  if (!bookColumns.some(c => c.name === "titleOverride")) await database.execAsync("ALTER TABLE books ADD COLUMN titleOverride TEXT");
  if (!bookColumns.some(c => c.name === "authorOverride")) await database.execAsync("ALTER TABLE books ADD COLUMN authorOverride TEXT");
  if (!bookColumns.some(c => c.name === "coverOverride")) await database.execAsync("ALTER TABLE books ADD COLUMN coverOverride TEXT");
  if (!bookColumns.some(c => c.name === "coverCustomized")) await database.execAsync("ALTER TABLE books ADD COLUMN coverCustomized INTEGER NOT NULL DEFAULT 0");
  await database.execAsync("UPDATE books SET sourceId=id WHERE sourceId=''; INSERT OR IGNORE INTO sources(id,uri,name,lastScannedAt,available) SELECT sourceId,sourceId,title,COALESCE(lastPlayedAt,0),1 FROM books WHERE sourceId<>'';");
  await migrateLegacy(database);
}

async function migrateLegacy(database: SQLite.SQLiteDatabase) {
  const marker = await database.getFirstAsync<{ value: string }>("SELECT value FROM settings WHERE key='legacy-v1'");
  if (marker) return;
  const [rawBooks, lastPlayed] = await Promise.all([AsyncStorage.getItem("@books"), AsyncStorage.getItem("@lastPlayed")]);
  const legacy = rawBooks ? JSON.parse(rawBooks) as any[] : [];
  await database.withExclusiveTransactionAsync(async tx => {
    for (const old of legacy) {
      const sourceId = old.id || old.chapters?.[0]?.uri || `legacy-${old.title}`;
      await tx.runAsync("INSERT OR IGNORE INTO sources(id,uri,name,lastScannedAt,available) VALUES(?,?,?,?,1)", sourceId, sourceId, old.title || "Biblioteca importada", Date.now());
      await tx.runAsync("INSERT OR IGNORE INTO books(id,sourceId,title,author,coverUri,lastPlayedAt) VALUES(?,?,?,?,?,?)", old.id, sourceId, old.title || "Sem título", old.author || "", old.coverImageUri || null, old.lastPlayedAt || null);
      for (let i = 0; i < (old.chapters || []).length; i++) {
        const ch = old.chapters[i];
        await tx.runAsync("INSERT OR IGNORE INTO chapters(id,bookId,title,uri,chapterOrder) VALUES(?,?,?,?,?)", ch.uri, old.id, ch.name || ch.title || `Capítulo ${i + 1}`, ch.uri, i);
      }
      const saved = old.chapters?.[old.savedChapterIndex || 0];
      if (saved) await tx.runAsync("INSERT OR IGNORE INTO progress(bookId,chapterId,position,updatedAt) VALUES(?,?,?,?)", old.id, saved.uri, old.savedPosition || 0, Date.now());
    }
    if (lastPlayed) await tx.runAsync("INSERT OR REPLACE INTO settings(key,value) VALUES('lastPlayed',?)", lastPlayed);
    await tx.runAsync("INSERT INTO settings(key,value) VALUES('legacy-v1','done')");
  });
}

export async function listSources(): Promise<LibrarySource[]> {
  await initStorage(); const d = await db;
  return (await d.getAllAsync<any>("SELECT * FROM sources ORDER BY lastScannedAt DESC")).map(r => ({ ...r, available: !!r.available }));
}

export async function listBooks(): Promise<Book[]> {
  await initStorage(); const d = await db;
  const rows = await d.getAllAsync<any>(`SELECT b.*, p.chapterId AS savedChapterId, p.position AS savedPosition, s.available AS sourceAvailable
    FROM books b LEFT JOIN progress p ON p.bookId=b.id LEFT JOIN sources s ON s.id=b.sourceId ORDER BY COALESCE(b.lastPlayedAt,0) DESC, b.title COLLATE NOCASE`);
  return Promise.all(rows.map(async row => {
    const chapters = await d.getAllAsync<any>("SELECT id,title AS name,uri,trackNumber,duration FROM chapters WHERE bookId=? ORDER BY chapterOrder", row.id) as Chapter[];
    const savedIndex = chapters.findIndex(ch => ch.id === row.savedChapterId);
    const durations = chapters.reduce((n, ch) => n + (ch.duration || 0), 0);
    let available = row.sourceAvailable !== 0;
    try { if (chapters.length) available = available && new File(chapters[0].uri).exists; } catch { available = false; }
    return { id: row.id, sourceId: row.sourceId, title: row.titleOverride ?? row.title, author: row.authorOverride ?? row.author ?? "", coverImageUri: row.coverCustomized ? row.coverOverride || undefined : row.coverUri || undefined, chapters,
      savedChapterIndex: Math.max(0, savedIndex), savedPosition: row.savedPosition || 0, totalDuration: durations || undefined,
      lastPlayedAt: row.lastPlayedAt || undefined, sourceAvailable: available };
  }));
}

export async function saveScannedSource(source: LibrarySource, scanned: Book[]) {
  await initStorage(); const d = await db; const now = Date.now();
  await d.withExclusiveTransactionAsync(async tx => {
    await tx.runAsync("INSERT INTO sources(id,uri,name,lastScannedAt,available,importMode) VALUES(?,?,?,?,1,?) ON CONFLICT(id) DO UPDATE SET uri=excluded.uri,name=excluded.name,lastScannedAt=excluded.lastScannedAt,available=1,importMode=COALESCE(excluded.importMode,sources.importMode)", source.id, source.uri, source.name, now, source.importMode || null);
    for (const book of scanned) {
      await tx.runAsync("INSERT INTO books(id,sourceId,title,author,coverUri) VALUES(?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET sourceId=excluded.sourceId,title=excluded.title,author=excluded.author,coverUri=COALESCE(excluded.coverUri,books.coverUri)", book.id, source.id, book.title, book.author, book.coverImageUri || null);
      for (let i = 0; i < book.chapters.length; i++) {
        const ch = book.chapters[i];
        await tx.runAsync("INSERT INTO chapters(id,bookId,title,uri,chapterOrder,trackNumber,duration) VALUES(?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET title=excluded.title,uri=excluded.uri,chapterOrder=excluded.chapterOrder,trackNumber=excluded.trackNumber", ch.id, book.id, ch.name, ch.uri, i, ch.trackNumber || null, ch.duration || null);
      }
      const chapterIds = book.chapters.map(ch => ch.id);
      if (chapterIds.length) {
        const placeholders = chapterIds.map(() => "?").join(",");
        await tx.runAsync(`DELETE FROM chapters WHERE bookId=? AND id NOT IN (${placeholders})`, book.id, ...chapterIds);
      } else {
        await tx.runAsync("DELETE FROM chapters WHERE bookId=?", book.id);
      }
    }
    const bookIds = scanned.map(book => book.id);
    const existing = await tx.getAllAsync<{ id: string }>("SELECT id FROM books WHERE sourceId=?", source.id);
    for (const row of existing) {
      if (!bookIds.includes(row.id)) {
        await tx.runAsync("DELETE FROM bookmarks WHERE bookId=?", row.id);
        await tx.runAsync("DELETE FROM progress WHERE bookId=?", row.id);
        await tx.runAsync("DELETE FROM chapters WHERE bookId=?", row.id);
        await tx.runAsync("DELETE FROM books WHERE id=?", row.id);
      }
    }
  });
}

export async function updateBookDetails(bookId: string, details: { title: string; author: string; coverImageUri?: string }) {
  await initStorage(); const d = await db;
  await d.runAsync("UPDATE books SET titleOverride=?,authorOverride=?,coverOverride=?,coverCustomized=1 WHERE id=?", details.title.trim(), details.author.trim(), details.coverImageUri || null, bookId);
}

export async function removeSource(sourceId: string) {
  await initStorage(); const d = await db;
  await d.withExclusiveTransactionAsync(async tx => {
    await tx.runAsync("DELETE FROM bookmarks WHERE bookId IN (SELECT id FROM books WHERE sourceId=?)", sourceId);
    await tx.runAsync("DELETE FROM progress WHERE bookId IN (SELECT id FROM books WHERE sourceId=?)", sourceId);
    await tx.runAsync("DELETE FROM chapters WHERE bookId IN (SELECT id FROM books WHERE sourceId=?)", sourceId);
    await tx.runAsync("DELETE FROM books WHERE sourceId=?", sourceId);
    await tx.runAsync("DELETE FROM sources WHERE id=?", sourceId);
  });
}

export async function savePlayback(bookId: string, chapterId: string, position: number) {
  await initStorage(); const d = await db; const now = Date.now();
  await d.runAsync("INSERT INTO progress(bookId,chapterId,position,updatedAt) VALUES(?,?,?,?) ON CONFLICT(bookId) DO UPDATE SET chapterId=excluded.chapterId,position=excluded.position,updatedAt=excluded.updatedAt", bookId, chapterId, Math.max(0, position), now);
  await d.runAsync("UPDATE books SET lastPlayedAt=? WHERE id=?", now, bookId);
}
export async function saveLastPlayed(bookId: string) { await initStorage(); const d = await db; await d.runAsync("INSERT OR REPLACE INTO settings(key,value) VALUES('lastPlayed',?)", bookId); }
export async function getLastPlayed() { await initStorage(); const d = await db; return (await d.getFirstAsync<{value:string}>("SELECT value FROM settings WHERE key='lastPlayed'"))?.value || null; }
export async function getLibrarySort(): Promise<"recent" | "title"> {
  await initStorage(); const d = await db;
  const value = (await d.getFirstAsync<{ value: string }>("SELECT value FROM settings WHERE key='librarySort'"))?.value;
  return value === "title" ? "title" : "recent";
}
export async function saveLibrarySort(value: "recent" | "title") {
  await initStorage(); const d = await db;
  await d.runAsync("INSERT OR REPLACE INTO settings(key,value) VALUES('librarySort',?)", value);
}
export async function addBookmark(bookId: string, chapterId: string, position: number): Promise<Bookmark> {
  await initStorage(); const d = await db; const mark = { id: `${bookId}:${chapterId}:${Math.round(position)}:${Date.now()}`, bookId, chapterId, position, createdAt: Date.now() };
  await d.runAsync("INSERT INTO bookmarks(id,bookId,chapterId,position,createdAt) VALUES(?,?,?,?,?)", mark.id, bookId, chapterId, position, mark.createdAt); return mark;
}
export async function listBookmarks(bookId: string): Promise<Bookmark[]> { await initStorage(); const d = await db; return d.getAllAsync<Bookmark>("SELECT * FROM bookmarks WHERE bookId=? ORDER BY createdAt DESC", bookId); }
export async function removeBookmark(id: string) { await initStorage(); const d = await db; await d.runAsync("DELETE FROM bookmarks WHERE id=?", id); }
