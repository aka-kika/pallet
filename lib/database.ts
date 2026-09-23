// Web preview store. Palettes saved in the browser preview live in memory until
// the dev server restarts. The Mac app keeps its collection on disk (desktop/store.cjs).
import type {Palette} from './palettes';
const saved=new Map<string,Palette>();
export const webStore={list:()=>[...saved.values()].reverse(),put:(p:Palette)=>{saved.delete(p.id);saved.set(p.id,p);},remove:(id:string)=>{saved.delete(id);}};
export {sameOrigin} from './origin';
