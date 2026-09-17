export type Palette = { id: string; name: string; colors: string[]; main: number; favorite: boolean; source: string };
const definitions: [string, string[], number, string?][] = [
 ['Asphalt Lime',['#111111','#737373','#4F6F9F','#D7FF3F','#F8F8F5'],2],
 ['Dusty Evening',['#C98C96','#F4E9E2','#F0B49D','#6F5147','#7789A5'],0],
 ['Midnight Interface',['#101A33','#3F7CFF','#DDEBFF','#F8FBFF','#7C8794'],1],
 ['Vibrant Sunset',['#4D3A4D','#BE5CA9','#D59CC5','#EADADA'],1],
 ['Orchid Mint',['#7269E3','#272C39','#A783A6','#98DEA3'],0],
 ['Studio Blue',['#1E56C3','#ECDCF4','#F3ECDE','#272932'],0],
 ['Wallet Lime',['#D7F266','#151514','#D3DDDA','#F7F8F6'],0],
 ['Astro Orange',['#E46036','#F1EDE5','#000000','#FFFFFF'],0],
 ['Signal Orange',['#FC5723','#DFDFDF','#AAAAAA','#FFFFFF'],0],
 ['Apple Modern',['#F5F5F7','#1D1D1F','#AAAAAA','#007AFF'],3],
 ['Storm Cloud',['#101721','#434A54','#838694','#474958'],1],
 ['Slate & Citron',['#FFFFFF','#57677A','#E1E821'],1],
 ['Graphic Garden',['#59B9C7','#D2DEE3','#2B313F'],0],
 ['June & Cornflower',['#BADE4F','#6E8EEC','#282B26','#F0ECE5'],1],
 ['Periwinkle Study',['#101726','#6176AD','#9290CF','#92A2D8','#BBC2D7','#F4F4F4'],1,'Photo reference · estimated swatches; labels unreadable'],
 ['Ash & Jet Stream',['#B4B9BA','#BACCD0','#000000','#111111'],1],
 ['Carbon Electric',['#101317','#343A40','#AAB2BD','#F4F7FA','#3B82F6'],4],
 ['Graphite Sprout',['#23262C','#3A3F47','#D1D5DB','#FE7733','#B1FA63','#FFFFFF'],4],
 ['Developer Dusk',['#0F172A','#1E293B','#F1F5F9','#94A3B8','#818CF8','#4ADE80'],4],
 ['Willow & White',['#FFFFFF','#F4F3EF','#DFDED9','#B5B1AE','#B0BFCC','#9ABDE2','#3F3F3F'],5],
];
export const seeds: Palette[] = definitions.map(([name, colors, main, source], i) => ({id:`seed-${i+1}`, name, colors, main, favorite:false, source:source || (i<10?'Earlier theme collection':'Photo reference')}));
export const rgb = (h: string) => [1,3,5].map(i=>parseInt(h.slice(i,i+2),16));
export const hex = (c:number[]) => '#'+c.map(n=>Math.round(Math.max(0,Math.min(255,n))).toString(16).padStart(2,'0')).join('').toUpperCase();
export const mix = (a:string,b:string,t:number) => hex(rgb(a).map((n,i)=>n+(rgb(b)[i]-n)*t));
export const luminance = (h:string) => rgb(h).map(n=>{const s=n/255;return s<=.04045?s/12.92:((s+.055)/1.055)**2.4}).reduce((v,n,i)=>v+n*[.2126,.7152,.0722][i],0);
export const contrast = (a:string,b:string) => (Math.max(luminance(a),luminance(b))+.05)/(Math.min(luminance(a),luminance(b))+.05);
export const ink = (bg:string) => {const dark=contrast(bg,'#111318'),light=contrast(bg,'#FFFFFF');return Math.max(dark,light)<4.5?'#000000':dark>light?'#111318':'#FFFFFF';};
export function readable(color:string,bg:string,ratio=4.5) { const target=ink(bg); let c=color; for(let n=0;n<100&&contrast(c,bg)<ratio;n++) c=mix(c,target,.06); return c; }
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
 const text=readable(dark?'#F5F5F7':'#111318',bg,10);
 const muted=readable(mix(text,bg,.35),bg,4.6);
 return {...t,background:bg,surface,raised,text,muted,border:mix(bg,text,.16),'highlight-ink':readable(t.highlight,bg),link:readable(t.accent,bg),focus:readable(t.highlight,bg,3)};
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
 const base=dark?mix(mix(sorted[0],'#16181D',.55),main,.10):mix(mix(sorted.at(-1)!,'#F8FAFC',.8),main,.08);
 const bg=dark?(luminance(base)>.07?mix(base,'#15171B',.65):base):base;
 const surface=mix(mix(bg,'#FFFFFF',dark?.045:.45),companionWash,.025);
 const raised=mix(mix(bg,dark?'#FFFFFF':main,dark?.085:.09),companionWash,.04);
 const text=readable(dark?'#F5F5F7':sorted[0],bg,10);
 const muted=readable(mix(text,bg,.35),bg,4.6);
 const accent=main;
 return {background:bg, surface, raised, text, muted, border:mix(bg,text,.16), accent, 'on-accent':ink(accent), 'accent-hover':mix(accent,ink(accent),.08), highlight, 'on-highlight':ink(highlight), 'highlight-ink':readable(highlight,bg), 'highlight-hover':mix(highlight,ink(highlight),.06), link:readable(main,bg), focus:readable(highlight,bg,3), selection:mix(bg,highlight,dark?.30:.20), 'on-selection':readable(text,mix(bg,highlight,dark?.30:.20)), success:readable(dark?'#86C89D':'#367749',bg), warning:readable(dark?'#EAC16B':'#8D641D',bg), danger:readable(dark?'#F58A93':'#B03448',bg)};
}
export function css(p:Palette) {const block=(dark:boolean)=>Object.entries(theme(p,dark)).map(([k,v])=>`  --${k}: ${v};`).join('\n');return `/* ${p.name.replaceAll('*/','')} · primary ${p.colors[p.main]} */\n:root, [data-theme="light"] {\n  color-scheme: light;\n${block(false)}\n}\n\n@media (prefers-color-scheme: dark) {\n  :root:not([data-theme="light"]) {\n    color-scheme: dark;\n${block(true)}\n  }\n}\n\n[data-theme="dark"] {\n  color-scheme: dark;\n${block(true)}\n}\n`;}
export function markdown(p:Palette) {const l=theme(p,false),d=theme(p,true);return `# ${p.name}\n\nSource: ${p.source}\n\nOriginal palette: ${p.colors.join(', ')}\n\nMain color: ${p.colors[p.main]}\n\n## Light and soft dark\n\nUI shades are derived from the original palette. Text pairs are contrast-adjusted.\n\n| Role | Light | Dark |\n| --- | --- | --- |\n${Object.keys(l).map(k=>`| ${k} | ${l[k as keyof typeof l]} | ${d[k as keyof typeof d]} |`).join('\n')}\n\n## CSS\n\n\`\`\`css\n${css(p)}\`\`\`\n`;}
export function validPalette(p:unknown):p is Palette {if(!p||typeof p!=='object')return false;const v=p as Palette;return typeof v.id==='string'&&/^[\w-]{1,80}$/.test(v.id)&&typeof v.name==='string'&&v.name.trim().length>0&&v.name.length<=100&&Array.isArray(v.colors)&&v.colors.length>=2&&v.colors.length<=10&&v.colors.every(c=>/^#[\da-f]{6}$/i.test(c))&&Number.isInteger(v.main)&&v.main>=0&&v.main<v.colors.length&&typeof v.favorite==='boolean'&&typeof v.source==='string'&&v.source.length<300;}
