// Checks the public page's collection (lib/collection.ts, siteSource) with a
// stand-in localStorage and collection.json. Run: pnpm check:collection
import {createServer} from 'vite';

const server=await createServer({configFile:false,root:process.cwd(),server:{middlewareMode:true},appType:'custom',logLevel:'error'});
const {siteSource}=await server.ssrLoadModule('/lib/collection.ts');

const store=new Map();
globalThis.localStorage={getItem:k=>store.get(k)??null,setItem:(k,v)=>store.set(k,String(v)),removeItem:k=>store.delete(k)};
let published=[{id:'p1',name:'One',colors:['#111111','#222222','#333333'],main:0,favorite:false,source:'Kika'}];
globalThis.fetch=async()=>({ok:true,json:async()=>published});

let failures=0;
const check=(ok,what)=>{console.log((ok?'  ok   ':'  FAIL ')+what);if(!ok)failures++;};
const source=siteSource('https://example.invalid/collection.json');

await source.load();
check(await source.put({...published[0],favorite:true,main:2}),'a heart and main color on a published palette save');
const saved=JSON.parse(store.get('pallet-site-collection'));
check(saved.saved.length===0&&saved.edits.p1?.favorite===true&&saved.edits.p1?.main===2,'only the two fields are kept, not a copy');

published=[{...published[0],name:'One renamed',colors:['#111111','#222222','#333333','#444444']}];
let list=await source.load();
check(list[0].name==='One renamed'&&list[0].colors.length===4,'a later collection.json edit shows');
check(list[0].favorite===true&&list[0].main===2,'the heart and main color stay');

published=[{...published[0],colors:['#111111','#222222']}];
list=await source.load();
check(list[0].main===0,'a main color past the new end falls back to the published one');

store.set('pallet-site-collection',JSON.stringify({saved:[{...published[0],favorite:true}],hidden:[]}));
list=await source.load();
const migrated=JSON.parse(store.get('pallet-site-collection'));
check(migrated.saved.length===0&&migrated.edits.p1?.favorite===true&&list[0].favorite===true,'an old full copy that only differs by heart becomes an edit');

const own={id:'p1',name:'Imported over it',colors:['#AA0000','#00AA00'],main:1,favorite:false,source:'import'};
await source.put(own);
list=await source.load();
check(list[0].name==='Imported over it'&&!JSON.parse(store.get('pallet-site-collection')).edits.p1,'a palette with other colors under the same id is kept whole');

check(await source.remove('p1')&&!(await source.load()).some(p=>p.id==='p1'),'remove hides it');

await server.close();
console.log(failures?`\n${failures} check(s) failed.`:'\nAll checks passed.');
process.exit(failures?1:0);
