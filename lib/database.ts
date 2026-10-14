// Web preview store. Palettes saved in the browser preview live in memory until
// the dev server restarts. The Mac app keeps its collection on disk (swiftui/Pallet/Model/Palette.swift).
// Deleted starter palettes are remembered in `hidden` so they stay gone.
import {seeds,type Palette} from './palettes';
const saved=new Map<string,Palette>(),hidden=new Set<string>();
export const webStore={
 list:()=>[...saved.values()].reverse(),
 hidden:(id:string)=>hidden.has(id),
 // Map.set keeps an existing key in place, so an edit doesn't reorder the list.
 put:(p:Palette)=>{saved.set(p.id,p);hidden.delete(p.id);},
 remove:(id:string)=>{saved.delete(id);if(seeds.some(s=>s.id===id))hidden.add(id);},
};
export {sameOrigin} from './origin';
