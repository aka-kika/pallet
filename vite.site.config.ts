import path from "node:path";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

// Static build of the web app for akakika.com/pallet (see scripts/build-site.mjs).
export default defineConfig({
  root: "site",
  base: "/pallet/",
  publicDir: path.resolve(__dirname, "public"),
  plugins: [react()],
  resolve: { alias: { "@": path.resolve(__dirname) } },
  build: { outDir: path.resolve(__dirname, "dist-site"), emptyOutDir: true },
});
