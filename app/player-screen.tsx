import { Ionicons } from "@expo/vector-icons";
import Slider from "@react-native-community/slider";
import { Link } from "expo-router";
import { Image, StatusBar, Text, TouchableOpacity, View } from "react-native";
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context";

export default function PlayerScreen() {
  return (
    <SafeAreaProvider>
      <StatusBar barStyle={"light-content"} />
      <SafeAreaView className="bg-neutral-900  flex-1 p-6 justify-between">
        <View className="flex-row justify-between items-center">
          <Link href={"/"}>
            <Ionicons name="chevron-down" size={24} color={"#d4d4d4"} />
          </Link>
          <Link href={{ pathname: "/chapters" }}>
            <Text className="text-white text-lg font-medium ">Chapter 1</Text>
          </Link>
          <TouchableOpacity>
            <Ionicons name="ellipsis-horizontal" size={24} color={"#d4d4d4"} />
          </TouchableOpacity>
        </View>
        <View className="">
          <View className="w-11/12 max-w-[400px] aspect-square self-center rounded-2xl overflow-hidden">
            <Image
              className="w-full h-full"
              source={require("../assets/images/thehourofthestar.jpg")}
              resizeMode="cover"
            />
          </View>
          <View className="px-4 mt-8 mb-16">
            <Text className="text-white text-2xl font-medium">
              The Hour of the Star
            </Text>
            <Text className="text-neutral-400">Clarice Lispector</Text>
          </View>
          <View className="w-full">
            <Slider
              style={{ width: "100%", height: 40 }}
              minimumValue={0}
              maximumValue={100}
              value={30}
              minimumTrackTintColor="#fafafa"
              maximumTrackTintColor="#d4d4d4"
              thumbTintColor="#fafafa"
            />
            <View className="flex-row justify-between px-4">
              <Text className="text-sm text-neutral-400">01:30</Text>
              <Text className="text-sm text-neutral-400">-04:15</Text>
            </View>
          </View>
          <View className="flex-row items-center justify-evenly">
            <Ionicons name="play-skip-back" size={24} color={"#fafafa"} />
            <Ionicons name="play-back" size={36} color={"#fafafa"} />
            <Ionicons name="play-circle" size={96} color={"#fafafa"} />
            <Ionicons name="play-forward" size={36} color={"#fafafa"} />
            <Ionicons name="play-skip-forward" size={24} color={"#fafafa"} />
          </View>
          <View className="mt-16 px-4 flex-row justify-between">
            <Ionicons name="volume-high" size={24} color={"#fafafa"} />
            <Ionicons name="time" size={24} color={"#fafafa"} />
            <Ionicons name="repeat" size={24} color={"#fafafa"} />
            <Ionicons name="moon" size={24} color={"#fafafa"} />
            <Ionicons name="bookmark" size={24} color={"#fafafa"} />
            <Ionicons name="list" size={24} color={"#fafafa"} />
          </View>
        </View>
      </SafeAreaView>
    </SafeAreaProvider>
  );
}
