import { BookType } from "@/types/AppTypes";
import AsyncStorage from "@react-native-async-storage/async-storage";
import {
  createContext,
  ReactNode,
  useContext,
  useEffect,
  useState,
} from "react";

interface LibraryContextType {
  books: BookType[];
  saveBooksToLibrary: (newBooks: BookType[]) => Promise<void>;
}

export const LibraryContext = createContext<LibraryContextType | undefined>(
  undefined,
);

export const LibraryProvider = ({ children }: { children: ReactNode }) => {
  const [books, setBooks] = useState<BookType[]>([]);

  useEffect(() => {
    const loadBooks = async () => {
      try {
        const booksString = await AsyncStorage.getItem("@books");
        if (booksString) {
          const booksJSON = JSON.parse(booksString);
          setBooks(booksJSON);
        }
      } catch (error) {
        setBooks([]);
        console.error("Erro ao carregar livros:", error);
      }
    };

    loadBooks();
  }, []);

  const saveBooksToLibrary = async (newBooks: BookType[]) => {
    try {
      setBooks(newBooks);
      const booksString = JSON.stringify(newBooks);
      await AsyncStorage.setItem("@books", booksString);
    } catch (error) {
      console.error("Erro ao salvar livros:", error);
    }
  };

  return (
    <LibraryContext.Provider value={{ books, saveBooksToLibrary }}>
      {children}
    </LibraryContext.Provider>
  );
};

export function useLibraryContext() {
  const library = useContext(LibraryContext);

  if (library === undefined) {
    throw new Error("useLibraryContext must be used with LibraryContext");
  }

  return library;
}
