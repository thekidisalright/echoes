import AudioControls from "@/components/AudioControls";
import SliderComponent from "@/components/Slider";
import { usePlayerContext } from "@/contexts/PlayerContext";
import { Ionicons } from "@expo/vector-icons";
import { Link, useRouter } from "expo-router";
import { useMemo, useRef, useState } from "react";
import { Alert, Animated, Image, PanResponder, ScrollView, StatusBar, Text, TouchableOpacity, useWindowDimensions, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

export default function PlayerScreen() {
  const {currentBook,currentChapterIndex,setSleepTimer,cancelSleepTimer,sleepTimer,addCurrentBookmark}=usePlayerContext();
  const {width,height}=useWindowDimensions(); const [saved,setSaved]=useState(false); const router=useRouter();
  const dragY=useRef(new Animated.Value(0)).current;
  const panResponder=useMemo(()=>PanResponder.create({
    onMoveShouldSetPanResponder:(_event,gesture)=>gesture.dy>16&&Math.abs(gesture.dy)>Math.abs(gesture.dx)*1.2,
    onPanResponderMove:(_event,gesture)=>{if(gesture.dy>0)dragY.setValue(gesture.dy);},
    onPanResponderRelease:(_event,gesture)=>{
      if(gesture.dy>120||gesture.vy>0.8){Animated.timing(dragY,{toValue:height,duration:180,useNativeDriver:true}).start(()=>router.back());}
      else Animated.spring(dragY,{toValue:0,useNativeDriver:true,bounciness:0}).start();
    },
    onPanResponderTerminate:()=>Animated.spring(dragY,{toValue:0,useNativeDriver:true,bounciness:0}).start(),
  }),[dragY,height,router]);
  if(!currentBook) return <SafeAreaView className="flex-1 bg-[#171614] items-center justify-center"><Text className="text-[#d5d4cf]">Nenhum audiobook selecionado.</Text></SafeAreaView>;
  const pickTimer=()=>Alert.alert("Temporizador", "Quando deseja pausar?",[
    {text:"15 minutos",onPress:()=>setSleepTimer(15)},{text:"30 minutos",onPress:()=>setSleepTimer(30)},{text:"45 minutos",onPress:()=>setSleepTimer(45)},{text:"60 minutos",onPress:()=>setSleepTimer(60)},{text:"Ao fim do capítulo",onPress:()=>setSleepTimer("chapter")},{text:"Cancelar",style:"cancel"}
  ]);
  const onBookmark=async()=>{await addCurrentBookmark();setSaved(true);setTimeout(()=>setSaved(false),1500);};
  const coverSize=Math.min(width>720?480:width-64,height*.45);
  return <SafeAreaView className="flex-1 bg-[#171614]"><StatusBar barStyle="light-content"/><Animated.View className="flex-1" style={{transform:[{translateY:dragY}]}} {...panResponder.panHandlers}><ScrollView contentContainerStyle={{paddingHorizontal:24,paddingTop:12,paddingBottom:26,flexGrow:1,justifyContent:"space-between"}}>
    <View className="flex-row justify-between items-center"><TouchableOpacity onPress={()=>router.back()} accessibilityLabel="Voltar"><Ionicons name="chevron-down" size={25} color="#aaa9a3"/></TouchableOpacity><Text className="text-[#aaa9a3] text-sm flex-1 text-center" numberOfLines={1}>{currentBook.author||"Audiobook"}</Text><View className="w-8"/></View>
    <View className="self-center my-7 rounded-xl overflow-hidden bg-[#292720] items-center justify-center" style={{width:coverSize,height:coverSize, maxWidth:480,maxHeight:480}}>{currentBook.coverImageUri?<Image source={{uri:currentBook.coverImageUri}} resizeMode="cover" style={{width:"100%",height:"100%"}}/>:<Ionicons name="book-outline" size={76} color="#8a7957"/>}</View>
    <View><Text className="text-[#d5d4cf] text-3xl font-cormorantbold" numberOfLines={2}>{currentBook.title}</Text><Text className="text-[#aaa9a3] text-base mt-1" numberOfLines={1}>{currentBook.chapters[currentChapterIndex]?.name||"Capítulo indisponível"}</Text><Text className="text-[#85857f] text-xs mt-1">Capítulo {currentChapterIndex+1} de {currentBook.chapters.length}</Text>
      <SliderComponent/><AudioControls/>
      <View className="flex-row justify-around mt-5"><TouchableOpacity onPress={pickTimer} className="items-center py-2 px-4"><Ionicons name="moon-outline" size={23} color={sleepTimer?"#d1aa65":"#aaa9a3"}/><Text className="text-[#aaa9a3] text-xs mt-1">{sleepTimer?"Timer ativo":"Temporizador"}</Text></TouchableOpacity><TouchableOpacity onPress={()=>void onBookmark()} className="items-center py-2 px-4"><Ionicons name={saved?"bookmark":"bookmark-outline"} size={23} color="#d1aa65"/><Text className="text-[#aaa9a3] text-xs mt-1">{saved?"Salvo":"Marcador"}</Text></TouchableOpacity><Link href="/chapters" asChild><TouchableOpacity className="items-center py-2 px-4"><Ionicons name="list-outline" size={23} color="#aaa9a3"/><Text className="text-[#aaa9a3] text-xs mt-1">Capítulos</Text></TouchableOpacity></Link></View>
      {sleepTimer&&<TouchableOpacity onPress={cancelSleepTimer} className="self-center mt-2"><Text className="text-[#d1aa65] text-xs">Cancelar temporizador</Text></TouchableOpacity>}
    </View>
  </ScrollView></Animated.View></SafeAreaView>;
}
