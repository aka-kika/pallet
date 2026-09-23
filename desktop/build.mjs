import {build} from 'vite';
import react from '@vitejs/plugin-react';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import fs from 'node:fs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const alias={'@':root};
const ui=path.join(root,'desktop/build/ui');
await build({configFile:false,root:path.join(root,'desktop/renderer'),resolve:{alias},plugins:[react()],css:{postcss:root},build:{outDir:ui,emptyOutDir:true}});
for(const file of ['palett-mark.png','favicon.png','app-icon.png']){
 const src=path.join(root,'public',file);
 if(fs.existsSync(src))fs.copyFileSync(src,path.join(ui,file));
}
await build({configFile:false,root,resolve:{alias},build:{ssr:path.join(root,'desktop/service.ts'),outDir:path.join(root,'desktop/build/service'),emptyOutDir:true,rollupOptions:{output:{entryFileNames:'service.mjs'}}}});
