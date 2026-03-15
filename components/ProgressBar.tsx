import { Slider } from "@miblanchard/react-native-slider";
import { useEffect, useState } from "react";
import { Text, View } from "react-native";

const formatTime = (timeInSeconds: number) => {
  if (!timeInSeconds || isNaN(timeInSeconds)) return "00:00";

  const totalSeconds = Math.floor(timeInSeconds);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;

  return `${minutes.toString().padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`;
};

interface Status {
  duration: number;
  currentTime: number;
}

interface Player {
  seekTo: Function;
}

export default function ProgressBars({
  player,
  status,
}: {
  player: Player;
  status: Status;
}) {
  const [isSliding, setIsSliding] = useState(false);
  const [sliderValue, setSliderValue] = useState(0);

  useEffect(() => {
    if (!isSliding && status.currentTime) {
      setSliderValue(status.currentTime);
    }
  }, [status.currentTime, isSliding]);

  const handleSlidingStart = () => {
    setIsSliding(true);
  };
  const handleValueChange = (value: any) => {
    setSliderValue(value[0]);
  };
  const handleSlidingComplete = (value: any) => {
    player.seekTo(value[0]);
    setIsSliding(false);
  };
  return (
    <View className="w-full px-4">
      <Slider
        minimumValue={0}
        maximumValue={status.duration || 100}
        value={sliderValue}
        minimumTrackTintColor="#D4A017"
        maximumTrackTintColor="#d4d4d4"
        thumbTintColor="#D4A017"
        trackStyle={{ height: 5, borderRadius: 3 }}
        thumbStyle={{ width: 16, height: 16, borderRadius: 8 }}
        onSlidingComplete={handleSlidingComplete}
        onSlidingStart={handleSlidingStart}
        onValueChange={handleValueChange}
      />
      <View className="flex-row justify-between">
        <Text className="text-xs text-neutral-400 font-light">
          {formatTime(status.currentTime)}
        </Text>
        <Text className="text-xs text-neutral-400 font-light">
          -{formatTime(status.duration - status.currentTime)}
        </Text>
      </View>
    </View>
  );
}
