import BookItem from "@/components/BookItem";
import ContinueListeningItem from "@/components/ContinueListeningItem";
import MiniPlayer from "@/components/MiniPlayer";
import ScanBooks from "@/components/ScanBooks";
import { useLibraryContext } from "@/contexts/LibraryContext";
import { usePlayerContext } from "@/contexts/PlayerContext";
import { ScrollView, Text, View } from "react-native";
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context";

export default function Index() {
  const { books } = useLibraryContext();
  const { currentBook } = usePlayerContext();
  return (
    <SafeAreaProvider>
      <SafeAreaView className="flex-1 bg-neutral-800">
        <View className="px-4 mt-4 mb-5 flex-row justify-between items-center">
          <Text className="text-white text-5xl font-cormorantbold">Echoes</Text>
          <ScanBooks />
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
            <View
              className={
                books.length > 0
                  ? "flex-row flex-wrap justify-between"
                  : "flex-col justify-center items-center h-full gap-1"
              }
            >
              {books.length > 0 ? (
                books.map((book, index) => <BookItem key={index} book={book} />)
              ) : (
                <>
                  <Text className="text-neutral-400 text-sm font-semibold">
                    No files found
                  </Text>
                  <Text className="text-neutral-400 text-xs text-center">
                    Please select a different folder or add files to the current
                    one.
                  </Text>
                </>
              )}
            </View>
          </View>
        </ScrollView>
        {currentBook ? <MiniPlayer /> : <></>}
      </SafeAreaView>
    </SafeAreaProvider>
  );
}
