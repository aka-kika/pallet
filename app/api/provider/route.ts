import {sameOrigin} from '@/lib/origin';
import {extractionPrompt,parseColors} from '@/lib/providers';
const bases:Record<string,string>={meta:'https://api.meta.ai/v1',openai:'https://api.openai.com/v1',anthropic:'https://api.anthropic.com/v1',gemini:'https://generativelanguage.googleapis.com/v1beta',openrouter:'https://openrouter.ai/api/v1'};
export async function POST(req:Request){
 if(!sameOrigin(req))return new Response('Forbidden',{status:403});
 if(Number(req.headers.get('content-length')||0)>5000000)return new Response('Image too large',{status:413});
 try{
 const text=await req.text();if(text.length>5000000)return new Response('Image too large',{status:413});
 let parsed;try{parsed=JSON.parse(text);}catch{return Response.json({error:'Invalid request JSON'},{status:400});}
 const {provider,key,model,action,dataUrl}=parsed;
 if(!bases[provider]||!['models','extract'].includes(action))return Response.json({error:'Unsupported provider or action'},{status:400});
 if(typeof key!=='string'||key.length<5||key.length>4096)return Response.json({error:'Add your provider API key in Settings first.'},{status:400});
 const headers:Record<string,string>={'Content-Type':'application/json'};
 if(provider==='anthropic'){headers['x-api-key']=key;headers['anthropic-version']='2023-06-01';}else if(provider==='gemini')headers['x-goog-api-key']=key;else headers.Authorization=`Bearer ${key}`;
 async function call(path:string,body?:object){const r=await fetch(bases[provider]+path,{method:body?'POST':'GET',headers,body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(75000),redirect:'error'});const j=await r.json().catch(()=>{throw new Error(`Provider returned an unreadable response (${r.status}).`);}) as any;if(!r.ok){const message=String(j.error?.message||j.message||'Provider rejected the request').replaceAll(key,'[redacted]').slice(0,350);throw new Error(`${r.status}: ${message}`);}return j;}
 if(action==='models'){
  if(provider==='openrouter')await call('/key');
  const j=await call('/models'+(provider==='gemini'?'?pageSize=1000':provider==='anthropic'?'?limit=1000':''));
  const list=j.data||j.models||[];
  const models=list.map((m:any)=>{const id=(m.id||m.name||'').replace(/^models\//,'');const modalities=m.architecture?.input_modalities||m.input_modalities;const cap=m.capabilities?.image_input?.supported;const vision=Array.isArray(modalities)?(modalities.includes('image')?'yes':'no'):typeof cap==='boolean'?(cap?'yes':'no'):'unknown';return {id,name:m.display_name||m.displayName||m.name||id,vision};}).filter((m:any)=>m.id);
  return Response.json({models},{headers:{'Cache-Control':'no-store'}});
 }
 if(typeof model!=='string'||!model||model.length>200||typeof dataUrl!=='string'||!/^data:image\/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$/.test(dataUrl))return Response.json({error:'Select a model and provide an image.'},{status:400});
 const [meta,data]=dataUrl.split(',');const mime=meta.split(':')[1].split(';')[0];let content='';
 if(provider==='anthropic'){const j=await call('/messages',{model,max_tokens:1024,messages:[{role:'user',content:[{type:'image',source:{type:'base64',media_type:mime,data}},{type:'text',text:extractionPrompt}]}]});content=(j.content||[]).filter((c:any)=>c.type==='text').map((c:any)=>c.text).join('');}
 else if(provider==='gemini'){const j=await call(`/models/${encodeURIComponent(model)}:generateContent`,{contents:[{parts:[{text:extractionPrompt},{inline_data:{mime_type:mime,data}}]}],generationConfig:{responseMimeType:'application/json'}});content=(j.candidates?.[0]?.content?.parts||[]).map((p:any)=>p.text||'').join('');}
 else if(provider==='openai'){const j=await call('/responses',{model,input:[{role:'user',content:[{type:'input_text',text:extractionPrompt},{type:'input_image',image_url:dataUrl}]}]});content=(j.output||[]).flatMap((o:any)=>o.content||[]).filter((c:any)=>c.type==='output_text').map((c:any)=>c.text).join('');}
 else {const j=await call('/chat/completions',{model,messages:[{role:'user',content:[{type:'text',text:extractionPrompt},{type:'image_url',image_url:{url:dataUrl}}]}]});content=j.choices?.[0]?.message?.content||'';}
 return Response.json(parseColors(content),{headers:{'Cache-Control':'no-store'}});
 }catch(e){return Response.json({error:(e as Error).name==='TimeoutError'?'Provider timed out. Try again or use local extraction.':(e as Error).message},{status:502,headers:{'Cache-Control':'no-store'}});}
}
