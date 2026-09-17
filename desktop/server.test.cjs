const {test}=require('node:test');const assert=require('node:assert/strict');const fs=require('node:fs');const os=require('node:os');const path=require('node:path');const {startServer}=require('./server.cjs');
test('desktop collection persists, rejects invalid input and requires its session',async()=>{
 const directory=fs.mkdtempSync(path.join(os.tmpdir(),'palette-test-'));const service=await import('./build/service/service.mjs');let changes=0;
 const options={directory,ui:path.join(__dirname,'build/ui'),service,token:'test-session',port:0,onChange:()=>changes++};
 let instance=await startServer(options);
 try{
  const request=(route,init={})=>fetch(instance.origin+route,{...init,headers:{'X-Palette-Session':'test-session',...init.headers}});
  assert.equal((await fetch(instance.origin+'/api/palettes')).status,403);
  assert.equal((await request('/api/palettes',{headers:{Origin:'https://untrusted.example'}})).status,403);
  assert.equal((await (await request('/api/palettes')).json()).length,20);
  assert.equal((await request('/api/palettes',{method:'PUT',body:'{}'})).status,400);
  const palette={...service.seeds[0],id:'test-import',name:'Saved capture'};
  assert.equal((await request('/api/palettes',{method:'PUT',body:JSON.stringify(palette)})).status,200);assert.equal(changes,1);
  assert.equal((await (await request('/api/palettes')).json()).length,21);
  await new Promise(r=>instance.server.close(r));instance=await startServer(options);
  assert.equal((await (await request('/api/palettes')).json()).find(p=>p.id==='test-import').name,'Saved capture');
  assert.equal((await request('/capture')).status,200);
 }finally{await new Promise(r=>instance.server.close(r));fs.rmSync(directory,{recursive:true,force:true});}
});
