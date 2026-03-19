import { usePlayerContext } from "@/contexts/PlayerContext";
import { BookType } from "@/types/AppTypes";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { Image, Text, TouchableOpacity, View } from "react-native";

export default function BookItem({ book }: { book: BookType }) {
  const { setCurrentBook, status, player } = usePlayerContext();
  const router = useRouter();
  const handlePress = () => {
    if (status.playing) {
      player.pause();
    }
    setCurrentBook(book);
    router.push("/player-screen");
  };
  const handleLongPress = () => {
    console.log("longpress: " + book.title);
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
          2h 20m
        </Text>
      </View>
    </TouchableOpacity>
  );
}
