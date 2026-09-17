import {extract} from './extract';
import type {Palette} from './palettes';
import {refineCaptureName,titleFromFile} from './name';

function looksLikeImage(file:File){
 return file.type.startsWith('image/')||/\.(png|jpe?g|gif|webp|avif|bmp|heic|heif)$/i.test(file.name);
}
export function imageFile(transfer:DataTransfer|null):File|null {
 if(!transfer)return null;
 for(const item of Array.from(transfer.items||[])){
  if(item.kind!=='file')continue;
  const file=item.getAsFile();
  if(file&&looksLikeImage(file))return file;
 }
 return Array.from(transfer.files||[]).find(looksLikeImage)||null;
}
export async function capturePalette(file:File):Promise<Palette>{
 const {colors}=await extract(file);
 const name=await refineCaptureName(colors,titleFromFile(file,colors));
 return {id:'palette-'+Array.from(crypto.getRandomValues(new Uint8Array(16)),n=>n.toString(16).padStart(2,'0')).join(''),name,colors,main:0,favorite:false,source:'Local quick capture · sampled colors'};
}
export function fromClipboardData(data:{name:string;dataUrl:string}):File {
 const [meta,base64]=data.dataUrl.split(',');
 const binary=atob(base64);const bytes=Uint8Array.from(binary,c=>c.charCodeAt(0));
 return new File([bytes],data.name,{type:meta.slice(5).split(';')[0]});
}
