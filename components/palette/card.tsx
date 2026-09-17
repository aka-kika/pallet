'use client';
import {useRef,useState} from 'react';
import {Heart,Check} from 'lucide-react';
import type {Palette} from '@/lib/palettes';
export function PaletteCard({p,active,select,favorite,copy,onMenu}:{p:Palette;active:boolean;select:()=>void;favorite:()=>void;copy:()=>void;onMenu:(e:React.MouseEvent,p:Palette)=>void}){
 const timer=useRef<ReturnType<typeof setTimeout>|null>(null),start=useRef({x:0,y:0}),held=useRef(false);const [touch,setTouch]=useState(false);
 const cancel=()=>{if(timer.current)clearTimeout(timer.current);};
 return <article className={'palette-card'+(active?' selected':'')} data-palette={p.id} onPointerDown={e=>{if(e.pointerType!=='touch')return;setTouch(true);held.current=false;start.current={x:e.clientX,y:e.clientY};if((e.target as HTMLElement).closest('.card-actions'))return;timer.current=setTimeout(()=>{held.current=true;copy();navigator.vibrate?.(15);},550);}} onPointerMove={e=>{if(Math.hypot(e.clientX-start.current.x,e.clientY-start.current.y)>10)cancel();}} onPointerUp={cancel} onPointerCancel={cancel} onContextMenu={e=>{e.preventDefault();e.stopPropagation();if(touch)return;onMenu(e,p);}}>
 <button className="card-palette" aria-label={`Select ${p.name}`} aria-pressed={active} onClick={()=>{if(held.current){held.current=false;return;}select();}}>{p.colors.map((c,i)=><span key={i} style={{background:c}}/>)}{active&&<span className="selected-check"><Check/></span>}</button>
 <div className="card-caption"><button className="card-name" onClick={select}>{p.name}</button><span className="list-colors">{p.colors.length} colors</span><div className="card-actions"><button className="icon-button" title={p.favorite?'Remove favorite':'Favorite'} aria-label={`${p.favorite?'Unfavorite':'Favorite'} ${p.name}`} aria-pressed={p.favorite} onClick={favorite}><Heart fill={p.favorite?'currentColor':'none'}/></button></div></div>
 </article>;
}
