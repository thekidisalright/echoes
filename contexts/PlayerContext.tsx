import { useLibraryContext } from "@/contexts/LibraryContext";
import type { Book, Bookmark } from "@/src/models";
import { addBookmark, getLastPlayed, listBookmarks, saveLastPlayed, savePlayback } from "@/src/storage";
import { AudioPlaylist, AudioPlaylistStatus, setAudioModeAsync, useAudioPlaylist, useAudioPlaylistStatus } from "expo-audio";
import { createContext, ReactNode, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import { AppState } from "react-native";

type PlayerContextType = {
  currentBook: Book | null; currentChapterIndex: number; player: AudioPlaylist; status: AudioPlaylistStatus;
  setCurrentBook: (book: Book | null) => void; setCurrentChapterIndex: (index: number) => void;
  openBook: (book: Book, play?: boolean) => Promise<void>; playChapter: (index: number) => Promise<void>;
  skip: { forward: () => void; back: () => void }; saveProgress: () => Promise<void>;
  bookmarks: Bookmark[]; addCurrentBookmark: () => Promise<void>; removeCurrentBookmark: (id: string) => Promise<void>;
  setSleepTimer: (minutes: number | "chapter") => void; cancelSleepTimer: () => void; sleepTimer: number | "chapter" | null;
};
function lockScreenMetadata(book: Book, chapterIndex: number) {
  const artworkUrl = book.coverImageUri && /^(https?:|file:)/i.test(book.coverImageUri) ? book.coverImageUri : undefined;
  return { title: book.chapters[chapterIndex]?.name || book.title, artist: book.author, albumTitle: book.title, ...(artworkUrl ? { artworkUrl } : {}) };
}
export const PlayerContext = createContext<PlayerContextType | undefined>(undefined);
export function PlayerProvider({children}:{children:ReactNode}) {
  const playlist=useAudioPlaylist({sources:[],loop:"none",updateInterval:500});
  const status=useAudioPlaylistStatus(playlist);
  const {books,refresh}=useLibraryContext();
  const [currentBook,setBook]=useState<Book|null>(null); const [bookmarks,setBookmarks]=useState<Bookmark[]>([]);
  const [sleepTimer,setSleep]=useState<number|"chapter"|null>(null);
  const bookRef=useRef<Book|null>(null); const currentIndex=status.currentIndex ?? 0; const indexRef=useRef(0);
  const lastSavedAt=useRef(0); const sleepDeadline=useRef<number|null>(null); const sleepChapter=useRef<number|null>(null);
  const lastPosition=useRef(0); const wasPlaying=useRef(false); const observedIndex=useRef(0);
  useEffect(()=>{bookRef.current=currentBook;},[currentBook]); useEffect(()=>{indexRef.current=currentIndex;},[currentIndex]);
  useEffect(()=>{void setAudioModeAsync({playsInSilentMode:true,shouldPlayInBackground:true,interruptionMode:"doNotMix"});},[]);
  const saveProgress=useCallback(async()=>{const book=bookRef.current; const index=indexRef.current; if(!book||!book.chapters[index])return;
    await savePlayback(book.id,book.chapters[index].id,playlist.currentTime||0); await saveLastPlayed(book.id); lastSavedAt.current=Date.now();},[playlist]);
  const openBook=useCallback(async(book:Book,play=false)=>{
    if(bookRef.current?.id===book.id) { if(play)playlist.play(); return; }
    if(bookRef.current?.id) await saveProgress();
    setBook(book); bookRef.current=book;
    playlist.pause(); playlist.clear(); book.chapters.forEach(ch=>playlist.add({uri:ch.uri,name:ch.name}));
    const index=Math.min(book.savedChapterIndex||0,Math.max(0,book.chapters.length-1)); indexRef.current=index;
    if(book.chapters.length){playlist.skipTo(index); if(book.savedPosition>0) setTimeout(()=>{void playlist.seekTo(book.savedPosition);},350);}
    playlist.setActiveForLockScreen(true,lockScreenMetadata(book,index),{showNextTrack:true,showPreviousTrack:true,showSeekBackward:true,showSeekForward:true});
    if(play) playlist.play(); await saveLastPlayed(book.id);
    if(book.chapters[index]) await savePlayback(book.id,book.chapters[index].id,book.savedPosition||0);
    await refresh();
  },[playlist,saveProgress,refresh]);
  const setCurrentBook=useCallback((book:Book|null)=>{if(book)void openBook(book,false);else{playlist.pause();setBook(null);}},[openBook,playlist]);
  const playChapter=useCallback(async(index:number)=>{const book=bookRef.current;if(!book||index<0||index>=book.chapters.length)return;
    await saveProgress(); playlist.skipTo(index); indexRef.current=index; setTimeout(()=>{void playlist.seekTo(0);playlist.play();},120);
  },[playlist,saveProgress]);
  const setCurrentChapterIndex=useCallback((index:number)=>{void playChapter(index);},[playChapter]);
  const forward=useCallback(()=>{if(currentIndex < (bookRef.current?.chapters.length||0)-1)void playChapter(currentIndex+1);},[currentIndex,playChapter]);
  const back=useCallback(()=>{if(currentIndex>0)void playChapter(currentIndex-1);else void playlist.seekTo(0);},[currentIndex,playChapter,playlist]);
  useEffect(()=>{const sub=AppState.addEventListener("change",state=>{if(state==="background"||state==="inactive")void saveProgress();}); return()=>sub.remove();},[saveProgress]);
  useEffect(()=>{const id=setInterval(()=>{if(playlist.playing)void saveProgress();},10000);return()=>clearInterval(id);},[playlist,saveProgress]);
  useEffect(()=>{lastPosition.current=status.currentTime||0;},[status.currentTime]);
  useEffect(()=>{if(status.didJustFinish&&sleepChapter.current===currentIndex){playlist.pause();sleepChapter.current=null;setSleep(null);}},[status.didJustFinish,currentIndex,playlist]);
  useEffect(()=>{if(wasPlaying.current&&!status.playing)void saveProgress();wasPlaying.current=status.playing;},[status.playing,saveProgress]);
  useEffect(()=>{const sub=playlist.addListener("trackChanged",({currentIndex:index})=>{
    const previous=observedIndex.current; const book=bookRef.current;
    if(book?.chapters[previous]&&previous!==index)void savePlayback(book.id,book.chapters[previous].id,lastPosition.current||0);
    indexRef.current=index; if(book?.chapters[index]) playlist.updateLockScreenMetadata(lockScreenMetadata(book,index));
    observedIndex.current=index; lastPosition.current=0;
    if(sleepChapter.current!==null && index!==sleepChapter.current){playlist.pause();sleepChapter.current=null;setSleep(null);}
  }); return()=>sub.remove();},[playlist]);
  useEffect(()=>{if(currentBook){void listBookmarks(currentBook.id).then(setBookmarks);}},[currentBook]);
  useEffect(()=>{if(!sleepDeadline.current)return;const id=setInterval(()=>{if(Date.now()>=sleepDeadline.current!){playlist.pause();sleepDeadline.current=null;setSleep(null);}},750);return()=>clearInterval(id);},[playlist,sleepTimer]);
  useEffect(()=>{if(books.length){void getLastPlayed().then(id=>{const b=books.find(item=>item.id===id);if(b&&!bookRef.current)void openBook(b,false);});}},[books,openBook]);
  const addCurrentBookmark=useCallback(async()=>{const book=bookRef.current;if(!book||!book.chapters[currentIndex])return;const mark=await addBookmark(book.id,book.chapters[currentIndex].id,playlist.currentTime||0);setBookmarks(prev=>[mark,...prev]);},[currentIndex,playlist]);
  const removeCurrentBookmark=useCallback(async(id:string)=>{const {removeBookmark}=await import("@/src/storage");await removeBookmark(id);setBookmarks(prev=>prev.filter(b=>b.id!==id));},[]);
  const setSleepTimer=useCallback((minutes:number|"chapter")=>{if(minutes==="chapter"){sleepDeadline.current=null;sleepChapter.current=currentIndex;setSleep("chapter");}else{sleepChapter.current=null;sleepDeadline.current=Date.now()+minutes*60000;setSleep(minutes);}},[currentIndex]);
  const cancelSleepTimer=useCallback(()=>{sleepDeadline.current=null;sleepChapter.current=null;setSleep(null);},[]);
  const value=useMemo(()=>({currentBook,currentChapterIndex:currentIndex,player:playlist,status,setCurrentBook,setCurrentChapterIndex,openBook,playChapter,skip:{forward,back},saveProgress,bookmarks,addCurrentBookmark,removeCurrentBookmark,setSleepTimer,cancelSleepTimer,sleepTimer}),[currentBook,currentIndex,playlist,status,setCurrentBook,setCurrentChapterIndex,openBook,playChapter,forward,back,saveProgress,bookmarks,addCurrentBookmark,removeCurrentBookmark,setSleepTimer,cancelSleepTimer,sleepTimer]);
  return <PlayerContext.Provider value={value}>{children}</PlayerContext.Provider>;
}
export function usePlayerContext(){const value=useContext(PlayerContext);if(!value)throw new Error("PlayerProvider ausente");return value;}
