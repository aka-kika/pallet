import vinext from "vinext";
import { defineConfig } from "vite";

// The web version. The Mac app is the SwiftUI project in swiftui/.
export default defineConfig({
  plugins: [vinext()],
});
