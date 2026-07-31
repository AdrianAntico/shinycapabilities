import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";

export default defineConfig({
  plugins: [react()],
  define: {
    "process.env.NODE_ENV": JSON.stringify("production")
  },
  build: {
    outDir: "../../inst/htmlwidgets/lib",
    emptyOutDir: true,
    cssCodeSplit: false,
    lib: {
      entry: resolve(import.meta.dirname, "src/widget.jsx"),
      name: "ShinyCapabilities",
      formats: ["iife"],
      fileName: () => "shinycapabilities.js"
    },
    rollupOptions: {
      output: {
        assetFileNames: (asset) =>
          asset.name?.endsWith(".css") ? "shinycapabilities.css" : "[name][extname]"
      }
    }
  }
});
