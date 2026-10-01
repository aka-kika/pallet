// The public page at akakika.com/pallet: the real Pallet web app, built as
// static files (scripts/build-site.mjs). Kika's palettes come from
// collection.json next to the page; a visitor's own stay in their browser.
import {createRoot} from 'react-dom/client';
import '../app/globals.css';
import {PaletteApp} from '../components/palette/app';
import {siteSource} from '../lib/collection';

const source=siteSource(new URL('collection.json',document.baseURI).href);
createRoot(document.getElementById('root')!).render(
 <PaletteApp source={source} downloadUrl="https://github.com/aka-kika/pallet/releases/latest/download/Pallet.zip"/>,
);
