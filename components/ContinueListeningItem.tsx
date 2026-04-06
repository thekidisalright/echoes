import { useLibraryContext } from "@/contexts/LibraryContext";
import { usePlayerContext } from "@/contexts/PlayerContext";
import { BookType } from "@/types/AppTypes";
import { Ionicons, MaterialIcons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { Image, Text, TouchableOpacity, View } from "react-native";
import ProgressBar from "./ProgressBar";

export default function ContinueListeningItem({
  status,
  book,
}: {
  status: string;
  book: BookType;
}) {
  const { setCurrentBook, saveProgress } = usePlayerContext();
  const { updateBook } = useLibraryContext();
  const router = useRouter();
  const handlePress = async () => {
    await saveProgress();
    setCurrentBook(book);
    await updateBook(book.id, { lastPlayedAt: Date.now() });
    router.push("/player-screen");
  };
  return (
    <TouchableOpacity
      onPress={handlePress}
      className="flex-row items-center h-[80px] gap-3 border-b border-b-neutral-700"
    >
      {book.coverImageUri ? (
        <Image
          source={{ uri: book.coverImageUri }}
          className="w-16 h-16 object-cover rounded-md border border-neutral-700"
          resizeMode="cover"
        />
      ) : (
        <View className="w-16 h-16 flex justify-center items-center bg-neutral-700 rounded-md border border-neutral-700">
          <Ionicons name="image-outline" color={"#737373"} size={24} />
        </View>
      )}
      <View className="flex-col flex-1 h-14 justify-between">
        <Text className="text-white text-sm font-semibold" numberOfLines={1}>
          {book.title}
        </Text>
        <Text className="text-neutral-400 text-sm mb-1" numberOfLines={1}>
          {book.author ? book.author : "Unknown"}
        </Text>
        <ProgressBar
          duration={book.chapters.length || 100}
          currentTime={book.savedChapterIndex + 1 || 50}
        />
      </View>
      <View className="w-14 flex-col items-center">
        {status ? (
          <MaterialIcons
            name="equalizer"
            color={status === "playing" ? "#D4A017" : "#a3a3a3"}
            size={18}
          />
        ) : (
          <Ionicons name="time" color={"#a3a3a3"} size={18} />
        )}
      </View>
    </TouchableOpacity>
  );
}
