import { Ionicons } from "@expo/vector-icons";
import { Image, Text, View } from "react-native";

export default function MiniPlayer() {
  return (
    <View className="absolute bottom-6 left-4 right-4 bg-neutral-950/80 rounded-2xl border border-neutral-400/50 flex-row items-center px-4 py-3 gap-2 justify-between shadow-lg">
      <Image
        source={require("@/assets/images/thehourofthestar.jpg")}
        className="w-14 h-14 object-cover rounded"
        resizeMode="cover"
      />
      <View className="flex-col flex-1 h-14 justify-center">
        <Text className="text-white text-sm font-semibold" numberOfLines={1}>
          The Hour of the Star
        </Text>
        <Text className="text-neutral-400 text-sm mb" numberOfLines={1}>
          Chapter 1
        </Text>
      </View>
      <View className="w-14 flex-col items-center">
        <Ionicons name="play-circle" color={"#fafafa"} size={48} />
      </View>
    </View>
  );
}
