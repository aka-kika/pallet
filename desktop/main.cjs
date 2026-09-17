const {app,BrowserWindow,Tray,Menu,globalShortcut,ipcMain,clipboard,nativeImage,session,dialog,screen}=require('electron');
const fs=require('node:fs');const path=require('node:path');const {pathToFileURL}=require('node:url');const {randomBytes}=require('node:crypto');
const {startServer}=require('./server.cjs');
app.setName('Pallet');
app.setPath('userData', path.join(app.getPath('appData'), 'Palette'));
let main,capture,tray,origin,server,quitting=false,ready=false,pendingImage=null;
const captureSizes={mini:{w:240,h:156},miny:{w:300,h:196},mo:{w:360,h:240}};
let prefs={autoCopyCSS:false,shortcut:'CommandOrControl+Shift+P',shortcutRegistered:false,captureSize:'mo'};
function captureBox(){return captureSizes[prefs.captureSize]||captureSizes.mo;}
const windows=()=>[main,capture].filter(w=>w&&!w.isDestroyed());
function showMain(){main.show();main.focus();app.dock?.show();}
function layoutCapture(){
 const {w,h}=captureBox();
 if(!capture||capture.isDestroyed())return;
 capture.setSize(w,h);
 const b=tray.getBounds();
 const point=b.width>0&&b.height>0?{x:b.x+b.width/2,y:b.y+b.height/2}:screen.getCursorScreenPoint();
 const area=screen.getDisplayNearestPoint(point).workArea;
 const x=Math.max(area.x,Math.min((b.width>0?b.x-Math.round(w/2)+Math.round(b.width/2):point.x-Math.round(w/2)),area.x+area.width-w));
 const y=Math.max(area.y,Math.min(area.y+6,area.y+area.height-h-10));
 capture.setPosition(Math.round(x),Math.round(y));
}
function showCapture(){
 layoutCapture();
 app.focus({steal:true});
 capture.show();
 capture.focus();
}
function toggleCapture(){
 if(!capture||capture.isDestroyed())return;
 if(capture.isVisible()){if(ready)capture.webContents.send('palette:dismiss-capture');else capture.hide();return;}
 showCapture();
}
function assertSender(event){if(!windows().some(w=>w.webContents===event.sender)||event.senderFrame!==event.sender.mainFrame||new URL(event.senderFrame.url).origin!==origin)throw new Error('Untrusted caller');}
function savePrefs(next){fs.writeFileSync(path.join(app.getPath('userData'),'capture-settings.json'),JSON.stringify({autoCopyCSS:next.autoCopyCSS,shortcut:next.shortcut,captureSize:next.captureSize}),{mode:0o600});}
function registerShortcut(shortcut){if(typeof shortcut!=='string'||shortcut.length>100||!/(Command|Control|Cmd|Ctrl)/i.test(shortcut)||!shortcut.includes('+'))throw new Error('Use a shortcut with Command or Control and a key.');let success=false;try{success=globalShortcut.unregister(shortcut);success=globalShortcut.register(shortcut,showCapture);}catch{}return success;}
async function clipboardImage(){
 const items=await clipboard.read();
 const prefer=['image/png','image/jpeg','image/webp','image/gif','image/avif'];
 for(const item of items){
  const type=prefer.find(t=>item.types.includes(t))||item.types.find(t=>t.startsWith('image/')&&t!=='image/svg+xml');
  if(!type)continue;
  const blob=await item.getType(type);
  if(!blob||typeof blob.arrayBuffer!=='function')continue;
  const buffer=Buffer.from(await blob.arrayBuffer());
  if(!buffer.length)continue;
  const image=nativeImage.createFromBuffer(buffer);
  if(image.isEmpty()){
   if(buffer.length>20*1024*1024)throw new Error('Choose an image smaller than 20 MB.');
   return {name:'image.png',dataUrl:`data:${type};base64,${buffer.toString('base64')}`};
  }
  const size=image.getSize();
  if(size.width*size.height>40000000)throw new Error('Clipboard image is too large. Use a smaller image.');
  return {name:'image.png',dataUrl:image.toDataURL()};
 }
 return null;
}
function makeWindow(options){const w=new BrowserWindow({...options,webPreferences:{preload:path.join(__dirname,'preload.cjs'),contextIsolation:true,sandbox:true,nodeIntegration:false}});w.webContents.setWindowOpenHandler(()=>({action:'deny'}));w.webContents.on('will-navigate',(event,url)=>{if(new URL(url).origin!==origin)event.preventDefault();});w.webContents.on('will-attach-webview',event=>event.preventDefault());return w;}
async function start(){
 const directory=app.getPath('userData');fs.mkdirSync(directory,{recursive:true});
 const preferences=path.join(directory,'capture-settings.json');if(fs.existsSync(preferences)){try{const p=JSON.parse(fs.readFileSync(preferences,'utf8'));if(typeof p.autoCopyCSS==='boolean')prefs.autoCopyCSS=p.autoCopyCSS;if(typeof p.shortcut==='string')prefs.shortcut=p.shortcut;if(p.captureSize==='mini'||p.captureSize==='miny'||p.captureSize==='mo')prefs.captureSize=p.captureSize;}catch{}}
 const service=await import(pathToFileURL(path.join(__dirname,'build/service/service.mjs')).href);
 const token=randomBytes(32).toString('hex');
 ({server,origin}=await startServer({directory,ui:path.join(__dirname,'build/ui'),service,token,onChange:()=>windows().forEach(w=>w.webContents.send('palette:collection-changed'))}));
 session.defaultSession.webRequest.onBeforeSendHeaders({urls:[origin+'/*']},(details,callback)=>{details.requestHeaders['X-Palette-Session']=token;callback({requestHeaders:details.requestHeaders});});
 session.defaultSession.setPermissionRequestHandler((_wc,_permission,callback)=>callback(false));
 main=makeWindow({width:1160,height:840,minWidth:360,minHeight:560,title:'Pallet',show:false,titleBarStyle:'hidden',backgroundColor:'#16181e'});
 main.setWindowButtonVisibility(false);
 capture=makeWindow({width:captureBox().w,height:captureBox().h,resizable:false,alwaysOnTop:true,skipTaskbar:true,frame:false,title:'',show:false,autoHideMenuBar:true});
 main.on('close',event=>{if(!quitting){event.preventDefault();main.hide();app.dock?.hide();}});capture.on('close',event=>{if(!quitting){event.preventDefault();capture.hide();}});
 const image=nativeImage.createFromPath(path.join(__dirname,'trayTemplate.png'));image.setTemplateImage(true);tray=new Tray(image);tray.setToolTip('Pallet — drop an image');tray.on('click',toggleCapture);
 const menu=Menu.buildFromTemplate([{label:'Open Collection',click:showMain},{label:'Settings…',click:()=>{showMain();main.webContents.send('palette:open-settings');}},{type:'separator'},{label:'Quit Pallet',click:()=>app.quit()}]);tray.on('right-click',()=>tray.popUpContextMenu(menu));
 tray.on('drop-files',async(_event,files)=>{showCapture();const file=files[0];try{if(!file||!fs.statSync(file).isFile()||fs.statSync(file).size>20*1024*1024)throw new Error('Choose an image smaller than 20 MB.');const ext=path.extname(file).toLowerCase();const mime={'.png':'image/png','.jpg':'image/jpeg','.jpeg':'image/jpeg','.webp':'image/webp','.gif':'image/gif','.avif':'image/avif'}[ext];if(!mime)throw new Error('Use PNG, JPG, WebP, GIF, or AVIF.');const data={name:path.basename(file),dataUrl:`data:${mime};base64,${fs.readFileSync(file).toString('base64')}`};if(ready)capture.webContents.send('palette:image',data);else pendingImage=data;}catch(e){dialog.showErrorBox('Could not capture image',e.message);}});
 const handle=(name,fn)=>ipcMain.handle('palette:'+name,(event,...args)=>{assertSender(event);return fn(...args);});
 handle('preferences',()=>prefs);
 handle('set-preferences',value=>{if(!value||typeof value.autoCopyCSS!=='boolean')throw new Error('Invalid preferences');let registered=prefs.shortcutRegistered;if(value.shortcut!==prefs.shortcut||!registered){registered=registerShortcut(value.shortcut);if(!registered)throw new Error('Shortcut unavailable. Your previous shortcut is still active.');if(prefs.shortcutRegistered)globalShortcut.unregister(prefs.shortcut);}const captureSize=value.captureSize==='mini'||value.captureSize==='miny'||value.captureSize==='mo'?value.captureSize:prefs.captureSize||'mo';const next={autoCopyCSS:value.autoCopyCSS,shortcut:value.shortcut,shortcutRegistered:registered,captureSize};savePrefs(next);prefs=next;layoutCapture();return prefs;});
 handle('clipboard-image',clipboardImage);
 handle('copy-css',async text=>{if(typeof text!=='string'||text.length>100000)throw new Error('Invalid CSS');await clipboard.writeText(text);});
 handle('open-collection',()=>{capture.hide();showMain();});
 handle('open-settings',()=>{capture.hide();showMain();main.webContents.send('palette:open-settings');});
 handle('hide-capture',()=>capture.hide());
 handle('hide-main',()=>{if(main&&!main.isDestroyed()){main.hide();app.dock?.hide();}});
 handle('suggest-name',async colors=>{if(!Array.isArray(colors)||!colors.length)return null;const helper=[path.join(process.resourcesPath||'', 'suggest-name'),path.join(__dirname,'suggest-name')].find(p=>p&&fs.existsSync(p));if(!helper)return null;try{const {execFile}=require('node:child_process');const {promisify}=require('node:util');const {stdout}=await promisify(execFile)(helper,colors.filter(c=>typeof c==='string').slice(0,6),{timeout:8000});const name=String(stdout||'').trim();return name.length>1&&name.length<=100?name:null;}catch{return null;}});
 ipcMain.on('palette:ready',event=>{assertSender(event);if(event.sender===capture.webContents){ready=true;if(pendingImage){capture.webContents.send('palette:image',pendingImage);pendingImage=null;}}});
 Menu.setApplicationMenu(Menu.buildFromTemplate([{label:'Pallet',submenu:[{role:'about'},{type:'separator'},{label:'Quick Capture',click:showCapture},{role:'hide'},{role:'quit'}]},{label:'Edit',submenu:[{role:'undo'},{role:'redo'},{type:'separator'},{role:'cut'},{role:'copy'},{role:'paste'},{role:'selectAll'}]},{label:'Window',submenu:[{role:'minimize'},{label:'Open Collection',click:showMain}]}]));
 prefs.shortcutRegistered=registerShortcut(prefs.shortcut);
 await Promise.all([main.loadURL(origin),capture.loadURL(origin+'/capture')]);showMain();
}
if(!app.requestSingleInstanceLock())app.quit();else{app.on('second-instance',()=>main&&showMain());app.whenReady().then(start).catch(e=>{dialog.showErrorBox('Pallet could not start',e.code==='EADDRINUSE'?'Local port 45487 is in use. Quit the other Pallet instance or free this port and reopen.':e.message);app.quit();});}
app.on('activate',()=>main&&showMain());app.on('window-all-closed',()=>{});app.on('before-quit',()=>{quitting=true;globalShortcut.unregisterAll();server?.close();});
