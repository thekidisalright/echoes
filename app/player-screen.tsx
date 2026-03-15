import AudioControls from "@/components/AudioControls";
import SliderComponent from "@/components/Slider";
import { Ionicons } from "@expo/vector-icons";
import {
  setAudioModeAsync,
  useAudioPlayer,
  useAudioPlayerStatus,
} from "expo-audio";
import { Link } from "expo-router";
import { useEffect } from "react";
import { Image, StatusBar, Text, TouchableOpacity, View } from "react-native";
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context";
const audioSource = require("../assets/test/dualipa_troye.mp3");

export default function PlayerScreen() {
  const player = useAudioPlayer(audioSource);
  const audioStatus = useAudioPlayerStatus(player);

  useEffect(() => {
    setAudioModeAsync({
      playsInSilentMode: true,
      shouldPlayInBackground: true,
      interruptionMode: "doNotMix",
    });
  }, []);

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
          <SliderComponent player={player} status={audioStatus} />
          <AudioControls player={player} status={audioStatus} />
          {/* Removemos o justify-between do pai */}
          <View className="mt-10 mb-2 px-2 flex-row">
            {/* flex-1: divide igualmente. items-center: centraliza o ícone. py-2: deixa o botão mais "alto" */}
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
