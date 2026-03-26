export interface BookType {
  id: string;
  title: string;
  chapters: {
    name: string;
    uri: string;
  }[];
  coverImageUri?: string;
  author?: string;
  savedChapterIndex: number;
  savedPosition: number;
  totalDuration?: number;
  lastPlayedAt?: number;
}
