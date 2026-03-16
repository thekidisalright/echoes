import BookItem from "@/components/BookItem";
import ContinueListeningItem from "@/components/ContinueListeningItem";
import MiniPlayer from "@/components/MiniPlayer";
import ScanBooks from "@/components/ScanBooks";
import { Link } from "expo-router";
import { useState } from "react";
import { ScrollView, Text, View } from "react-native";
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context";

export default function Index() {
  const [books, setBooks] = useState([]);
  return (
    <SafeAreaProvider>
      <SafeAreaView className="flex-1 bg-neutral-800">
        <View className="px-4 mt-4 mb-5 flex-row justify-between items-center">
          <Link href={{ pathname: "/player-screen" }}>
            <Text className="text-white text-5xl font-cormorantbold">
              Echoes
            </Text>
          </Link>
          <ScanBooks setBooks={setBooks} books={books} />
        </View>
        <ScrollView
          className="flex-1"
          contentContainerClassName="pb-32"
          showsVerticalScrollIndicator={false}
        >
          <View className="px-4 mb-8">
            <Text className="text-white text-xl font-medium mb-1">
              Continue Listening
            </Text>
            <ContinueListeningItem status="idle" />
            <ContinueListeningItem status="" />
          </View>
          <View className="px-4 ">
            <Text className="text-white text-xl font-medium mb-3">
              All Audiobooks
            </Text>
            <View className="flex-row flex-wrap justify-between">
              <BookItem
                image={require("@/assets/images/thehourofthestar.jpg")}
              />
              <BookItem image={require("@/assets/images/amongflowers.jpg")} />
              <BookItem image={require("@/assets/images/reputations.jpg")} />
              <BookItem
                image={require("@/assets/images/worstpersonever.jpg")}
              />
            </View>
          </View>
        </ScrollView>
        <MiniPlayer />
      </SafeAreaView>
    </SafeAreaProvider>
  );
}
