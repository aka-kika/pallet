import {webStore,sameOrigin} from '@/lib/database';
import {seeds,validPalette} from '@/lib/palettes';
export async function GET(){const saved=webStore.list();const ids=new Set(saved.map(p=>p.id));return Response.json([...seeds.filter(p=>!ids.has(p.id)),...saved],{headers:{'Cache-Control':'no-store'}});}
export async function PUT(req:Request){if(!sameOrigin(req))return new Response('Forbidden',{status:403});try{const p=await req.json();if(!validPalette(p))return Response.json({error:'Invalid palette'},{status:400});webStore.put(p);return Response.json({saved:true});}catch{return Response.json({error:'Invalid JSON'},{status:400});}}
export async function DELETE(req:Request){if(!sameOrigin(req))return new Response('Forbidden',{status:403});const id=new URL(req.url).searchParams.get('id')||'';if(!/^[\w-]{1,80}$/.test(id))return Response.json({error:'Invalid palette'},{status:400});webStore.remove(id);return Response.json({ok:true});}
