import { BookType } from "@/types/AppTypes";
import AsyncStorage from "@react-native-async-storage/async-storage";
import {
  AudioPlayer,
  AudioStatus,
  setAudioModeAsync,
  useAudioPlayer,
  useAudioPlayerStatus,
} from "expo-audio";
import {
  createContext,
  Dispatch,
  SetStateAction,
  useContext,
  useEffect,
  useRef,
  useState,
} from "react";
import { AppState } from "react-native";
import { useLibraryContext } from "./LibraryContext";

interface PlayerContextType {
  currentBook: BookType | null;
  setCurrentBook: Dispatch<SetStateAction<BookType | null>>;
  currentChapterIndex: number | null;
  setCurrentChapterIndex: Dispatch<SetStateAction<number>>;
  skip: {
    forward: () => void;
    back: () => void;
  };
  player: AudioPlayer;
  status: AudioStatus;
}

export const PlayerContext = createContext<PlayerContextType | undefined>(
  undefined,
);

export const PlayerProvider = ({ children }: { children: React.ReactNode }) => {
  const hasLoadedInitialBook = useRef(false);
  const { updateBook, books } = useLibraryContext();
  const pendingSeekTime = useRef<number | null>(null);
  // Configurações da reprodução de áudio no dispositivo
  useEffect(() => {
    setAudioModeAsync({
      playsInSilentMode: true,
      shouldPlayInBackground: true,
      interruptionMode: "doNotMix",
    });
  }, []);

  const [currentBook, setCurrentBook] = useState<BookType | null>(null);
  const [currentChapterIndex, setCurrentChapterIndex] = useState<number>(0);
  const lastBookTitleRef = useRef<string | null>(null);
  const audioSource = currentBook?.chapters?.[currentChapterIndex]?.uri;
  const player = useAudioPlayer(audioSource, { updateInterval: 100 });
  const playerStatus = useAudioPlayerStatus(player);
  const forward = () => {
    if (!currentBook) return;
    if (currentChapterIndex < currentBook.chapters.length - 1) {
      setCurrentChapterIndex((prev) => prev + 1);
    } else {
      setCurrentChapterIndex(0);
    }
  };
  const back = () => {
    if (!currentBook) return;
    if (currentChapterIndex !== 0) {
      setCurrentChapterIndex((prev) => prev - 1);
    }
  };

  // Verifica se o player e playerStatus já foram carregados e avança o áudio para onde havia parado anteriormente.
  useEffect(() => {
    const isReadyToSeek = playerStatus && playerStatus.duration > 0;
    if (
      pendingSeekTime.current !== null &&
      pendingSeekTime.current > 0 &&
      isReadyToSeek
    ) {
      player.seekTo(pendingSeekTime.current);
      pendingSeekTime.current = null;
    }
  }, [playerStatus.duration, player]);

  // Define como livro atual o livro que estava tocando quando o app foi fechado
  useEffect(() => {
    const bootPlayer = async () => {
      if (books.length > 0 && !hasLoadedInitialBook.current) {
        try {
          const lastBook = await AsyncStorage.getItem("@lastPlayed");
          if (lastBook) {
            const foundBook = books.find((b) => b.id === lastBook);
            if (foundBook) {
              setCurrentBook(foundBook);
              setCurrentChapterIndex(foundBook.savedChapterIndex || 0);
              pendingSeekTime.current = foundBook.savedPosition || 0;
            }
          }
          hasLoadedInitialBook.current = true;
        } catch (error) {
          console.error("Error while initializing player : ", error);
        }
      }
    };

    bootPlayer();
  }, [books]);

  // Se a faixa atual acabou, executa a função de avançar faixa
  useEffect(() => {
    if (playerStatus.didJustFinish && currentBook) {
      forward();
    }
  }, [playerStatus.didJustFinish, currentBook]);

  // Decide se o áudio deve começar a tocar sozinho ou se deve esperar.
  useEffect(() => {
    if (currentBook && player) {
      player.seekTo(0);

      const isSameBook = lastBookTitleRef.current === currentBook.title;
      if (isSameBook) {
        player.play();
      } else {
        lastBookTitleRef.current = currentBook.title;
      }
    }
  }, [currentChapterIndex, currentBook]);

  const saveProgress = async () => {
    if (currentBook && player) {
      const currentPosition = player.currentTime;
      await updateBook(currentBook.id, {
        savedChapterIndex: currentChapterIndex,
        savedPosition: currentPosition,
      });
      await AsyncStorage.setItem("@lastPlayed", currentBook.id);
    }
  };

  // Salva progresso ao fechar ou minimizar o app
  useEffect(() => {
    const subscription = AppState.addEventListener("change", (nextAppState) => {
      if (nextAppState === "background" || nextAppState === "inactive") {
        saveProgress();
      }
    });

    return () => subscription.remove();
  }, [currentBook, currentChapterIndex, player]);

  const value = {
    currentBook,
    setCurrentBook,
    currentChapterIndex,
    player,
    status: playerStatus,
    setCurrentChapterIndex,
    skip: { forward, back },
  };
  return (
    <PlayerContext.Provider value={value}>{children}</PlayerContext.Provider>
  );
};

export function usePlayerContext() {
  const player = useContext(PlayerContext);

  if (player === undefined) {
    throw new Error("usePlayerContext must be used with a PlayerContext");
  }

  return player;
}
