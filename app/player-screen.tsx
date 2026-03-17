import AudioControls from "@/components/AudioControls";
import SliderComponent from "@/components/Slider";
import { usePlayerContext } from "@/contexts/PlayerContext";
import { Ionicons } from "@expo/vector-icons";
import { Link } from "expo-router";
import { Image, StatusBar, Text, TouchableOpacity, View } from "react-native";
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context";

export default function PlayerScreen() {
  const { currentBook, currentChapterIndex } = usePlayerContext();
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
          <Text className="text-white">{currentBook?.author}</Text>
          <TouchableOpacity>
            <Ionicons name="ellipsis-horizontal" size={24} color={"#d4d4d4"} />
          </TouchableOpacity>
        </View>
        <View
          className="mt-4 w-10/12 max-w-[400px] bg-neutral-700 self-center rounded-xl overflow-hidden justify-center items-center"
          style={{
            boxShadow: "0 16px 48px rgba(0,0,0,0.7)",
            aspectRatio: "3 / 4",
          }}
        >
          {currentBook?.cover ? (
            <Image
              className="w-full h-full"
              source={{ uri: currentBook.cover }}
              resizeMode="cover"
              style={{ objectFit: "cover" }}
            />
          ) : (
            <Ionicons name="image-outline" color={"#737373"} size={72} />
          )}
        </View>
        <View>
          <View className="px-4 mt-5 mb-6">
            <Text
              className="text-white text-2xl font-cormorantbold mb-2"
              numberOfLines={1}
            >
              {currentBook?.title}
            </Text>
            <Text className="text-white text-lg">
              Chapter {currentChapterIndex ? currentChapterIndex + 1 : "?"}
            </Text>
            <Text
              className="text-neutral-300 text-sm font-light"
              numberOfLines={1}
            >
              Chapter {currentChapterIndex ? currentChapterIndex + 1 : "?"} of{" "}
              {currentBook?.chapters.length}
            </Text>
          </View>
          <SliderComponent />
          <AudioControls />
          <View className="mt-10 mb-2 px-2 flex-row">
            <TouchableOpacity className="flex-1 items-center justify-center py-2">
              <Ionicons
                name="volume-high-outline"
                size={24}
                color={"#fafafa"}
              />
            </TouchableOpacity>

            <TouchableOpacity className="flex-1 items-center justify-center py-2">
              <Ionicons name="time-outline" size={24} color={"#fafafa"} />
            </TouchableOpacity>

            <TouchableOpacity className="flex-1 items-center justify-center py-2">
              <Ionicons name="repeat-outline" size={24} color={"#fafafa"} />
            </TouchableOpacity>

            <TouchableOpacity className="flex-1 items-center justify-center py-2">
              <Ionicons name="moon-outline" size={24} color={"#fafafa"} />
            </TouchableOpacity>

            <TouchableOpacity className="flex-1 items-center justify-center py-2">
              <Ionicons name="bookmark" size={24} color={"#D4A017"} />
            </TouchableOpacity>

            <Link href={{ pathname: "/chapters" }} asChild>
              <TouchableOpacity className="flex-1 items-center justify-center py-2">
                <Ionicons name="list-outline" size={24} color={"#fafafa"} />
              </TouchableOpacity>
            </Link>
          </View>
        </View>
      </SafeAreaView>
    </SafeAreaProvider>
  );
}
