import { useLibraryContext } from "@/contexts/LibraryContext";
import type { Book } from "@/src/models";
import { Ionicons } from "@expo/vector-icons";
import { File } from "expo-file-system";
import { useEffect, useState } from "react";
import { ActivityIndicator, Alert, Image, KeyboardAvoidingView, Modal, Platform, ScrollView, Text, TextInput, TouchableOpacity, View } from "react-native";

export default function BookEditDialog({ book, onClose }: { book: Book | null; onClose: () => void }) {
  const { updateBookDetails } = useLibraryContext();
  const [title, setTitle] = useState(""); const [author, setAuthor] = useState(""); const [coverImageUri, setCoverImageUri] = useState<string | undefined>(); const [saving, setSaving] = useState(false);
  useEffect(() => { if (book) { setTitle(book.title); setAuthor(book.author); setCoverImageUri(book.coverImageUri); } }, [book]);
  const chooseCover = async () => {
    try { const result = await File.pickFileAsync({ mimeTypes: ["image/*"] }); if (!result.canceled) setCoverImageUri(result.result.uri); }
    catch { Alert.alert("Não foi possível abrir as imagens", "Tente escolher a capa novamente."); }
  };
  const save = async () => {
    if (!book || !title.trim()) return;
    setSaving(true);
    try { await updateBookDetails(book.id, { title, author, coverImageUri }); onClose(); }
    catch { Alert.alert("Não foi possível salvar", "Tente novamente."); }
    finally { setSaving(false); }
  };
  return <Modal visible={!!book} transparent animationType="fade" onRequestClose={onClose}>
    <KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : undefined} className="flex-1 justify-center bg-black/75 px-5">
      <View className="max-h-[90%] w-full self-center rounded-2xl border border-[#45423a] bg-[#201f1b] p-5">
        <ScrollView keyboardShouldPersistTaps="handled">
          <Text className="text-[#d5d4cf] text-2xl font-cormorantbold mb-4">Editar audiobook</Text>
          <TouchableOpacity onPress={() => void chooseCover()} accessibilityRole="button" accessibilityLabel="Escolher capa" className="self-center w-28 h-36 rounded-lg overflow-hidden bg-[#2b2924] items-center justify-center mb-5">
            {coverImageUri ? <Image source={{ uri: coverImageUri }} resizeMode="cover" className="w-full h-full" /> : <Ionicons name="image-outline" size={36} color="#d1aa65" />}
            <View className="absolute bottom-0 left-0 right-0 bg-black/70 py-1.5 items-center"><Text className="text-[#d5d4cf] text-xs">Alterar capa</Text></View>
          </TouchableOpacity>
          <Text className="text-[#aaa9a3] text-sm mb-1.5">Título</Text><TextInput value={title} onChangeText={setTitle} placeholder="Título" placeholderTextColor="#73736e" className="border border-[#3a3935] rounded-xl px-4 py-3 text-[#d5d4cf] mb-4" />
          <Text className="text-[#aaa9a3] text-sm mb-1.5">Autor</Text><TextInput value={author} onChangeText={setAuthor} placeholder="Autor" placeholderTextColor="#73736e" className="border border-[#3a3935] rounded-xl px-4 py-3 text-[#d5d4cf] mb-5" />
        </ScrollView>
        <View className="flex-row justify-end gap-3 pt-4"><TouchableOpacity disabled={saving} onPress={onClose} className="px-4 py-3"><Text className="text-[#aaa9a3]">Cancelar</Text></TouchableOpacity><TouchableOpacity disabled={!title.trim() || saving} onPress={() => void save()} className="flex-row items-center gap-2 rounded-lg bg-[#80683f] px-4 py-3">{saving && <ActivityIndicator size="small" color="#f0eee7" />}<Text className="text-[#f0eee7] font-medium">Salvar</Text></TouchableOpacity></View>
      </View>
    </KeyboardAvoidingView>
  </Modal>;
}
