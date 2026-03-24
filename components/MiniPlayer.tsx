import { usePlayerContext } from "@/contexts/PlayerContext";
import { Ionicons } from "@expo/vector-icons";
import { Link } from "expo-router";
import { Image, Text, TouchableOpacity, View } from "react-native";

export default function MiniPlayer() {
  const { currentBook, currentChapterIndex, player, status } =
    usePlayerContext();
  const togglePlayPause = () => {
    if (status.playing) {
      player.pause();
    } else {
      player.play();
    }
  };
  return (
    <Link href={{ pathname: "/player-screen" }} asChild>
      <View
        className="absolute bottom-6 left-4 right-4 bg-neutral-950/80 rounded-2xl border border-neutral-700/50 flex-row items-center px-4 py-3 gap-2 justify-between"
        style={{
          boxShadow: "0 0px 30px rgba(0,0,0,0.6)",
        }}
      >
        {currentBook?.coverImageUri ? (
          <Image
            source={{ uri: currentBook.coverImageUri }}
            className="w-14 h-14 object-cover rounded-md border border-neutral-700"
            resizeMode="cover"
          />
        ) : (
          <View className="w-14 h-14 flex justify-center items-center bg-neutral-700 rounded-md border border-neutral-600">
            <Ionicons name="image-outline" color={"#737373"} size={24} />
          </View>
        )}

        <View className="flex-col flex-1 h-14 justify-center">
          <Text className="text-white text-sm font-semibold" numberOfLines={1}>
            {currentBook?.title}
          </Text>
          <Text className="text-neutral-400 text-sm mb" numberOfLines={1}>
            {currentBook && currentChapterIndex != null
              ? currentBook.chapters[currentChapterIndex].name
              : "Unknow chapter"}
          </Text>
        </View>
        <TouchableOpacity
          className="w-14 flex-col items-center"
          onPress={togglePlayPause}
        >
          {status.playing ? (
            <Ionicons name="pause-circle" color={"#fafafa"} size={48} />
          ) : (
            <Ionicons name="play-circle" color={"#fafafa"} size={48} />
          )}
        </TouchableOpacity>
      </View>
    </Link>
  );
}
