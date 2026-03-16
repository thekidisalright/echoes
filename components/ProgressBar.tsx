import { View } from "react-native";

interface ProgressBarProps {
  currentTime: number;
  duration: number;
}

export default function ProgressBar({
  currentTime,
  duration,
}: ProgressBarProps) {
  const progressPercent = duration > 0 ? (currentTime / duration) * 100 : 0;

  return (
    <View className="w-full">
      <View className="w-full h-1 bg-neutral-300 rounded-full overflow-hidden">
        <View
          className="h-full rounded-full"
          style={{ width: `${progressPercent}%`, backgroundColor: "#D4A017" }}
        />
      </View>
    </View>
  );
}
