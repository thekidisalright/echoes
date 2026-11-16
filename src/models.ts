export type Chapter = { id: string; name: string; uri: string; trackNumber?: number; duration?: number };
export type Bookmark = { id: string; bookId: string; chapterId: string; position: number; createdAt: number };
export type Book = {
  id: string;
  sourceId: string;
  title: string;
  author: string;
  coverImageUri?: string;
  chapters: Chapter[];
  savedChapterIndex: number;
  savedPosition: number;
  totalDuration?: number;
  lastPlayedAt?: number;
  sourceAvailable: boolean;
};
export type LibrarySource = { id: string; uri: string; name: string; lastScannedAt: number; available: boolean; importMode?: "one-book" | "books-in-folders" };
