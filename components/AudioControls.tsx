import { Ionicons } from "@expo/vector-icons";
import { TouchableOpacity, View } from "react-native";

interface PlayerType {
  pause: () => void;
  play: () => void;
  seekTo: (time: number) => void;
}
interface StatusType {
  playing: boolean;
  currentTime: number;
  duration: number;
}

interface AudioControlsProps {
  player: PlayerType;
  status: StatusType;
}

export default function AudioControls({ player, status }: AudioControlsProps) {
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
      <Ionicons name="play-skip-back" size={22} color={"#fafafa"} />
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
      <Ionicons name="play-skip-forward" size={22} color={"#fafafa"} />
    </View>
  );
}
