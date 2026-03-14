import { Ionicons } from "@expo/vector-icons";
import { Slider } from "@miblanchard/react-native-slider";
import { Link } from "expo-router";
import { Image, StatusBar, Text, TouchableOpacity, View } from "react-native";
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context";

export default function PlayerScreen() {
  return (
    <SafeAreaProvider>
      <StatusBar barStyle={"light-content"} />
      <SafeAreaView className="bg-neutral-800  flex-1 p-6 justify-between">
        <View className="flex-row justify-between items-center">
          <Link href={"/"} asChild>
            <TouchableOpacity>
              <Ionicons name="chevron-down" size={24} color={"#d4d4d4"} />
            </TouchableOpacity>
          </Link>
          <Text className="text-white">Clarice Lispector</Text>
          <TouchableOpacity>
            <Ionicons name="ellipsis-horizontal" size={24} color={"#d4d4d4"} />
          </TouchableOpacity>
        </View>
        <View
          className="mt-4 w-10/12 max-w-[400px] self-center rounded-xl overflow-hidden"
          style={{
            boxShadow: "0 16px 48px rgba(0,0,0,0.7)",
            aspectRatio: "3 / 4",
          }}
        >
          <Image
            className="w-full h-full"
            source={require("../assets/images/thehourofthestar.jpg")}
            resizeMode="cover"
            style={{ objectFit: "cover" }}
          />
        </View>
        <View>
          <View className="px-4 mt-5 mb-6">
            <Text className="text-white text-2xl font-cormorantbold mb-2">
              The Hour of the Star
            </Text>
            <Text className="text-white text-lg">Chapter 1</Text>
            <Text className="text-neutral-300 text-sm font-light">
              Chapter 1 of 12
            </Text>
          </View>
          <View className="w-full px-4">
            <Slider
              minimumValue={0}
              maximumValue={100}
              value={30}
              minimumTrackTintColor="#D4A017"
              maximumTrackTintColor="#d4d4d4"
              thumbTintColor="#D4A017"
              trackStyle={{ height: 5, borderRadius: 3 }}
              thumbStyle={{ width: 16, height: 16, borderRadius: 8 }}
            />
            <View className="flex-row justify-between">
              <Text className="text-xs text-neutral-400 font-light">01:30</Text>
              <Text className="text-xs text-neutral-400 font-light">
                -04:15
              </Text>
            </View>
          </View>
          <View className="flex-row items-center justify-center gap-8 px-4">
            <Ionicons name="play-skip-back" size={22} color={"#fafafa"} />
            <Ionicons name="play-back" size={32} color={"#fafafa"} />
            <Ionicons name="play-circle" size={72} color={"#fafafa"} />
            <Ionicons name="play-forward" size={32} color={"#fafafa"} />
            <Ionicons name="play-skip-forward" size={22} color={"#fafafa"} />
          </View>
          <View className="mt-10 mb-4 px-4 flex-row justify-between">
            <Ionicons name="volume-high-outline" size={24} color={"#fafafa"} />
            <Ionicons name="time-outline" size={24} color={"#fafafa"} />
            <Ionicons name="repeat-outline" size={24} color={"#fafafa"} />
            <Ionicons name="moon-outline" size={24} color={"#fafafa"} />
            <Ionicons name="bookmark" size={24} color={"#D4A017"} />
            <Ionicons name="list-outline" size={24} color={"#fafafa"} />
          </View>
        </View>
      </SafeAreaView>
    </SafeAreaProvider>
  );
}
