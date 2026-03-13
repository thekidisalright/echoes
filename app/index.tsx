import { Text, View } from "react-native";
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context";

export default function Index() {
  return (
    <SafeAreaProvider>
      <SafeAreaView className="flex-1">
        <View className="flex-1 bg-white p-4">
          <Text
            style={{ fontFamily: "Roboto_700Bold" }}
            className="text-blue-500 text-4xl"
          >
            Echoes
          </Text>
        </View>
      </SafeAreaView>
    </SafeAreaProvider>
  );
}
