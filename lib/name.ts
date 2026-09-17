import {rgb} from './palettes';

const hues:[number,string][]=[[15,'Coral'],[40,'Orange'],[55,'Gold'],[75,'Lime'],[150,'Green'],[175,'Teal'],[200,'Cyan'],[230,'Blue'],[255,'Indigo'],[280,'Violet'],[320,'Magenta'],[345,'Rose'],[361,'Coral']];

function word(hex:string){
 const [r,g,b]=rgb(hex);
 const max=Math.max(r,g,b),min=Math.min(r,g,b);
 const l=(max+min)/510,s=max===min?0:(max-min)/(255*(1-Math.abs(2*l-1)));
 if(s<0.12)return l>0.92?'Snow':l>0.78?'Ivory':l>0.55?'Silver':l>0.32?'Slate':l>0.14?'Charcoal':'Ink';
 let h=Math.atan2(Math.sqrt(3)*(g-b),2*r-g-b)*180/Math.PI;if(h<0)h+=360;
 const hue=hues.find(([end])=>h<end)?.[1]||'Blue';
 if(l<0.18)return hue==='Coral'||hue==='Rose'?'Wine':hue==='Orange'?'Umber':hue==='Gold'?'Bronze':hue==='Blue'||hue==='Indigo'?'Navy':'Ink';
 if(l>0.82)return hue==='Gold'||hue==='Orange'?'Cream':hue==='Coral'||hue==='Rose'?'Blush':'Mist';
 return hue;
}

export function nameFromColors(colors:string[]){
 const words:string[]=[];
 for(const c of colors){
  const w=word(c);
  if(!words.includes(w))words.push(w);
  if(words.length===3)break;
 }
 if(words.length===0)return 'New palette';
 if(words.length===1)return words[0]+' Study';
 if(words.length===2)return words[0]+' & '+words[1];
 return words[0]+', '+words[1]+' & '+words[2];
}

export function isGenericCaptureName(name:string){
 const n=name.replace(/\.[^.]+$/,'').trim();
 return !n||/^(clipboard|image|img|dsc|screenshot|paste|untitled|quick capture|palette)\b/i.test(n)||/\d{4}.\d{2}.\d{2}t\d/i.test(n);
}

export function titleFromFile(file:File,colors:string[]){
 const raw=file.name.replace(/\.[^.]+$/,'').replace(/[-_]/g,' ').replace(/\s+/g,' ').trim();
 if(isGenericCaptureName(raw))return nameFromColors(colors);
 return raw.slice(0,100)||nameFromColors(colors);
}

export async function refineCaptureName(colors:string[],current:string){
 try{
  const next=await window.paletteDesktop?.suggestName?.(colors);
  if(typeof next==='string'&&next.trim())return next.trim().slice(0,100);
 }catch{}
 return current;
}
