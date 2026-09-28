import builtins from '../shared/builtin-palettes.json' with {type:'json'};
export type Palette = { id: string; name: string; colors: string[]; main: number; favorite: boolean; source: string };
// Built-in palettes live in one JSON file shared with the SwiftUI app.
export const seeds: Palette[] = builtins;
export const rgb = (h: string) => [1,3,5].map(i=>parseInt(h.slice(i,i+2),16));
export const hex = (c:number[]) => '#'+c.map(n=>Math.round(Math.max(0,Math.min(255,n))).toString(16).padStart(2,'0')).join('').toUpperCase();
export const mix = (a:string,b:string,t:number) => hex(rgb(a).map((n,i)=>n+(rgb(b)[i]-n)*t));
export const luminance = (h:string) => rgb(h).map(n=>{const s=n/255;return s<=.04045?s/12.92:((s+.055)/1.055)**2.4}).reduce((v,n,i)=>v+n*[.2126,.7152,.0722][i],0);
export const contrast = (a:string,b:string) => (Math.max(luminance(a),luminance(b))+.05)/(Math.min(luminance(a),luminance(b))+.05);
export const ink = (bg:string) => {const dark=contrast(bg,'#111318'),light=contrast(bg,'#FFFFFF');return Math.max(dark,light)<4.5?'#000000':dark>light?'#111318':'#FFFFFF';};
export function readable(color:string,bg:string,ratio=4.5) { const target=ink(bg); let c=color; for(let n=0;n<100&&contrast(c,bg)<ratio;n++) c=mix(c,target,.06); return c; }
// Push a foreground color until it reaches `ratio` on every background it can
// sit on. Returns the color unchanged when it already passes, so palettes that
// read well keep their exact look.
function legible(color:string,bgs:string[],ratio=4.5) { let c=color; for(let n=0;n<10;n++){ const bad=bgs.find(bg=>contrast(c,bg)<ratio); if(!bad) return c; const next=readable(c,bad,ratio); if(next===c) break; c=next; }
 // Still short: fall back to whichever of black or white reads best.
 const worst=(x:string)=>Math.min(...bgs.map(bg=>contrast(x,bg)));
 return [c,'#000000','#FFFFFF'].reduce((a,b)=>worst(b)>worst(a)?b:a); }
export function parseHex(s:string){
 const t=s.trim();
 if(/^#?[0-9a-f]{6}$/i.test(t))return('#'+t.replace('#','')).toUpperCase();
 if(/^#?[0-9a-f]{3}$/i.test(t)){const h=t.replace('#','');return('#'+h[0]+h[0]+h[1]+h[1]+h[2]+h[2]).toUpperCase();}
 return null;
}
export function withLockedBackground<T extends ReturnType<typeof theme>>(t:T,lock:string|null,dark:boolean):T{
 if(!lock)return t;
 const bg=lock;
 const surface=mix(mix(bg,'#FFFFFF',dark?.045:.45),t.highlight,.025);
 const raised=mix(mix(bg,dark?'#FFFFFF':t.accent,dark?.085:.09),t.highlight,.04);
 return {...t,...roles(bg,surface,raised,dark?'#F5F5F7':'#111318',t.accent,t.highlight,dark)};
}
// Every role that sits on the page surfaces. The main color (accent) tints the
// washes, hover, borders and icons; the companion (highlight) marks "on" states.
// Each foreground is pushed until it reads on every surface, see docs/THEME-RULES.md.
function roles(bg:string,surface:string,raised:string,ink0:string,accent:string,highlight:string,dark:boolean){
 // Washes take the accent's hue but stay close to the background in lightness,
 // so one text color can still read on all of them.
 const tint=(t:number,limit:number)=>{let c=mix(bg,accent,t);for(let n=0;n<20&&contrast(c,bg)>limit;n++){t*=.85;c=mix(bg,accent,t);}return c;};
 const wash=tint(dark?.22:.16,1.25),hover=tint(dark?.32:.26,1.45);
 const surfaces=[bg,surface,raised,wash,hover];
 const text=legible(readable(ink0,bg,10),surfaces);
 const muted=legible(readable(mix(text,bg,.35),bg,4.6),surfaces);
 const soft=legible(mix(bg,text,.68),surfaces),dim=legible(mix(bg,text,.46),surfaces),uidim=legible(mix(bg,text,.46),surfaces,3);
 const link=legible(readable(accent,bg),surfaces);
 const selection=mix(bg,highlight,dark?.30:.20);
 return {background:bg,surface,raised,wash,hover,text,muted,border:mix(bg,mix(text,accent,.45),.18),'text-soft':soft,'text-dim':dim,'ui-dim':uidim,icon:legible(mix(uidim,link,.55),surfaces,3),'highlight-ink':legible(readable(highlight,bg),surfaces),link,focus:legible(readable(highlight,bg,3),surfaces,3),selection,'on-selection':legible(readable(text,selection),[selection]),success:legible(readable(dark?'#86C89D':'#367749',bg),surfaces),warning:legible(readable(dark?'#EAC16B':'#8D641D',bg),surfaces),danger:legible(readable(dark?'#F58A93':'#B03448',bg),surfaces)};
}
export function theme(p:Palette, dark:boolean) {
 const main=p.colors[p.main]||p.colors[0];
 // Keep the selected color as the foundation and give a distinct companion
 // the small, high-visibility actions. Neutral palettes remain neutral.
 const chroma=(c:string)=>{const channels=rgb(c);return (Math.max(...channels)-Math.min(...channels))/255;};
 const companions=p.colors.filter((_,i)=>i!==p.main).sort((a,b)=>{
  const score=(c:string)=>chroma(c)*2+Math.sqrt(rgb(c).reduce((s,n,i)=>s+(n-rgb(main)[i])**2,0))/442;
  return score(b)-score(a);
 });
 const highlight=companions[0]||main;
 const companionWash=hex(p.colors.reduce((sum,c)=>sum.map((n,i)=>n+rgb(c)[i]/p.colors.length),[0,0,0]));
 const sorted=[...p.colors].sort((a,b)=>luminance(a)-luminance(b));
 // Muted mains tint the page more, loud ones less, so neon stays calm.
 const tint=(dark?.18:.14)*(1-.5*chroma(main));
 const base=dark?mix(mix(sorted[0],'#16181D',.55),main,tint):mix(mix(sorted.at(-1)!,'#F8FAFC',.8),main,tint);
 let bg=dark?(luminance(base)>.07?mix(base,'#15171B',.65):base):base;
 // Light mode stays light even when every palette color is dark.
 for(let n=0;n<20&&!dark&&luminance(bg)<.72;n++)bg=mix(bg,'#F8FAFC',.2);
 // The page is a quiet backdrop: cap how colorful it can get.
 for(let n=0;n<20&&chroma(bg)>.07;n++){const g=rgb(bg).reduce((a,b)=>a+b)/3;bg=mix(bg,hex([g,g,g]),.15);}
 const surface=mix(mix(bg,'#FFFFFF',dark?.045:.45),companionWash,.025);
 const raised=mix(mix(bg,dark?'#FFFFFF':main,dark?.085:.09),companionWash,.04);
 const accent=main;
 const r=roles(bg,surface,raised,dark?'#F5F5F7':sorted[0],accent,highlight,dark);
 return {...r, accent, 'on-accent':legible(ink(accent),[accent]), 'accent-hover':mix(accent,ink(accent),.08), highlight, 'on-highlight':legible(ink(highlight),[highlight]), 'highlight-hover':mix(highlight,ink(highlight),.06)};
}
export function css(p:Palette) {const block=(dark:boolean)=>Object.entries(theme(p,dark)).map(([k,v])=>`  --${k}: ${v};`).join('\n');return `/* ${p.name.replaceAll('*/','')} · primary ${p.colors[p.main]} */\n:root, [data-theme="light"] {\n  color-scheme: light;\n${block(false)}\n}\n\n@media (prefers-color-scheme: dark) {\n  :root:not([data-theme="light"]) {\n    color-scheme: dark;\n${block(true)}\n  }\n}\n\n[data-theme="dark"] {\n  color-scheme: dark;\n${block(true)}\n}\n`;}
export function markdown(p:Palette) {const l=theme(p,false),d=theme(p,true);return `# ${p.name}\n\nSource: ${p.source}\n\nOriginal palette: ${p.colors.join(', ')}\n\nMain color: ${p.colors[p.main]}\n\n## Light and soft dark\n\nUI shades are derived from the original palette. Text pairs are contrast-adjusted.\n\n| Role | Light | Dark |\n| --- | --- | --- |\n${Object.keys(l).map(k=>`| ${k} | ${l[k as keyof typeof l]} | ${d[k as keyof typeof d]} |`).join('\n')}\n\n## CSS\n\n\`\`\`css\n${css(p)}\`\`\`\n`;}
export function validPalette(p:unknown):p is Palette {if(!p||typeof p!=='object')return false;const v=p as Palette;return typeof v.id==='string'&&/^[\w-]{1,80}$/.test(v.id)&&typeof v.name==='string'&&v.name.trim().length>0&&v.name.length<=100&&Array.isArray(v.colors)&&v.colors.length>=2&&v.colors.length<=10&&v.colors.every(c=>/^#[\da-f]{6}$/i.test(c))&&Number.isInteger(v.main)&&v.main>=0&&v.main<v.colors.length&&typeof v.favorite==='boolean'&&typeof v.source==='string'&&v.source.length<300;}
