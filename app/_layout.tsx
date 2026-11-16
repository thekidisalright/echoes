import { LibraryProvider } from "@/contexts/LibraryContext";
import { PlayerProvider } from "@/contexts/PlayerContext";
import {
  CormorantGaramond_400Regular,
  CormorantGaramond_500Medium,
  CormorantGaramond_700Bold,
  useFonts,
} from "@expo-google-fonts/cormorant-garamond";
import { Stack } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import { useEffect } from "react";
import { StatusBar } from "expo-status-bar";
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
    <LibraryProvider>
      <PlayerProvider>
        <StatusBar style="light" />
        <Stack>
          <Stack.Screen
            name="index"
            options={{
              headerShown: false,
              title: "Biblioteca",
              animation: "none",
            }}
          />
          <Stack.Screen
            name="player-screen"
            options={{
              animation: "slide_from_bottom",
              headerShown: false,
              title: "Reproduzindo",
              presentation: "card",
            }}
          />
          <Stack.Screen
            name="chapters"
            options={{
              presentation: "card",
              title: "Capítulos",
              headerShown: false,
            }}
          />
          <Stack.Screen name="directories" options={{ headerShown: false, animation: "slide_from_right" }} />
          <Stack.Screen name="settings" options={{ headerShown: false, animation: "slide_from_right" }} />
        </Stack>
      </PlayerProvider>
    </LibraryProvider>
  );
}
