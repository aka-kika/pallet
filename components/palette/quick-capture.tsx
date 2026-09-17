'use client';
import {useCallback,useEffect,useRef,useState} from 'react';
import {ImagePlus,Check,LoaderCircle} from 'lucide-react';
import {capturePalette,imageFile,fromClipboardData} from '@/lib/capture';
import {css,theme,seeds,Palette} from '@/lib/palettes';
import '@/lib/desktop';

export function QuickCapture(){
 const input=useRef<HTMLInputElement>(null),running=useRef(false),hoverUrl=useRef(''),latestRef=useRef<Palette|null>(null);
 const [busy,setBusy]=useState(false),[error,setError]=useState(''),[latest,setLatest]=useState<Palette|null>(null),[dark,setDark]=useState(false),[hover,setHover]=useState('');
 latestRef.current=latest;
 function peek(dt:DataTransfer){const f=imageFile(dt);if(!f||hoverUrl.current)return;hoverUrl.current=URL.createObjectURL(f);setHover(hoverUrl.current);}
 function unpeek(){if(hoverUrl.current){URL.revokeObjectURL(hoverUrl.current);hoverUrl.current='';}setHover('');}
 function reset(){unpeek();setLatest(null);setError('');setBusy(false);running.current=false;}
 useEffect(()=>()=>{if(hoverUrl.current)URL.revokeObjectURL(hoverUrl.current);},[]);
 useEffect(()=>{const media=matchMedia('(prefers-color-scheme: dark)');const sync=()=>{let appearance='system';try{appearance=JSON.parse(localStorage.getItem('palette-prefs')||'{}').appearance||'system';}catch{}setDark(appearance==='dark'||appearance==='system'&&media.matches);};sync();media.addEventListener('change',sync);window.addEventListener('storage',sync);return()=>{media.removeEventListener('change',sync);window.removeEventListener('storage',sync);};},[]);
 useEffect(()=>{const t=theme(latest||seeds[11],dark);Object.entries(t).forEach(([k,v])=>document.documentElement.style.setProperty('--'+k,v));document.documentElement.style.setProperty('--muted-foreground',t.muted);document.documentElement.style.colorScheme=dark?'dark':'light';},[latest,dark]);
 const run=useCallback(async(file:File)=>{if(running.current){setError('A capture is already saving. Try this image again in a moment.');return;}running.current=true;setBusy(true);setError('');unpeek();try{const p=await capturePalette(file);const response=await fetch('/api/palettes',{method:'PUT',headers:{'Content-Type':'application/json'},body:JSON.stringify(p)});if(!response.ok)throw new Error('Could not save. Drop or paste the image again to retry.');setLatest(p);}catch(e){setLatest(null);setError((e as Error).message);}finally{running.current=false;setBusy(false);}},[]);
 const pasteNative=useCallback(async()=>{try{const data=await window.paletteDesktop?.readClipboardImage();if(!data){setError('No image on the clipboard. Copy an image or take a screenshot to the clipboard first.');return;}await run(fromClipboardData(data));}catch(e){setError((e as Error).message);}},[run]);
 const dismiss=useCallback(async()=>{const p=latestRef.current;try{if(p&&window.paletteDesktop){const prefs=await window.paletteDesktop.getPreferences();if(prefs.autoCopyCSS)await window.paletteDesktop.copyCSS(css(p));}}catch{}reset();await window.paletteDesktop?.hideCapture();},[]);
 useEffect(()=>{function paste(e:ClipboardEvent){if((e.target as HTMLElement)?.closest('input,textarea'))return;const file=imageFile(e.clipboardData);e.preventDefault();if(file)void run(file);else void pasteNative();}function key(e:KeyboardEvent){if(e.key==='Escape'){e.preventDefault();void dismiss();}}window.addEventListener('paste',paste);window.addEventListener('keydown',key);const unsub=window.paletteDesktop?.onImage(data=>void run(fromClipboardData(data)));const unsubDismiss=window.paletteDesktop?.onDismissCapture(()=>{void dismiss();});window.paletteDesktop?.ready();return()=>{window.removeEventListener('paste',paste);window.removeEventListener('keydown',key);unsub?.();unsubDismiss?.();};},[run,pasteNative,dismiss]);
 return <main className="quick-capture" onDragEnter={e=>{e.preventDefault();peek(e.dataTransfer);}} onDragOver={e=>{e.preventDefault();peek(e.dataTransfer);}} onDragLeave={e=>{if(!e.currentTarget.contains(e.relatedTarget as Node))unpeek();}} onDrop={e=>{e.preventDefault();unpeek();const file=imageFile(e.dataTransfer);if(file)void run(file);else setError('Drop a JPG, PNG, WebP, GIF, or AVIF image.');}}>
 <input ref={input} type="file" hidden accept="image/png,image/jpeg,image/webp,image/gif,image/avif" onChange={e=>{if(e.target.files?.[0])void run(e.target.files[0]);e.target.value='';}}/>
 <button type="button" className={'capture-drop'+(hover&&!latest?' has-image':'')+(latest?' is-imported':'')} disabled={busy} onClick={()=>input.current?.click()}>
  {busy?<><LoaderCircle className="spin"/><strong>Saving palette…</strong><span>Stay in this window</span></>
   :error?<><strong>Could not import</strong><span>{error}</span></>
   :latest?<><div className="capture-swatches" aria-hidden="true">{latest.colors.map((c,i)=><span key={i} style={{background:c}}/>)}</div><strong className="imported-mark"><Check/>Imported</strong><span>{latest.name}</span></>
   :hover?<><img src={hover} alt=""/><strong>Drop to import</strong><span>or click to choose · ⌘V to paste</span></>
   :<><ImagePlus/><strong>Drop an image</strong><span>or click to choose · ⌘V to paste</span></>}
 </button>
 </main>;
}
