import { useLibraryContext } from "@/contexts/LibraryContext";
import { Ionicons } from "@expo/vector-icons";
import { Directory, File } from "expo-file-system";
import { TouchableOpacity } from "react-native";

export default function ScanBooks() {
  const { saveBooksToLibrary } = useLibraryContext();
  const handlePickFolder = async () => {
    try {
      const pickedDirectory = await Directory.pickDirectoryAsync();
      if (!pickedDirectory) return;
      const booksFound: any[] = [];
      const scanDirectory = (currentDir: any) => {
        const contents = currentDir.list();
        const audioFiles: any[] = [];
        let coverImageUri: string | null = null;

        contents.forEach((item: any) => {
          if (item instanceof Directory) {
            scanDirectory(item);
          } else if (item instanceof File) {
            if (item.name.endsWith(".mp3")) {
              audioFiles.push({
                name: item.name.split(".mp3", 1).join(""),
                uri: item.uri,
              });
            } else if (item.name.endsWith(".m4a")) {
              audioFiles.push({
                name: item.name.split(".m4a", 1).join(""),
                uri: item.uri,
              });
            } else if (
              item.name.endsWith(".jpg") ||
              item.name.endsWith(".jpeg") ||
              item.name.endsWith(".png")
            ) {
              if (!coverImageUri) {
                coverImageUri = item.uri;
              }
            }
          }
        });
        if (audioFiles.length > 0) {
          booksFound.push({
            title: currentDir.name,
            chapters: audioFiles,
            author: "Unknown Author",
            cover: coverImageUri,
          });
        }
      };
      scanDirectory(pickedDirectory);
      saveBooksToLibrary(booksFound);
    } catch (error) {
      console.error("Error while trying to scan for books:", error);
    }
  };
  return (
    <TouchableOpacity onPress={handlePickFolder}>
      <Ionicons name="settings" size={24} color={"#a3a3a3"} />
    </TouchableOpacity>
  );
}
