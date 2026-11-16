import { Alert } from "react-native";
import { Directory, File } from "expo-file-system";
import { parseBlob } from "music-metadata-browser";
import { createContext, ReactNode, useCallback, useContext, useEffect, useMemo, useState } from "react";
import type { Book, LibrarySource } from "@/src/models";
import { getLibrarySort, initStorage, listBooks, listSources, removeSource as deleteSource, saveLibrarySort, saveScannedSource, updateBookDetails as storeBookDetails } from "@/src/storage";

type FolderMode = "one-book" | "books-in-folders";
type BookDetails = { title: string; author: string; coverImageUri?: string };
type LibraryContextType = {
  books: Book[]; sources: LibrarySource[]; loading: boolean; importing: boolean; importStatus: string;
  sortOrder: "recent" | "title"; setSortOrder: (value: "recent" | "title") => Promise<void>;
  refresh: () => Promise<void>; importFolder: () => Promise<void>; importFiles: () => Promise<void>;
  rescanSource: (source: LibrarySource) => Promise<void>; removeSource: (source: LibrarySource) => Promise<void>;
  updateBookDetails: (bookId: string, details: BookDetails) => Promise<void>;
};
export const LibraryContext = createContext<LibraryContextType | undefined>(undefined);

const audioExt = /\.(mp3|m4a|m4b)$/i;
const imageExt = /\.(jpe?g|png|webp)$/i;
const natural = new Intl.Collator(undefined, { numeric: true, sensitivity: "base" });
function cleanTitle(name: string) { return name.replace(/\.[^.]+$/, "").replace(/^\d+[\s._-]+/, "").replace(/[._]+/g, " ").trim() || name; }
function trackNumber(name: string) { const m = name.match(/^\s*(?:track\s*)?(\d{1,3})(?:[\s._-]|$)/i); return m ? Number(m[1]) : undefined; }
function folderCovers(files: File[]) {
  const images = files.filter(f => imageExt.test(f.name)).sort((a, b) => natural.compare(a.name, b.name));
  return { preferred: images.find(f => /^(cover|folder|front|artwork|album)(?:[-_ .]|$)/i.test(f.name))?.uri, fallback: images[0]?.uri };
}
function dataUri(bytes: Uint8Array, mime: string) {
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"; let out = "";
  for (let i = 0; i < bytes.length; i += 3) { const a = bytes[i], b = bytes[i + 1], c = bytes[i + 2]; out += alphabet[a >> 2] + alphabet[((a & 3) << 4) | ((b ?? 0) >> 4)] + (b === undefined ? "=" : alphabet[((b & 15) << 2) | ((c ?? 0) >> 6)]) + (c === undefined ? "=" : alphabet[c & 63]); }
  return `data:${mime};base64,${out}`;
}
function sortAudio(files: File[]) {
  return files.filter(file => audioExt.test(file.name)).sort((a, b) => {
    const at = trackNumber(a.name), bt = trackNumber(b.name);
    if (at !== undefined && bt !== undefined) return at - bt || natural.compare(a.name, b.name);
    if (at !== undefined) return -1; if (bt !== undefined) return 1;
    return natural.compare(a.name, b.name);
  });
}
async function makeBook(dir: Directory, files: File[], sourceId: string, skipUris: Set<string>): Promise<Book | null> {
  const audio = sortAudio(files).filter(file => !skipUris.has(file.uri));
  if (!audio.length) return null;
  const metadata = await Promise.all(audio.map(async file => { try { return await parseBlob(file, { duration: true }); } catch { return null; } }));
  const cover = folderCovers(files); const embedded = metadata.map(m => m?.common.picture?.[0]).find(Boolean);
  const tagged = metadata.find(m => m?.common.album || m?.common.artist || m?.common.albumartist);
  const chapters = audio.map((file, index) => ({ id: file.uri, name: metadata[index]?.common.title?.trim() || cleanTitle(file.name), uri: file.uri,
    trackNumber: metadata[index]?.common.track.no || trackNumber(file.name), duration: metadata[index]?.format.duration }));
  return { id: dir.uri, sourceId, title: tagged?.common.album?.trim() || dir.name || cleanTitle(audio[0].name),
    author: tagged?.common.albumartist?.trim() || tagged?.common.artist?.trim() || "",
    coverImageUri: cover.preferred || (embedded ? dataUri(embedded.data, embedded.format) : cover.fallback), chapters,
    savedChapterIndex: 0, savedPosition: 0, totalDuration: chapters.reduce((sum, chapter) => sum + (chapter.duration || 0), 0) || undefined, sourceAvailable: true };
}
async function scanTree(root: Directory, sourceId: string, mode: FolderMode, skipUris: Set<string>, status: (message: string) => void): Promise<Book[]> {
  const entriesByDirectory: { dir: Directory; files: File[] }[] = [];
  const walk = (dir: Directory) => {
    let entries: (Directory | File)[];
    try { entries = dir.list(); } catch { return; }
    const files = entries.filter((entry): entry is File => entry instanceof File);
    if (files.some(file => audioExt.test(file.name))) entriesByDirectory.push({ dir, files });
    for (const child of entries.filter((entry): entry is Directory => entry instanceof Directory)) walk(child);
  };
  walk(root);
  if (mode === "one-book") {
    const allFiles = entriesByDirectory.flatMap(entry => entry.files).filter(file => audioExt.test(file.name));
    status(`Lendo ${allFiles.length} arquivo(s) de áudio…`);
    const book = await makeBook(root, allFiles, sourceId, skipUris);
    return book ? [book] : [];
  }
  const books: Book[] = [];
  for (let index = 0; index < entriesByDirectory.length; index++) {
    const entry = entriesByDirectory[index]; status(`Lendo pasta ${index + 1} de ${entriesByDirectory.length}…`);
    const book = await makeBook(entry.dir, entry.files, sourceId, skipUris);
    if (book) books.push(book);
  }
  return books;
}
function askFolderMode(): Promise<FolderMode | null> {
  return new Promise(resolve => Alert.alert("Como organizar esta pasta?", "Escolha como os arquivos de áudio devem virar livros.", [
    { text: "A pasta inteira é um livro", onPress: () => resolve("one-book") },
    { text: "Cada pasta é um livro", onPress: () => resolve("books-in-folders") },
    { text: "Cancelar", style: "cancel", onPress: () => resolve(null) },
  ], { cancelable: true, onDismiss: () => resolve(null) }));
}

export function LibraryProvider({ children }: { children: ReactNode }) {
  const [books, setBooks] = useState<Book[]>([]); const [sources, setSources] = useState<LibrarySource[]>([]);
  const [loading, setLoading] = useState(true); const [importing, setImporting] = useState(false); const [importStatus, setImportStatus] = useState("");
  const [sortOrder, setSortOrderState] = useState<"recent" | "title">("recent");
  const refresh = useCallback(async () => { await initStorage(); const [nextBooks, nextSources, nextSort] = await Promise.all([listBooks(), listSources(), getLibrarySort()]); setBooks(nextBooks); setSources(nextSources); setSortOrderState(nextSort); setLoading(false); }, []);
  useEffect(() => { void refresh().catch(error => { console.warn("Falha ao abrir biblioteca", error); setLoading(false); }); }, [refresh]);
  const importFolder = useCallback(async () => {
    let started = false;
    try {
      const dir = await Directory.pickDirectoryAsync(); if (!dir) return;
      setImporting(true); started = true; setImportStatus("Escolha como organizar esta pasta…");
      const mode = await askFolderMode(); if (!mode) return;
      setImportStatus("Preparando leitura da pasta…");
      const existingUris = new Set(books.filter(book => book.sourceId !== dir.uri).flatMap(book => book.chapters.map(chapter => chapter.uri)));
      const scanned = await scanTree(dir, dir.uri, mode, existingUris, setImportStatus);
      setImportStatus("Salvando livros na biblioteca…");
      await saveScannedSource({ id: dir.uri, uri: dir.uri, name: dir.name || "Pasta de áudio", lastScannedAt: Date.now(), available: true, importMode: mode }, scanned);
      await refresh();
      if (!scanned.length) Alert.alert("Nenhum arquivo novo encontrado", "Esta pasta não contém áudio compatível que ainda não esteja na biblioteca.");
    } catch (error) { Alert.alert("Não foi possível importar a pasta", "Verifique o acesso à pasta e tente selecioná-la novamente."); console.warn(error); }
    finally { if (started) { setImporting(false); setImportStatus(""); } }
  }, [books, refresh]);
  const importFiles = useCallback(async () => {
    let started = false;
    try {
      const result = await File.pickFileAsync({ multipleFiles: true, mimeTypes: ["audio/*"] });
      if (result.canceled) return;
      const selected = sortAudio(result.result);
      if (!selected.length) { Alert.alert("Nenhum áudio selecionado", "Escolha arquivos MP3, M4A ou M4B."); return; }
      setImporting(true); started = true; setImportStatus(`Lendo ${selected.length} arquivo(s) de áudio…`);
      const existingUris = new Set(books.flatMap(book => book.chapters.map(chapter => chapter.uri)));
      const unique = selected.filter(file => !existingUris.has(file.uri));
      if (!unique.length) { Alert.alert("Arquivos já adicionados", "Todos os arquivos selecionados já estão na biblioteca."); return; }
      const sourceId = `files:${Date.now()}`; const metadata = await Promise.all(unique.map(async file => { try { return await parseBlob(file, { duration: true }); } catch { return null; } }));
      const tagged = metadata.find(item => item?.common.album || item?.common.artist || item?.common.albumartist);
      const chapters = unique.map((file, index) => ({ id: file.uri, uri: file.uri, name: metadata[index]?.common.title?.trim() || cleanTitle(file.name),
        trackNumber: metadata[index]?.common.track.no || trackNumber(file.name), duration: metadata[index]?.format.duration }));
      const book: Book = { id: sourceId, sourceId, title: tagged?.common.album?.trim() || cleanTitle(unique[0].name),
        author: tagged?.common.albumartist?.trim() || tagged?.common.artist?.trim() || "", chapters, savedChapterIndex: 0, savedPosition: 0,
        totalDuration: chapters.reduce((sum, chapter) => sum + (chapter.duration || 0), 0) || undefined, sourceAvailable: true };
      setImportStatus("Salvando livro na biblioteca…");
      await saveScannedSource({ id: sourceId, uri: sourceId, name: "Arquivos selecionados", lastScannedAt: Date.now(), available: true }, [book]); await refresh();
    } catch (error) { Alert.alert("Não foi possível adicionar os arquivos", "Escolha novamente os arquivos de áudio."); console.warn(error); }
    finally { if (started) { setImporting(false); setImportStatus(""); } }
  }, [books, refresh]);
  const rescanSource = useCallback(async (source: LibrarySource) => {
    try {
      setImporting(true); setImportStatus("Preparando leitura da pasta…"); const dir = new Directory(source.uri);
      const scanned = await scanTree(dir, source.id, source.importMode || "books-in-folders", new Set(), setImportStatus);
      await saveScannedSource({ ...source, lastScannedAt: Date.now(), available: true }, scanned); await refresh();
    } catch { Alert.alert("Acesso à pasta expirou", "Selecione novamente a pasta original para atualizar este audiobook."); }
    finally { setImporting(false); setImportStatus(""); }
  }, [refresh]);
  const removeSource = useCallback(async (source: LibrarySource) => { await deleteSource(source.id); await refresh(); }, [refresh]);
  const updateBookDetails = useCallback(async (bookId: string, details: BookDetails) => { await storeBookDetails(bookId, details); await refresh(); }, [refresh]);
  const setSortOrder = useCallback(async (value: "recent" | "title") => { setSortOrderState(value); await saveLibrarySort(value); }, []);
  const value = useMemo<LibraryContextType>(() => ({ books, sources, loading, importing, importStatus, sortOrder, setSortOrder, refresh, importFolder, importFiles, rescanSource, removeSource, updateBookDetails }),
    [books, sources, loading, importing, importStatus, sortOrder, setSortOrder, refresh, importFolder, importFiles, rescanSource, removeSource, updateBookDetails]);
  return <LibraryContext.Provider value={value}>{children}</LibraryContext.Provider>;
}
export function useLibraryContext() { const value = useContext(LibraryContext); if (!value) throw new Error("LibraryProvider ausente"); return value; }
