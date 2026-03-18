import { Ionicons, MaterialIcons } from "@expo/vector-icons";
import { Image, Text, View } from "react-native";
import ProgressBar from "./ProgressBar";

export default function ContinueListeningItem({ status }: { status: string }) {
  return (
    <View className="flex-row items-center h-[80px] gap-3 border-b border-b-neutral-700">
      <Image
        source={require("@/assets/images/thehourofthestar.jpg")}
        className="w-16 h-16 object-cover rounded-md"
        resizeMode="cover"
      />
      <View className="flex-col flex-1 h-14 justify-between">
        <Text className="text-white text-sm font-semibold" numberOfLines={1}>
          The Hour of the Star
        </Text>
        <Text className="text-neutral-400 text-sm mb-1" numberOfLines={1}>
          Clarice Lispector
        </Text>
        <ProgressBar duration={3000} currentTime={1550} />
      </View>
      <View className="w-14 flex-col items-center">
        {status ? (
          <MaterialIcons
            name="equalizer"
            color={status === "idle" ? "#a3a3a3" : "#D4A017"}
            size={18}
          />
        ) : (
          <Ionicons name="time" color={"#a3a3a3"} size={18} />
        )}
      </View>
    </View>
  );
}
