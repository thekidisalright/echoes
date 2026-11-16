import { useLibraryContext } from "@/contexts/LibraryContext";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { ActivityIndicator, Alert, ScrollView, Text, TouchableOpacity, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

export default function LibraryManagementScreen() {
  const { sources, books, importing, importStatus, importFolder, importFiles, rescanSource, removeSource } = useLibraryContext(); const router = useRouter();
  const confirmRemove = (sourceId: string, name: string) => Alert.alert("Remover origem?", `Remover “${name}” e seus livros da biblioteca? Os arquivos originais não serão apagados.`, [
    { text: "Cancelar", style: "cancel" }, { text: "Remover", style: "destructive", onPress: () => { const source = sources.find(item => item.id === sourceId); if (source) void removeSource(source); } },
  ]);
  const importAction = (icon: keyof typeof Ionicons.glyphMap, label: string, onPress: () => void) => <TouchableOpacity disabled={importing} onPress={onPress} accessibilityRole="button" className="flex-1 flex-row items-center justify-center gap-2 rounded-xl border border-[#514731] bg-[#24221e] py-4"><Ionicons name={icon} size={20} color="#d1aa65" /><Text className="text-[#d5d4cf] text-sm">{label}</Text></TouchableOpacity>;
  return <SafeAreaView className="flex-1 bg-[#171614]"><ScrollView contentContainerStyle={{ paddingHorizontal: 20, paddingTop: 18, paddingBottom: 40 }}>
    <View className="flex-row items-center mb-6"><TouchableOpacity onPress={() => router.back()} accessibilityRole="button" accessibilityLabel="Voltar" className="mr-4 p-2"><Ionicons name="arrow-back" size={23} color="#aaa9a3" /></TouchableOpacity><Text className="text-[#d5d4cf] text-3xl font-cormorantbold">Gerenciar biblioteca</Text></View>
    <View className="flex-row gap-3 mb-4">{importAction("folder-open-outline", "Adicionar pasta", () => void importFolder())}{importAction("musical-notes-outline", "Adicionar arquivos", () => void importFiles())}</View>
    {importing && <View className="flex-row items-center gap-3 rounded-lg bg-[#24221e] border border-[#393833] px-4 py-3 mb-6"><ActivityIndicator size="small" color="#d1aa65" /><Text className="text-[#b7b6af] text-sm flex-1">{importStatus || "Importando biblioteca…"}</Text></View>}
    <Text className="text-[#c9c8c2] text-2xl font-cormorantbold mt-5 mb-2">Pastas e arquivos adicionados</Text>
    {sources.length === 0 ? <Text className="text-[#92928d] py-5">Nenhuma origem adicionada. Escolha uma pasta ou arquivos acima.</Text> : sources.map(source => {
      const count = books.filter(book => book.sourceId === source.id).length; const isFileSelection = source.id.startsWith("files:");
      return <View key={source.id} className="border-b border-[#373633] py-5 flex-row items-center">
        <View className="w-11 h-11 items-center justify-center rounded-lg bg-[#252420] mr-3"><Ionicons name={isFileSelection ? "musical-notes-outline" : "folder-outline"} size={22} color="#d1aa65" /></View>
        <View className="flex-1 mr-2"><Text className="text-[#d5d4cf] text-base font-medium" numberOfLines={1}>{source.name}</Text><Text className="text-[#92928d] text-xs mt-1">{count} {count === 1 ? "livro" : "livros"} · {source.available ? "disponível" : "acesso indisponível"}</Text></View>
        {!isFileSelection && <TouchableOpacity accessibilityRole="button" accessibilityLabel={`Atualizar ${source.name}`} disabled={importing} onPress={() => void rescanSource(source)} className="p-3"><Ionicons name="refresh-outline" size={21} color={importing ? "#696861" : "#aaa9a3"} /></TouchableOpacity>}
        <TouchableOpacity accessibilityRole="button" accessibilityLabel={`Remover ${source.name}`} disabled={importing} onPress={() => confirmRemove(source.id, source.name)} className="p-3"><Ionicons name="trash-outline" size={20} color={importing ? "#696861" : "#aaa9a3"} /></TouchableOpacity>
      </View>;
    })}
  </ScrollView></SafeAreaView>;
}
