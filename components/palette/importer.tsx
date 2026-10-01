'use client';
import {useRef,useState,useEffect} from 'react';
import {ImagePlus,Upload,LoaderCircle,X} from 'lucide-react';
import {Dialog,DialogContent,DialogTitle,DialogDescription} from '@/components/ui/dialog';
import {extract} from '@/lib/extract';
import {Palette,ink} from '@/lib/palettes';
import {imageFile} from '@/lib/capture';
import {titleFromFile} from '@/lib/name';
export function Importer({open,onClose,file,onSave}:{open:boolean;onClose:()=>void;file:File|null;onSave:(p:Palette)=>Promise<boolean>}){
 const input=useRef<HTMLInputElement>(null),hoverUrl=useRef('');
 const [busy,setBusy]=useState(false),[error,setError]=useState(''),[draft,setDraft]=useState<Palette|null>(null),[preview,setPreview]=useState(''),[current,setCurrent]=useState<File|null>(null),[thumb,setThumb]=useState(''),[hover,setHover]=useState(''),[over,setOver]=useState(false);
 const shown=thumb||hover;
 function peek(dt:DataTransfer){const f=imageFile(dt);if(!f||hoverUrl.current)return;hoverUrl.current=URL.createObjectURL(f);setHover(hoverUrl.current);}
 function unpeek(){if(hoverUrl.current){URL.revokeObjectURL(hoverUrl.current);hoverUrl.current='';}setHover('');setOver(false);}
 useEffect(()=>{if(open){setError('');setDraft(null);setPreview('');setCurrent(file);unpeek();}},[open,file]);
 useEffect(()=>{if(!current){setThumb('');return;}const url=URL.createObjectURL(current);setThumb(url);return()=>URL.revokeObjectURL(url);},[current]);
 useEffect(()=>()=>{if(hoverUrl.current)URL.revokeObjectURL(hoverUrl.current);},[]);
 useEffect(()=>{if(!open)return;function paste(e:ClipboardEvent){if(busy||draft)return;const f=imageFile(e.clipboardData);if(f){e.preventDefault();setCurrent(f);setError('');}}window.addEventListener('paste',paste);return()=>window.removeEventListener('paste',paste);},[open,busy,draft]);
 async function run(f:File){setBusy(true);setError('');try{const local=await extract(f);const colors=local.colors,name=titleFromFile(f,local.colors);setPreview(local.dataUrl);setDraft({id:'palette-'+Array.from(crypto.getRandomValues(new Uint8Array(16)),n=>n.toString(16).padStart(2,'0')).join(''),name:name.slice(0,100)||'New palette',colors,main:0,favorite:false,source:'Local image extraction · sampled colors'});}catch(e){setError((e as Error).message);}finally{setBusy(false);}}
 return <Dialog open={open} onOpenChange={v=>!busy&&!v&&onClose()}><DialogContent className="import-panel"><DialogTitle>Add image</DialogTitle><DialogDescription>Extract a palette, choose its main color, and save both modes.</DialogDescription>
 <input ref={input} hidden type="file" accept="image/png,image/jpeg,image/webp,image/gif,image/avif" onChange={e=>{setCurrent(e.target.files?.[0]||null);setDraft(null);setError('');e.target.value='';}}/>
 {!draft?<><button type="button" className={'drop-target'+(shown?' has-image':'')+(over?' is-over':'')} disabled={busy} onClick={()=>input.current?.click()} onDragEnter={e=>{e.preventDefault();setOver(true);peek(e.dataTransfer);}} onDragOver={e=>{e.preventDefault();e.dataTransfer.dropEffect='copy';setOver(true);peek(e.dataTransfer);}} onDragLeave={e=>{if(!e.currentTarget.contains(e.relatedTarget as Node))unpeek();}} onDrop={e=>{e.preventDefault();e.stopPropagation();unpeek();const f=imageFile(e.dataTransfer)||e.dataTransfer.files[0]||null;if(f){setCurrent(f);setDraft(null);setError('');}}}>{shown?<img src={shown} alt={current?.name||'Dropped image'}/>:<ImagePlus size={30}/>}{shown?null:<strong>Drop an image here</strong>}<span>{shown?'Click to choose another · up to 20 MB':'or choose a file · up to 20 MB'}</span></button>
 <p className="helper">Samples visible pixels on this device. No image leaves this Mac.</p>
 <button className="button primary" disabled={!current||busy} onClick={()=>current&&run(current)}>{busy?<LoaderCircle className="spin"/>:<Upload/>}{busy?'Extracting…':'Extract palette'}</button></>:<>
 <div className="import-result"><img src={preview} alt="Imported palette reference"/><div><label htmlFor="palette-name">Palette name</label><input id="palette-name" maxLength={100} value={draft.name} onChange={e=>setDraft({...draft,name:e.target.value})}/><p className="helper">Click a swatch to set the main color. × removes a color. Edit any hex below.</p></div></div>
 <div className="edit-swatches">{draft.colors.map((c,i)=>{const tone=/^#[0-9a-f]{6}$/i.test(c)?ink(c):undefined;return <div className="edit-swatch" key={i}><div className="edit-swatch-chip" style={{color:tone}}><button type="button" className="edit-swatch-color" style={{background:c,color:tone}} aria-label={`Main color ${c}`} aria-pressed={draft.main===i} onClick={()=>setDraft({...draft,main:i})}>{draft.main===i?'Main':''}</button>{draft.colors.length>2&&<button type="button" className="edit-swatch-remove" aria-label={`Remove ${c}`} onClick={()=>{const colors=draft.colors.filter((_,j)=>j!==i);setDraft({...draft,colors,main:i===draft.main?0:i<draft.main?draft.main-1:draft.main});}}><X/></button>}</div><input aria-label={`Hex color ${i+1}`} value={c} maxLength={7} onChange={e=>{const colors=[...draft.colors];colors[i]=e.target.value;setDraft({...draft,colors});}}/></div>;})}</div>
 <div className="dialog-actions"><button className="button" disabled={busy} onClick={()=>setDraft(null)}>Back</button><button className="button primary" disabled={busy||!draft.name.trim()||draft.colors.length<2||!draft.colors.every(c=>/^#[0-9a-f]{6}$/i.test(c))} onClick={async()=>{setBusy(true);const ok=await onSave(draft);setBusy(false);if(ok)onClose();else setError('Could not save. Your palette is still here. Try again.');}}>{busy?'Saving…':'Add to collection'}</button></div>
 </>}{error&&<p className="notice warning" role="alert">{error}</p>}
 </DialogContent></Dialog>;
}
