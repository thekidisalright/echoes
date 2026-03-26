import { useLibraryContext } from "@/contexts/LibraryContext";
import { usePlayerContext } from "@/contexts/PlayerContext";
import { BookType } from "@/types/AppTypes";
import { Ionicons } from "@expo/vector-icons";
import { createAudioPlayer } from "expo-audio";
import { useRouter } from "expo-router";
import { useEffect } from "react";
import { Image, Text, TouchableOpacity, View } from "react-native";

export default function BookItem({ book }: { book: BookType }) {
  const { setCurrentBook, saveProgress } = usePlayerContext();
  const { updateBook } = useLibraryContext();
  useEffect(() => {
    const calculateTotalDuration = async () => {
      if (book.totalDuration) return;

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
                  resolve(status.duration);
                  tempPlayer.release();
                }
              },
            );
          });
          sumSeconds += duration;
        }
        await updateBook(book.id, { totalDuration: sumSeconds });
      } catch (error) {
        console.error("Error while trying to fetch the book duration: ", error);
      }
    };

    calculateTotalDuration();
  }, [book.totalDuration, book.id]);
  const router = useRouter();
  const handlePress = async () => {
    await saveProgress();
    setCurrentBook(book);
    await updateBook(book.id, { lastPlayedAt: Date.now() });
    router.push("/player-screen");
  };
  const handleLongPress = () => {
    console.log("longpress: " + book.title);
  };
  const formatTime = (timeInSeconds: number) => {
    const hours = Math.floor(timeInSeconds / 3600);
    const minutes = Math.floor((timeInSeconds % 3600) / 60);

    if (hours > 0) {
      return `${hours}h ${minutes.toString().padStart(2, "0")}m`;
    }
    return `${minutes}m`;
  };
  return (
    <TouchableOpacity
      className="w-[48%] mb-4 rounded-xl"
      onLongPress={handleLongPress}
      onPress={handlePress}
      activeOpacity={0.5}
    >
      <View className="w-full">
        <View
          className={
            book.coverImageUri
              ? "overflow-hidden aspect-[3/4] w-full rounded-xl mb-1"
              : "flex-row justify-center items-center bg-neutral-700 opacity-50 aspect-[3/4] w-full rounded-xl mb-1"
          }
        >
          {book.coverImageUri ? (
            <Image
              source={{ uri: book.coverImageUri }}
              className="w-full h-full"
              resizeMode="cover"
            />
          ) : (
            <Ionicons name="image-outline" color={"#737373"} size={48} />
          )}
        </View>
        <Text className="text-white text-sm font-medium" numberOfLines={1}>
          {book.title ? book.title : "Untitled"}
        </Text>
        <Text className="text-neutral-400 text-xs" numberOfLines={1}>
          {book.author ? book.author : "Unknown"}
        </Text>
        <Text className="text-neutral-400 text-xs mt-0.5" numberOfLines={1}>
          {book.totalDuration ? formatTime(book.totalDuration) : "Loading..."}
        </Text>
      </View>
    </TouchableOpacity>
  );
}
