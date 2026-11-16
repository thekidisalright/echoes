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
  const { openBook } = usePlayerContext();
  const router = useRouter();
  const measuredDuration = book.chapters.reduce((total, chapter) => total + (chapter.duration || 0), 0);
  const progress = measuredDuration > 0
    ? book.chapters.reduce((total, chapter, index) => total + (index < book.savedChapterIndex ? chapter.duration || 0 : 0), 0) + (book.savedPosition || 0)
    : book.savedChapterIndex;
  const handlePress = async () => {
    await openBook(book, false);
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
        <Text className="text-[#d5d4cf] text-sm font-semibold" numberOfLines={1}>
          {book.title}
        </Text>
        <Text className="text-neutral-400 text-sm mb-1" numberOfLines={1}>
          {book.author || "Autor desconhecido"}
        </Text>
        <ProgressBar
          duration={measuredDuration || book.chapters.length}
          currentTime={progress}
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
