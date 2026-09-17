const fs=require('node:fs');
const path=require('node:path');
function createStore(directory,seeds){
 fs.mkdirSync(directory,{recursive:true});
 const file=path.join(directory,'palettes.json');
 const hiddenFile=path.join(directory,'hidden.json');
 let palettes=fs.existsSync(file)?JSON.parse(fs.readFileSync(file,'utf8')):[];
 let hidden=fs.existsSync(hiddenFile)?JSON.parse(fs.readFileSync(hiddenFile,'utf8')):[];
 if(!Array.isArray(palettes))throw new Error('Palette data is not an array. Restore a backup before continuing.');
 if(!Array.isArray(hidden))hidden=[];
 function write(next,nextHidden){fs.writeFileSync(file+'.tmp',JSON.stringify(next,null,2),{mode:0o600});fs.renameSync(file+'.tmp',file);fs.writeFileSync(hiddenFile+'.tmp',JSON.stringify(nextHidden,null,2),{mode:0o600});fs.renameSync(hiddenFile+'.tmp',hiddenFile);palettes=next;hidden=nextHidden;}
 return {all:()=>[...seeds.filter(s=>!palettes.some(p=>p.id===s.id)&&!hidden.includes(s.id)),...palettes],put(p){write([...palettes.filter(v=>v.id!==p.id),p],hidden.filter(id=>id!==p.id));},remove(id){if(typeof id!=='string'||!/^[\w-]{1,80}$/.test(id))throw new Error('Invalid palette');write(palettes.filter(p=>p.id!==id),hidden.includes(id)?hidden:[...hidden,id]);}};
}
module.exports={createStore};
