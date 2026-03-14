import {
  CormorantGaramond_400Regular,
  CormorantGaramond_500Medium,
  CormorantGaramond_700Bold,
  useFonts,
} from "@expo-google-fonts/cormorant-garamond";
import { Stack } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import { useEffect } from "react";
import "../global.css";

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [loaded, error] = useFonts({
    CormorantGaramond_400Regular,
    CormorantGaramond_500Medium,
    CormorantGaramond_700Bold,
  });

  useEffect(() => {
    if (loaded || error) {
      SplashScreen.hideAsync();
    }
  }, [loaded, error]);

  if (!loaded && !error) {
    return null;
  }
  return (
    <Stack>
      <Stack.Screen
        name="index"
        options={{ headerShown: false, title: "Home" }}
      />
      <Stack.Screen
        name="player-screen"
        options={{
          animation: "slide_from_bottom",
          headerShown: false,
          title: "Player",
        }}
      />
      <Stack.Screen
        name="chapters"
        options={{
          presentation: "formSheet",
          sheetAllowedDetents: [0.5, 0.8],
          sheetGrabberVisible: true,
          title: "Chapters",
          headerShown: true,
        }}
      />
    </Stack>
  );
}
