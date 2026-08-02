import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";

export default defineConfig({
  plugins: [react()],
  define: { "process.env.NODE_ENV": JSON.stringify("production") },
  build: {
    outDir: "../../inst/htmlwidgets/lib",
    emptyOutDir: false,
    cssCodeSplit: false,
    lib: {
      entry: resolve(import.meta.dirname, "src/selection-system.jsx"),
      name: "ShinyCapabilitiesSelectionSystem",
      formats: ["iife"],
      fileName: () => "selection-system.js"
    },
    rollupOptions: {
      output: { assetFileNames: asset => asset.name?.endsWith(".css") ? "selection-system.css" : "[name][extname]" }
    }
  }
});
