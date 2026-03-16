import { MaterialIcons } from "@expo/vector-icons";
import { Image, Text, View } from "react-native";
import ProgressBar from "./ProgressBar";

export default function ContinueListeningItem({ status }: { status: string }) {
  return (
    <View className="flex-row items-center h-[72px] gap-3">
      <Image
        source={require("@/assets/images/thehourofthestar.jpg")}
        className="w-14 h-14 object-cover rounded"
        resizeMode="cover"
      />
      <View className="flex-col flex-1 h-14 justify-center">
        <Text className="text-white font-semibold" numberOfLines={1}>
          The Hour of the Star
        </Text>
        <Text className="text-white text-sm mb-1" numberOfLines={1}>
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
          <></>
        )}
      </View>
    </View>
  );
}
