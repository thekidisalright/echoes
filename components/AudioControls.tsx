import { Ionicons } from "@expo/vector-icons";
import { TouchableOpacity, View } from "react-native";

interface Player {
  pause: Function;
  play: Function;
}
interface Status {
  playing: boolean;
}

export default function AudioControls({
  player,
  status,
}: {
  player: Player;
  status: Status;
}) {
  const togglePlayPause = () => {
    if (status.playing) {
      player.pause();
    } else {
      player.play();
    }
  };
  return (
    <View className="flex-row items-center justify-center gap-8 px-4">
      <Ionicons name="play-skip-back" size={22} color={"#fafafa"} />
      <Ionicons name="play-back" size={32} color={"#fafafa"} />
      <TouchableOpacity onPress={togglePlayPause}>
        <Ionicons
          name={status.playing ? "pause-circle" : "play-circle"}
          size={72}
          color={"#fafafa"}
        />
      </TouchableOpacity>
      <Ionicons name="play-forward" size={32} color={"#fafafa"} />
      <Ionicons name="play-skip-forward" size={22} color={"#fafafa"} />
    </View>
  );
}
