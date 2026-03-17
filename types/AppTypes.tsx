export interface BookType {
  title: string;
  cover: string;
  author: string;
  chapters: {
    name: string;
    uri: string;
  }[];
}
