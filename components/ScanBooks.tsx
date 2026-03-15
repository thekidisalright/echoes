import { Ionicons } from "@expo/vector-icons";
import { Directory, File } from "expo-file-system";
import { TouchableOpacity } from "react-native";

export default function ScanBooks({ setBooks }: any) {
  const handlePickFolder = async () => {
    try {
      const pickedDirectory = await Directory.pickDirectoryAsync();
      if (!pickedDirectory) return;
      const booksFound: any[] = [];
      const scanDirectory = (currentDir: any) => {
        const contents = currentDir.list();
        const audioFiles: any[] = [];

        contents.forEach((item: any) => {
          if (item instanceof Directory) {
            scanDirectory(item);
          } else if (item instanceof File) {
            if (item.name.endsWith(".mp3") || item.name.endsWith(".m4a")) {
              audioFiles.push({ name: item.name, uri: item.uri });
            }
          }
        });
        if (audioFiles.length > 0) {
          booksFound.push({
            title: currentDir.name,
            chapters: audioFiles,
          });
        }
      };
      scanDirectory(pickedDirectory);
      setBooks(booksFound);
    } catch (error) {
      console.error("Error while trying to scan for books:", error);
    }
  };
  return (
    <TouchableOpacity onPress={handlePickFolder}>
      <Ionicons name="file-tray-stacked-outline" size={24} color={"#fafafa"} />
    </TouchableOpacity>
  );
}
