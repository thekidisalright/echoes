import { Link } from "expo-router";
import { Text, View } from "react-native";
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context";

export default function Index() {
  return (
    <SafeAreaProvider>
      <SafeAreaView className="flex-1 bg-neutral-900">
        <View className="flex-1 bg-neutral-900 p-4">
          <Link href={{ pathname: "/player-screen" }}>
            <Text
              style={{ fontFamily: "Roboto_700Bold" }}
              className="text-white text-4xl"
            >
              Echoes
            </Text>
          </Link>
        </View>
      </SafeAreaView>
    </SafeAreaProvider>
  );
}
