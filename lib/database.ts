import {env} from 'cloudflare:workers';
export function database(){if(!env.DB)throw new Error('Collection storage unavailable');return env.DB;}
export {sameOrigin} from './origin';
