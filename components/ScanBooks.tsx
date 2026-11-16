import { useLibraryContext } from "@/contexts/LibraryContext";
import { Ionicons } from "@expo/vector-icons";
import { ActivityIndicator, Text, TouchableOpacity } from "react-native";

export default function ScanBooks(){const {importFolder,importing}=useLibraryContext();return <TouchableOpacity onPress={()=>void importFolder()} className="flex-row items-center gap-2 px-4 py-3 rounded-xl border border-[#746345]">{importing?<ActivityIndicator color="#d1aa65"/>:<Ionicons name="folder-open-outline" size={20} color="#d1aa65"/>}<Text className="text-[#eadfca]">Importar</Text></TouchableOpacity>;}
