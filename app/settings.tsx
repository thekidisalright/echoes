import { useLibraryContext } from "@/contexts/LibraryContext";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { ScrollView, Text, TouchableOpacity, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

export default function SettingsScreen() {
  const { sortOrder, setSortOrder } = useLibraryContext(); const router = useRouter();
  return <SafeAreaView className="flex-1 bg-[#171614]"><ScrollView contentContainerStyle={{ padding: 20, paddingTop: 18 }}>
    <View className="flex-row items-center mb-7"><TouchableOpacity onPress={() => router.back()} accessibilityRole="button" accessibilityLabel="Voltar" className="mr-4 p-2"><Ionicons name="arrow-back" size={23} color="#aaa9a3" /></TouchableOpacity><Text className="text-[#d5d4cf] text-3xl font-cormorantbold">Configurações</Text></View>
    <Text className="text-[#c9c8c2] text-xl font-cormorantbold mb-1">Ordem da biblioteca</Text>
    <Text className="text-[#92928d] text-sm mb-4">Escolha como os audiobooks aparecem ao abrir o app.</Text>
    {(["recent", "title"] as const).map(value => <TouchableOpacity key={value} onPress={() => void setSortOrder(value)} accessibilityRole="radio" accessibilityState={{ checked: sortOrder === value }} className="flex-row items-center justify-between border-b border-[#373633] py-4">
      <Text className="text-[#d5d4cf]">{value === "recent" ? "Mais recentes" : "Título"}</Text><Ionicons name={sortOrder === value ? "radio-button-on" : "radio-button-off"} size={21} color={sortOrder === value ? "#d1aa65" : "#85857f"} />
    </TouchableOpacity>)}
  </ScrollView></SafeAreaView>;
}
