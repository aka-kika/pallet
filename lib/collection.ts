// Where the web app keeps palettes. Two homes:
// - server: the dev preview's /api/palettes (in memory until restart).
// - site: akakika.com/pallet. Kika's collection ships read-only as
//   collection.json (written by scripts/pallet-publish.mjs); a visitor's own
//   palettes and changes stay in their browser (localStorage) and never
//   reach anyone else.
import {seeds,validPalette,paletteEntries,type Palette} from './palettes';

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

// A published palette changed here only by its main color or heart is kept
// as just those two fields, so later edits to collection.json still show.
type Edit={main?:number;favorite?:boolean};
type Local={saved:Palette[];hidden:string[];edits:Record<string,Edit>};
const LOCAL_KEY='pallet-site-collection';
function readLocal():Local{
 try{const j=JSON.parse(localStorage.getItem(LOCAL_KEY)||'{}');return {saved:Array.isArray(j.saved)?j.saved.filter(validPalette):[],hidden:Array.isArray(j.hidden)?j.hidden.filter((x:unknown)=>typeof x==='string'):[],edits:j.edits&&typeof j.edits==='object'&&!Array.isArray(j.edits)?j.edits:{}};}
 catch{return {saved:[],hidden:[],edits:{}};}
}
function writeLocal(l:Local){try{localStorage.setItem(LOCAL_KEY,JSON.stringify(l));return true;}catch{return false;}}
const onlyEdited=(a:Palette,b:Palette)=>a.name===b.name&&a.source===b.source&&a.colors.length===b.colors.length&&a.colors.every((c,i)=>c===b.colors[i]);
function without(edits:Record<string,Edit>,id:string){const rest={...edits};delete rest[id];return rest;}
function applyEdit(p:Palette,e?:Edit):Palette{
 if(!e)return p;
 const main=typeof e.main==='number'&&Number.isInteger(e.main)&&e.main>=0&&e.main<p.colors.length?e.main:p.main;
 return {...p,main,favorite:typeof e.favorite==='boolean'?e.favorite:p.favorite};
}

/** The public page: the published collection plus this browser's own changes. */
export function siteSource(collectionUrl:string):CollectionSource{
 let published:Palette[]=seeds;
 return {
  async load(){
   published=seeds;
   try{
    const r=await fetch(collectionUrl,{cache:'no-cache'});
    const j=r.ok?await r.json():null;
    const list=(paletteEntries(j)??[]).filter(validPalette);
    if(list.length)published=list;
   }catch{}
   const local=readLocal();
   // Full copies saved by earlier versions that differ only by main color or heart become edits.
   const copies=local.saved.filter(p=>published.some(x=>x.id===p.id&&onlyEdited(x,p)));
   if(copies.length){
    for(const p of copies)local.edits[p.id]={main:p.main,favorite:p.favorite};
    local.saved=local.saved.filter(p=>!copies.includes(p));
    writeLocal(local);
   }
   const mine=new Map(local.saved.map(p=>[p.id,p]));
   const base=published.filter(p=>!local.hidden.includes(p.id)).map(p=>mine.get(p.id)??applyEdit(p,local.edits[p.id]));
   const added=local.saved.filter(p=>!published.some(x=>x.id===p.id));
   return [...base,...added];
  },
  async put(p){
   if(!validPalette(p))return false;
   const l=readLocal();
   const hidden=l.hidden.filter(id=>id!==p.id);
   const original=published.find(x=>x.id===p.id);
   if(original&&onlyEdited(original,p)){
    return writeLocal({saved:l.saved.filter(x=>x.id!==p.id),hidden,edits:{...l.edits,[p.id]:{main:p.main,favorite:p.favorite}}});
   }
   const edits=without(l.edits,p.id);
   // An edit keeps its place; only a new palette goes to the end.
   const saved=l.saved.some(x=>x.id===p.id)?l.saved.map(x=>x.id===p.id?p:x):[...l.saved,p];
   return writeLocal({saved,hidden,edits});
  },
  async remove(id){
   const l=readLocal();
   const edits=without(l.edits,id);
   return writeLocal({saved:l.saved.filter(x=>x.id!==id),hidden:l.hidden.includes(id)?l.hidden:[...l.hidden,id],edits});
  },
 };
}
