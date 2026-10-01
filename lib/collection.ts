// Where the web app keeps palettes. Two homes:
// - server: the dev preview's /api/palettes (in memory until restart).
// - site: akakika.com/pallet. Kika's collection ships read-only as
//   collection.json (written by scripts/pallet-publish.mjs); a visitor's own
//   palettes and changes stay in their browser (localStorage) and never
//   reach anyone else.
import {seeds,validPalette,type Palette} from './palettes';

export type CollectionSource={
 load:()=>Promise<Palette[]>;
 put:(p:Palette)=>Promise<boolean>;
 remove:(id:string)=>Promise<boolean>;
};

const order=new Map(seeds.map((p,i)=>[p.id,i]));
const sortBySeeds=(list:Palette[])=>[...list].sort((a,b)=>(order.get(a.id)??1000)-(order.get(b.id)??1000));

export const serverSource:CollectionSource={
 async load(){
  const r=await fetch('/api/palettes');
  if(!r.ok)throw new Error('Your saved collection could not be loaded.');
  const list=await r.json();
  if(!Array.isArray(list)||!list.every(validPalette))throw new Error('Collection response is invalid.');
  return sortBySeeds(list);
 },
 async put(p){
  try{const r=await fetch('/api/palettes',{method:'PUT',headers:{'Content-Type':'application/json'},body:JSON.stringify(p)});return r.ok;}catch{return false;}
 },
 async remove(id){
  try{const r=await fetch('/api/palettes?id='+encodeURIComponent(id),{method:'DELETE'});return r.ok;}catch{return false;}
 },
};

type Local={saved:Palette[];hidden:string[]};
const LOCAL_KEY='pallet-site-collection';
function readLocal():Local{
 try{const j=JSON.parse(localStorage.getItem(LOCAL_KEY)||'{}');return {saved:Array.isArray(j.saved)?j.saved.filter(validPalette):[],hidden:Array.isArray(j.hidden)?j.hidden.filter((x:unknown)=>typeof x==='string'):[]};}
 catch{return {saved:[],hidden:[]};}
}
function writeLocal(l:Local){try{localStorage.setItem(LOCAL_KEY,JSON.stringify(l));return true;}catch{return false;}}

/** The public page: the published collection plus this browser's own changes. */
export function siteSource(collectionUrl:string):CollectionSource{
 return {
  async load(){
   let published:Palette[]=seeds;
   try{
    const r=await fetch(collectionUrl,{cache:'no-cache'});
    const j=r.ok?await r.json():null;
    const list=Array.isArray(j?.palettes)?j.palettes.filter(validPalette):[];
    if(list.length)published=list;
   }catch{}
   const local=readLocal();
   const mine=new Map(local.saved.map(p=>[p.id,p]));
   const base=published.filter(p=>!local.hidden.includes(p.id)).map(p=>mine.get(p.id)??p);
   const added=local.saved.filter(p=>!published.some(x=>x.id===p.id));
   return [...base,...added];
  },
  async put(p){
   if(!validPalette(p))return false;
   const l=readLocal();
   return writeLocal({saved:[...l.saved.filter(x=>x.id!==p.id),p],hidden:l.hidden.filter(id=>id!==p.id)});
  },
  async remove(id){
   const l=readLocal();
   return writeLocal({saved:l.saved.filter(x=>x.id!==id),hidden:l.hidden.includes(id)?l.hidden:[...l.hidden,id]});
  },
 };
}
