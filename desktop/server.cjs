const http=require('node:http');
const fs=require('node:fs');
const path=require('node:path');
const {timingSafeEqual}=require('node:crypto');
const {createStore}=require('./store.cjs');
async function startServer({directory,ui,service,token,port=45487,onChange=()=>{}}){
 const store=createStore(directory,service.seeds);
 const matches=value=>typeof value==='string'&&Buffer.byteLength(value)===Buffer.byteLength(token)&&timingSafeEqual(Buffer.from(value),Buffer.from(token));
 const server=http.createServer(async(req,res)=>{
  const origin=`http://127.0.0.1:${server.address().port}`;
  const json=(status,data)=>{res.writeHead(status,{'Content-Type':'application/json','Cache-Control':'no-store'});res.end(JSON.stringify(data));};
  if(req.headers.host!==new URL(origin).host||req.headers.origin&&req.headers.origin!==origin)return json(403,{error:'Origin rejected'});
  const url=new URL(req.url,origin);
  try{
   if(url.pathname.startsWith('/api/')){
    if(!matches(req.headers['x-palette-session']))return json(403,{error:'Session required'});
    if(req.method==='GET'&&url.pathname==='/api/palettes')return json(200,store.all());
    if(req.method==='DELETE'&&url.pathname==='/api/palettes'){const id=url.searchParams.get('id')||'';if(!/^[\w-]{1,80}$/.test(id))return json(400,{error:'Invalid palette'});store.remove(id);onChange();return json(200,{ok:true});}
    if(!['PUT','POST'].includes(req.method))return json(405,{error:'Method not allowed'});
    const chunks=[];let length=0;for await(const chunk of req){length+=chunk.length;if(length>16*1024*1024)return json(413,{error:'Request too large'});chunks.push(chunk);}
    const body=Buffer.concat(chunks).toString('utf8');
    if(url.pathname==='/api/palettes'&&req.method==='PUT'){let p;try{p=JSON.parse(body);}catch{return json(400,{error:'Invalid JSON'});}if(!service.validPalette(p))return json(400,{error:'Invalid palette'});store.put(p);onChange();return json(200,{ok:true});}
    if(url.pathname==='/api/provider'&&req.method==='POST'){const response=await service.providerRequest(new Request(url,{method:'POST',headers:{'Content-Type':'application/json','Origin':origin},body}));res.writeHead(response.status,{'Content-Type':'application/json','Cache-Control':'no-store'});return res.end(await response.text());}
    return json(404,{error:'Unknown endpoint'});
   }
   if(req.method!=='GET')return json(405,{error:'Method not allowed'});
   const candidate=path.resolve(ui,'.'+decodeURIComponent(url.pathname));
   if(candidate!==ui&&!candidate.startsWith(ui+path.sep))return json(403,{error:'Invalid path'});
   const file=fs.existsSync(candidate)&&fs.statSync(candidate).isFile()?candidate:path.join(ui,'index.html');
   const types={'.html':'text/html','.js':'text/javascript','.css':'text/css','.svg':'image/svg+xml','.png':'image/png','.woff2':'font/woff2'};
   res.writeHead(200,{'Content-Type':types[path.extname(file)]||'application/octet-stream','X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; connect-src 'self' http://localhost:11434 http://127.0.0.1:11434; font-src 'self' data:; object-src 'none'; frame-ancestors 'none'; base-uri 'none'"});fs.createReadStream(file).pipe(res);
  }catch(error){console.error('Palette request failed:',error.message);if(!res.headersSent)json(500,{error:'Could not complete the request'});else res.end();}
 });
 await new Promise((resolve,reject)=>{server.once('error',reject);server.listen(port,'127.0.0.1',resolve);});
 return {server,origin:`http://127.0.0.1:${server.address().port}`};
}
module.exports={startServer};
