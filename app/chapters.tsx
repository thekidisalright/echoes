import { usePlayerContext } from "@/contexts/PlayerContext";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { ScrollView, Text, TouchableOpacity, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

const time = (seconds: number) => `${Math.floor(seconds / 60)}:${Math.floor(seconds % 60).toString().padStart(2, "0")}`;
export default function Chapters() {
  const { currentBook, currentChapterIndex, playChapter, player, bookmarks, removeCurrentBookmark } = usePlayerContext(); const router = useRouter();
  if (!currentBook) return <SafeAreaView className="flex-1 bg-[#171614]" />;
  return <SafeAreaView className="flex-1 bg-[#171614]"><ScrollView contentContainerStyle={{ padding: 20, paddingBottom: 40 }}>
    <View className="flex-row items-center mb-6"><TouchableOpacity onPress={() => router.back()} className="mr-4 p-2"><Ionicons name="arrow-back" size={23} color="#aaa9a3" /></TouchableOpacity><View><Text className="text-[#d5d4cf] text-3xl font-cormorantbold">{currentBook.title}</Text><Text className="text-[#aaa9a3] text-sm">Capítulos e marcadores</Text></View></View>
    <Text className="text-[#d1aa65] text-sm uppercase tracking-widest mb-2">Capítulos</Text>
    {currentBook.chapters.map((chapter, index) => <TouchableOpacity key={chapter.id} onPress={() => { void playChapter(index); router.back(); }} className="flex-row items-center py-4 border-b border-[#393833]"><Text className="text-[#85857f] w-10">{String(index + 1).padStart(2, "0")}</Text><Text className={`flex-1 ${index === currentChapterIndex ? "text-[#d1aa65]" : "text-[#d5d4cf]"}`} numberOfLines={1}>{chapter.name}</Text>{index === currentChapterIndex && <Ionicons name="volume-high" size={18} color="#d1aa65" />}</TouchableOpacity>)}
    <Text className="text-[#d1aa65] text-sm uppercase tracking-widest mt-8 mb-2">Marcadores salvos</Text>
    {bookmarks.length === 0 ? <Text className="text-[#85857f] py-3">Os marcadores aparecem aqui.</Text> : bookmarks.map(mark => {
      const index = currentBook.chapters.findIndex(chapter => chapter.id === mark.chapterId); const chapter = currentBook.chapters[index];
      return <View key={mark.id} className="flex-row items-center py-3 border-b border-[#393833]"><TouchableOpacity className="flex-1" onPress={() => { if (index >= 0) { void playChapter(index).then(() => setTimeout(() => player.seekTo(mark.position), 180)); router.back(); } }}><Text className="text-[#d5d4cf]">{chapter?.name || "Capítulo removido"}</Text><Text className="text-[#aaa9a3] text-xs mt-1">{time(mark.position)}</Text></TouchableOpacity><TouchableOpacity onPress={() => void removeCurrentBookmark(mark.id)} accessibilityLabel="Remover marcador" className="p-2"><Ionicons name="trash-outline" size={20} color="#aaa9a3" /></TouchableOpacity></View>;
    })}
  </ScrollView></SafeAreaView>;
}
