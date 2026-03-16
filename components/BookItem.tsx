import { Image, Text, View } from "react-native";

export default function BookItem({ image }: { image: any }) {
  return (
    <View className="w-[48%] mb-4">
      <View className="overflow-hidden aspect-[3/4] w-full rounded-xl mb-1">
        <Image source={image} className="w-full h-full" resizeMode="cover" />
      </View>
      <Text className="text-white text-sm font-medium">
        The Hour of the Star
      </Text>
      <Text className="text-neutral-400 text-xs">Clarice Lispector</Text>
      <Text className="text-neutral-400 text-xs mt-0.5">2h 20m</Text>
    </View>
  );
}
