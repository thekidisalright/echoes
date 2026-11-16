import { useLibraryContext } from "@/contexts/LibraryContext";
import { usePlayerContext } from "@/contexts/PlayerContext";
import type { Book } from "@/src/models";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { Image, Text, TouchableOpacity, View } from "react-native";

export default function BookItem({ book, onLongPress }: { book: Book; onLongPress: (book: Book) => void }) {
  const { openBook } = usePlayerContext(); const { importFolder } = useLibraryContext(); const router = useRouter();
  const handlePress = async () => { if (!book.sourceAvailable) { await importFolder(); return; } await openBook(book, false); router.push("/player-screen"); };
  const formatTime = (seconds: number) => { const hours = Math.floor(seconds / 3600); const minutes = Math.floor((seconds % 3600) / 60); return hours ? `${hours}h ${minutes.toString().padStart(2, "0")}m` : `${minutes}m`; };
  return <TouchableOpacity className="w-full mb-5" onPress={() => void handlePress()} onLongPress={() => onLongPress(book)} onAccessibilityAction={event => { if (event.nativeEvent.actionName === "longpress") onLongPress(book); }} accessibilityActions={[{ name: "longpress", label: "Editar audiobook" }]} delayLongPress={450} activeOpacity={0.75} accessibilityRole="button" accessibilityLabel={`Ouvir ${book.title}`} accessibilityHint="Pressione e segure para editar">
    <View className="w-full">
      <View className="overflow-hidden aspect-[3/4] w-full rounded-xl mb-2 bg-[#262521] items-center justify-center">
        {book.coverImageUri ? <Image source={{ uri: book.coverImageUri }} className="w-full h-full" resizeMode="cover" /> : <Ionicons name="book-outline" color="#777771" size={48} />}
      </View>
      <Text className="text-[#d5d4cf] text-sm font-medium" numberOfLines={1}>{book.title || "Sem título"}</Text>
      <Text className="text-[#969690] text-xs" numberOfLines={1}>{book.author || "Autor desconhecido"}</Text>
      <Text className="text-[#85857f] text-xs mt-0.5" numberOfLines={1}>{!book.sourceAvailable ? "Pasta indisponível" : `${book.chapters.length} capítulos${book.totalDuration ? ` · ${formatTime(book.totalDuration)}` : ""}`}</Text>
    </View>
  </TouchableOpacity>;
}
