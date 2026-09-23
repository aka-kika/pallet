import vinext from "vinext";
import { defineConfig } from "vite";

// Web preview of the shared UI. The Mac app has its own build (desktop/build.mjs).
export default defineConfig({
  plugins: [vinext()],
});
