import BookItem from "@/components/BookItem";
import BookEditDialog from "@/components/BookEditDialog";
import ContinueListeningItem from "@/components/ContinueListeningItem";
import MiniPlayer from "@/components/MiniPlayer";
import { useLibraryContext } from "@/contexts/LibraryContext";
import { usePlayerContext } from "@/contexts/PlayerContext";
import type { Book } from "@/src/models";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { useMemo, useState } from "react";
import { ActivityIndicator, ScrollView, Text, TextInput, TouchableOpacity, useWindowDimensions, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

export default function Index() {
  const { books, loading, importing, importStatus, sortOrder, setSortOrder } = useLibraryContext(); const { currentBook, status } = usePlayerContext();
  const [query, setQuery] = useState(""); const [editingBook, setEditingBook] = useState<Book | null>(null); const { width } = useWindowDimensions(); const router = useRouter(); const columns = width > 900 ? 5 : width > 620 ? 4 : 2;
  const visible = useMemo(() => books.filter(book => `${book.title} ${book.author}`.toLowerCase().includes(query.trim().toLowerCase())).sort((a, b) => sortOrder === "title" ? a.title.localeCompare(b.title, undefined, { numeric: true, sensitivity: "base" }) : (b.lastPlayedAt || 0) - (a.lastPlayedAt || 0)), [books, query, sortOrder]);
  const recent = books.filter(book => book.lastPlayedAt).sort((a, b) => (b.lastPlayedAt || 0) - (a.lastPlayedAt || 0)).slice(0, 3);
  const action = (icon: keyof typeof Ionicons.glyphMap, label: string, onPress: () => void) => <TouchableOpacity key={label} onPress={onPress} accessibilityRole="button" accessibilityLabel={label} className="items-center justify-center rounded-xl border border-[#46443e] w-11 h-11"><Ionicons name={icon} size={20} color="#d1aa65" /></TouchableOpacity>;
  return <SafeAreaView className="flex-1 bg-[#171614]">
    <ScrollView contentContainerStyle={{ paddingHorizontal: width > 700 ? 36 : 20, paddingTop: 18, paddingBottom: currentBook ? 130 : 48 }}>
      <View className="flex-row justify-between items-center mb-7">
        <Text className="text-[#d5d4cf] text-5xl font-cormorantbold">Echoes</Text>
        <View className="flex-row gap-2">{action("library-outline", "Gerenciar biblioteca", () => router.push("./directories"))}{action("settings-outline", "Configurações", () => router.push("./settings"))}</View>
      </View>
      {importing && <View className="flex-row items-center gap-3 rounded-lg bg-[#24221e] border border-[#393833] px-4 py-3 mb-5"><ActivityIndicator size="small" color="#d1aa65" /><Text className="text-[#b7b6af] text-sm flex-1">{importStatus || "Importando biblioteca…"}</Text></View>}
      {recent.length > 0 && <View className="mb-8"><Text className="text-[#c9c8c2] text-2xl font-cormorantbold mb-2">Continue ouvindo</Text>{recent.map(book => <ContinueListeningItem key={book.id} book={book} status={currentBook?.id === book.id && status.playing ? "playing" : ""} />)}</View>}
      <View className="flex-row items-center rounded-xl bg-[#24221e] border border-[#393833] px-3 mb-5"><Ionicons name="search" size={19} color="#a9a9a2" /><TextInput value={query} onChangeText={setQuery} placeholder="Buscar título ou autor" placeholderTextColor="#8e8e87" className="flex-1 text-[#cecdc7] px-3 py-3" returnKeyType="search" /></View>
      <View className="flex-row items-center justify-between mb-3"><Text className="text-[#c9c8c2] text-2xl font-cormorantbold">Biblioteca</Text><View className="flex-row gap-2">{(["recent", "title"] as const).map(key => <TouchableOpacity key={key} onPress={() => void setSortOrder(key)} className={`px-3 py-2 rounded-full ${sortOrder === key ? "bg-[#80683f]" : "bg-[#24221e]"}`}><Text className="text-[#d2d1cb] text-xs">{key === "recent" ? "Recentes" : "Título"}</Text></TouchableOpacity>)}</View></View>
      {loading ? <ActivityIndicator color="#d1aa65" className="mt-10" /> : visible.length === 0 ? <View className="items-center py-16 px-6"><Ionicons name="headset-outline" size={42} color="#8e8e87" /><Text className="text-[#d5d4cf] text-2xl font-cormorantbold mt-3">{books.length ? "Nenhum resultado" : "Nenhum audiobook"}</Text><Text className="text-[#a9a9a2] text-center mt-2">{books.length ? "Tente outro título ou autor." : "Toque em Gerenciar biblioteca para adicionar uma pasta ou arquivos."}</Text></View> : <View className="flex-row flex-wrap" style={{ marginHorizontal: -7 }}>{visible.map(book => <View key={book.id} style={{ width: `${100 / columns}%`, paddingHorizontal: 7 }}><BookItem book={book} onLongPress={setEditingBook} /></View>)}</View>}
    </ScrollView>
    {currentBook && <MiniPlayer />}
    <BookEditDialog book={editingBook} onClose={() => setEditingBook(null)} />
  </SafeAreaView>;
}
