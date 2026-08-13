import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { copyFileSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";

const publishSelectionSource = {
  name: "publish-selection-source-contract",
  closeBundle() {
    const target = resolve(import.meta.dirname, "../../inst/htmlwidgets/src");
    mkdirSync(target, { recursive: true });
    copyFileSync(
      resolve(import.meta.dirname, "src/selection-system.jsx"),
      resolve(target, "selection-system.jsx")
    );
    copyFileSync(
      resolve(import.meta.dirname, "src/selection-system.css"),
      resolve(target, "selection-system.css")
    );
  }
};

export default defineConfig({
  plugins: [react(), publishSelectionSource],
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
