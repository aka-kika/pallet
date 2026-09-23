export type CaptureSize='mini'|'miny'|'mo';
export type AppPresence='both'|'dock'|'menubar';
export type CapturePreferences={autoCopyCSS:boolean;shortcut:string;shortcutRegistered:boolean;captureSize:CaptureSize;appPresence:AppPresence};
export type DesktopBridge={
 getPreferences:()=>Promise<CapturePreferences>;
 setPreferences:(p:{autoCopyCSS:boolean;shortcut:string;captureSize:CaptureSize;appPresence:AppPresence})=>Promise<CapturePreferences>;
 readClipboardImage:()=>Promise<{name:string;dataUrl:string}|null>;
 copyCSS:(text:string)=>Promise<void>;
 openCollection:()=>Promise<void>;
 openSettings:()=>Promise<void>;
 hideCapture:()=>Promise<void>;
 hideMain:()=>Promise<void>;
 suggestName:(colors:string[])=>Promise<string|null>;
 onImage:(fn:(image:{name:string;dataUrl:string})=>void)=>()=>void;
 onCollectionChanged:(fn:()=>void)=>()=>void;
 onOpenSettings:(fn:()=>void)=>()=>void;
 onDismissCapture:(fn:()=>void)=>()=>void;
 ready:()=>void;
};
declare global {interface Window {paletteDesktop?:DesktopBridge}}
