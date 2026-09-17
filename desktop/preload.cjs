const {contextBridge,ipcRenderer}=require('electron');
const listen=(channel,fn)=>{const wrapped=(_event,value)=>fn(value);ipcRenderer.on(channel,wrapped);return()=>ipcRenderer.removeListener(channel,wrapped);};
contextBridge.exposeInMainWorld('paletteDesktop',{
 getPreferences:()=>ipcRenderer.invoke('palette:preferences'),
 setPreferences:p=>ipcRenderer.invoke('palette:set-preferences',p),
 readClipboardImage:()=>ipcRenderer.invoke('palette:clipboard-image'),
 copyCSS:text=>ipcRenderer.invoke('palette:copy-css',text),
 openCollection:()=>ipcRenderer.invoke('palette:open-collection'),
 openSettings:()=>ipcRenderer.invoke('palette:open-settings'),
 hideCapture:()=>ipcRenderer.invoke('palette:hide-capture'),
 hideMain:()=>ipcRenderer.invoke('palette:hide-main'),
 suggestName:colors=>ipcRenderer.invoke('palette:suggest-name',colors),
 onImage:fn=>listen('palette:image',fn),
 onCollectionChanged:fn=>listen('palette:collection-changed',fn),
 onOpenSettings:fn=>listen('palette:open-settings',fn),
 onDismissCapture:fn=>listen('palette:dismiss-capture',fn),
 ready:()=>ipcRenderer.send('palette:ready')
});
