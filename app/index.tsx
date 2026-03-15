import ScanBooks from "@/components/ScanBooks";
import { Link } from "expo-router";
import { useState } from "react";
import { Text, View } from "react-native";
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context";

export default function Index() {
  const [books, setBooks] = useState([]);
  return (
    <SafeAreaProvider>
      <SafeAreaView className="flex-1 bg-neutral-900">
        <View className="bg-neutral-900 p-4 flex-row justify-between items-center">
          <Link href={{ pathname: "/player-screen" }}>
            <Text className="text-white text-4xl">Echoes</Text>
          </Link>
          <ScanBooks setBooks={setBooks} books={books} />
        </View>
      </SafeAreaView>
    </SafeAreaProvider>
  );
}
