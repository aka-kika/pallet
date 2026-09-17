import React from 'react';
import {createRoot} from 'react-dom/client';
import {PaletteApp} from '../../components/palette/app';
import {QuickCapture} from '../../components/palette/quick-capture';
import '../../app/globals.css';
createRoot(document.getElementById('root')!).render(location.pathname==='/capture'?<QuickCapture/>:<PaletteApp/>);
