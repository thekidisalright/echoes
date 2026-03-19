import { usePlayerContext } from "@/contexts/PlayerContext";
import { Ionicons } from "@expo/vector-icons";
import { TouchableOpacity, View } from "react-native";

export default function AudioControls() {
  const { player, status, skip } = usePlayerContext();
  const togglePlayPause = () => {
    if (status.playing) {
      player.pause();
    } else {
      player.play();
    }
  };
  const forward = () => {
    const newTime = Math.min(status.duration || 0, status.currentTime + 15);
    player.seekTo(newTime);
  };
  const back = () => {
    const newTime = Math.max(0, status.currentTime - 15);
    player.seekTo(newTime);
  };
  return (
    <View className="flex-row items-center justify-center gap-8 px-4">
      <TouchableOpacity onPress={skip.back}>
        <Ionicons name="play-skip-back" size={22} color={"#fafafa"} />
      </TouchableOpacity>
      <TouchableOpacity onPress={back}>
        <Ionicons name="play-back" size={32} color={"#fafafa"} />
      </TouchableOpacity>
      <TouchableOpacity onPress={togglePlayPause}>
        <Ionicons
          name={status.playing ? "pause-circle" : "play-circle"}
          size={72}
          color={"#fafafa"}
        />
      </TouchableOpacity>
      <TouchableOpacity onPress={forward}>
        <Ionicons name="play-forward" size={32} color={"#fafafa"} />
      </TouchableOpacity>
      <TouchableOpacity onPress={skip.forward}>
        <Ionicons name="play-skip-forward" size={22} color={"#fafafa"} />
      </TouchableOpacity>
    </View>
  );
}
