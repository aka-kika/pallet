'use client';
import {useEffect,useRef,useState} from 'react';
import {Dialog,DialogContent,DialogTitle,DialogDescription} from '@/components/ui/dialog';
import {Tabs,TabsList,TabsTrigger} from '@/components/ui/tabs';
import {RadioGroup,RadioGroupItem} from '@/components/ui/radio-group';
import {ShieldCheck} from 'lucide-react';
import {parseHex} from '@/lib/palettes';
import {CaptureSettings,CaptureSettingsHandle} from './capture-settings';
export function Settings({open,onClose,tab,setTab,appearance,setAppearance,autoImportOnDrop,setAutoImportOnDrop,hideKeyboardGuide,setHideKeyboardGuide,view,setView,bgLock,setBgLock}:{open:boolean;onClose:()=>void;tab:string;setTab:(v:string)=>void;appearance:string;setAppearance:(s:string)=>void;autoImportOnDrop:boolean;setAutoImportOnDrop:(v:boolean)=>void;hideKeyboardGuide:boolean;setHideKeyboardGuide:(v:boolean)=>void;view:string;setView:(v:string)=>void;bgLock:string|null;setBgLock:(v:string|null)=>void}){
 const [saving,setSaving]=useState(false),[hexField,setHexField]=useState(bgLock||'');
 const captureRef=useRef<CaptureSettingsHandle>(null);
 const snap=useRef({appearance,autoImportOnDrop,hideKeyboardGuide,view,bgLock});
 useEffect(()=>{if(open){snap.current={appearance,autoImportOnDrop,hideKeyboardGuide,view,bgLock};setHexField(bgLock||'');}},[open]);
 function cancel(){setAppearance(snap.current.appearance);setAutoImportOnDrop(snap.current.autoImportOnDrop);setHideKeyboardGuide(snap.current.hideKeyboardGuide);setView(snap.current.view);setBgLock(snap.current.bgLock);onClose();}
 async function save(){setSaving(true);try{if(!await captureRef.current?.save())return;snap.current={appearance,autoImportOnDrop,hideKeyboardGuide,view,bgLock};onClose();}finally{setSaving(false);}}
 function onHex(v:string){setHexField(v);if(!v.trim()){setBgLock(null);return;}const hex=parseHex(v);if(hex)setBgLock(hex);}
 return <Dialog open={open} onOpenChange={v=>!v&&cancel()}><DialogContent className="settings-panel"><DialogTitle>Settings</DialogTitle><DialogDescription>App and menu bar.</DialogDescription>
 <Tabs value={tab} onValueChange={setTab}><TabsList className="settings-tabs"><TabsTrigger value="app">App</TabsTrigger><TabsTrigger value="menubar">Menu bar</TabsTrigger></TabsList></Tabs>
 {tab==='app'&&<>
 <div className="field"><label>Appearance</label><RadioGroup className="appearance" value={appearance} onValueChange={setAppearance}>{['light','dark','system'].map(v=><label key={v}><RadioGroupItem value={v}/>{v==='dark'?'Soft dark':v[0].toUpperCase()+v.slice(1)}</label>)}</RadioGroup></div>
 <div className="field"><label>Collection layout</label><RadioGroup className="appearance" value={view} onValueChange={setView}><label><RadioGroupItem value="grid"/>Cards</label><label><RadioGroupItem value="list"/>List</label></RadioGroup></div>
 <label className="capture-checkbox"><input type="checkbox" checked={autoImportOnDrop} onChange={e=>setAutoImportOnDrop(e.target.checked)}/>Import dropped images without opening Add image</label>
 <p className="helper">Extracts locally and adds the palette to the collection. The Add image button still opens the window so you can name it or remove colors first.</p>
 <label className="capture-checkbox"><input type="checkbox" checked={hideKeyboardGuide} onChange={e=>setHideKeyboardGuide(e.target.checked)}/>Hide keyboard shortcuts at the bottom</label>
 <p className="helper">Space, ⌘C, and the other keys still work. Turn this on once you know them.</p>
 <div className="field"><label htmlFor="bg-lock-hex">Lock background</label><input id="bg-lock-hex" value={hexField} placeholder="#16181E" spellCheck={false} autoComplete="off" maxLength={7} onChange={e=>onHex(e.target.value)}/><p className="helper">Keeps this color as the app background while you shuffle. L or the lock icon captures the current background. Clear the field to unlock.</p></div>
 <div className="notice"><ShieldCheck/><p>Local color extraction samples pixels on this device. No key, no upload. On Mac, Apple Intelligence can refine the palette name.</p></div>
 </>}
 {open&&<div hidden={tab!=='menubar'}><CaptureSettings ref={captureRef}/></div>}
 <div className="dialog-actions"><button type="button" className="button" onClick={cancel}>Cancel</button><button type="button" className="button primary" disabled={saving} onClick={()=>void save()}>{saving?'Saving…':'Save'}</button></div>
 </DialogContent></Dialog>;
}
