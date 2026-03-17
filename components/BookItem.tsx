import { Ionicons } from "@expo/vector-icons";
import { Image, Text, View } from "react-native";

interface BookType {
  title: string;
  cover: string;
  author: string;
}

export default function BookItem({ book }: { book: BookType }) {
  return (
    <View className="w-[48%] mb-4">
      <View
        className={
          book.cover
            ? "overflow-hidden aspect-[3/4] w-full rounded-xl mb-1"
            : "flex-row justify-center items-center bg-neutral-700 opacity-50 aspect-[3/4] w-full rounded-xl mb-1"
        }
      >
        {book.cover ? (
          <Image
            source={{ uri: book.cover }}
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
  );
}
