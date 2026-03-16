import { Image, Text, View } from "react-native";

export default function BookItem() {
  return (
    <View className="w-[48%] mb-4 gap-0.5">
      <View className="overflow-hidden aspect-[3/4] w-full rounded-lg">
        <Image
          source={require("@/assets/images/thehourofthestar.jpg")}
          className="w-full h-full"
          resizeMode="cover"
        />
      </View>
      <Text className="text-white text-sm font-medium">
        The Hour of the Star
      </Text>
      <Text className="text-neutral-400 text-xs">Clarice Lispector</Text>
      <Text className="text-neutral-400 text-xs mt-1">2h20m</Text>
    </View>
  );
}
