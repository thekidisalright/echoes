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

import { BookType } from "@/types/AppTypes";

interface PlayerContextType {
  currentBook: BookType | null;
  setCurrentBook: Dispatch<SetStateAction<BookType | null>>;
  currentChapterIndex: number | null;
  setCurrentChapterIndex: Dispatch<SetStateAction<number>>;
  player: AudioPlayer;
  status: AudioStatus;
}

export const PlayerContext = createContext<PlayerContextType | undefined>(
  undefined,
);

export const PlayerProvider = ({ children }: { children: React.ReactNode }) => {
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

  useEffect(() => {
    if (playerStatus.didJustFinish && currentBook) {
      if (currentChapterIndex < currentBook.chapters.length - 1) {
        setCurrentChapterIndex((prev) => prev + 1);
      } else {
        setCurrentChapterIndex(0);
      }
    }
  }, [playerStatus.didJustFinish, currentBook]);

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

  const value = {
    currentBook,
    setCurrentBook,
    currentChapterIndex,
    player,
    status: playerStatus,
    setCurrentChapterIndex,
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
