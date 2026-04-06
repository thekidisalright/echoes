import { BookType } from "@/types/AppTypes";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { createAudioPlayer } from "expo-audio";
import {
  createContext,
  ReactNode,
  useContext,
  useEffect,
  useRef,
  useState,
} from "react";

interface LibraryContextType {
  books: BookType[];
  saveBooksToLibrary: (newBooks: BookType[]) => Promise<void>;
  updateBook: (id: string, updates: Partial<BookType>) => Promise<void>;
}

export const LibraryContext = createContext<LibraryContextType | undefined>(
  undefined,
);

export const LibraryProvider = ({ children }: { children: ReactNode }) => {
  const [books, setBooks] = useState<BookType[]>([]);
  const isCalculating = useRef(false);

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
        console.error("Erro ao carregar livros: ", error);
      }
    };

    loadBooks();
  }, []);

  useEffect(() => {
    if (isCalculating.current) return;
    const booksWithoutDuration = books.filter((b) => !b.totalDuration);
    if (booksWithoutDuration.length === 0) return;
    isCalculating.current = true;
    const calculateDurations = async () => {
      for (const book of booksWithoutDuration) {
        try {
          let sumSeconds = 0;

          for (const chapter of book.chapters) {
            const duration = await new Promise<number>((resolve) => {
              const tempPlayer = createAudioPlayer(chapter.uri);
              const listener = tempPlayer.addListener(
                "playbackStatusUpdate",
                (status) => {
                  if (status.duration > 0) {
                    listener.remove();
                    tempPlayer.release();
                    resolve(status.duration);
                  }
                },
              );
            });
            sumSeconds += duration;
          }
          await updateBook(book.id, { totalDuration: sumSeconds });
        } catch (error) {
          console.error(
            "Error while trying to fetch the book duration: ",
            error,
          );
        }
      }
      isCalculating.current = false;
    };

    calculateDurations();
  }, [books]);

  const saveBooksToLibrary = async (newBooks: BookType[]) => {
    try {
      setBooks(newBooks);
      const booksString = JSON.stringify(newBooks);
      await AsyncStorage.setItem("@books", booksString);
    } catch (error) {
      console.error("Erro ao salvar livros: ", error);
    }
  };

  const updateBook = async (id: string, updates: Partial<BookType>) => {
    try {
      let updatedBooks: BookType[] = [];

      setBooks((prev) => {
        updatedBooks = prev.map((book) =>
          book.id === id ? { ...book, ...updates } : book,
        );
        return updatedBooks;
      });

      await AsyncStorage.setItem("@books", JSON.stringify(updatedBooks));
    } catch (error) {
      console.error("Error while updating book: ", error);
    }
  };

  return (
    <LibraryContext.Provider value={{ books, saveBooksToLibrary, updateBook }}>
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
