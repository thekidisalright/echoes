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
  useState,
} from "react";

import { BookType } from "@/types/AppTypes";

interface PlayerContextType {
  currentBook: BookType | null;
  setCurrentBook: Dispatch<SetStateAction<BookType | null>>;
  currentChapterIndex: number | null;
  setCurrentChapterIndex: Dispatch<SetStateAction<number | null>>;
  player: AudioPlayer;
  status: AudioStatus;
}

export const PlayerContext = createContext<PlayerContextType | undefined>(
  undefined,
);

export const PlayerProvider = ({ children }: { children: React.ReactNode }) => {
  const [currentBook, setCurrentBook] = useState<BookType | null>(null);
  const [currentChapterIndex, setCurrentChapterIndex] = useState<number>(0);
  const audioSource = currentBook?.chapters[currentChapterIndex].uri;
  const player = useAudioPlayer(audioSource, { updateInterval: 200 });
  const playerStatus = useAudioPlayerStatus(player);

  useEffect(() => {
    setAudioModeAsync({
      playsInSilentMode: true,
      shouldPlayInBackground: true,
      interruptionMode: "doNotMix",
    });
  }, []);

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
