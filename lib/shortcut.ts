const reserved=/^(CommandOrControl|Command|Control)\+(Q|W|Tab|Space)$/i;

export function displayShortcut(accelerator:string){
 return accelerator.replace(/CommandOrControl|Command|Cmd/gi,'⌘').replace(/Control|Ctrl/gi,'⌃').replace(/Option|Alt/gi,'⌥').replace(/Shift/gi,'⇧').replace(/Plus/gi,'+').replace(/\+/g,'');
}

export function eventToAccelerator(e:KeyboardEvent){
 if(['Meta','Control','Alt','Shift','Dead'].includes(e.key))return null;
 if(!(e.metaKey||e.ctrlKey))return null;
 const mods=['CommandOrControl'];
 if(e.altKey)mods.push('Alt');
 if(e.shiftKey)mods.push('Shift');
 const special:Record<string,string>={Escape:'Esc',ArrowUp:'Up',ArrowDown:'Down',ArrowLeft:'Left',ArrowRight:'Right',' ':'Space','+':'Plus','=':'Plus','-':'-'};
 const key=special[e.key]||(e.key.length===1?e.key.toUpperCase():e.key);
 if(key==='Esc')return null;
 const accelerator=mods.concat(key).join('+');
 if(reserved.test(accelerator))return null;
 return accelerator;
}
