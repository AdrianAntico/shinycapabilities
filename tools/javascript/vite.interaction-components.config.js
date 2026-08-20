import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { copyFileSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";

const publishInteractionSources = {
  name: "publish-interaction-component-sources",
  closeBundle() {
    const target = resolve(import.meta.dirname, "../../inst/htmlwidgets/src");
    mkdirSync(target, { recursive: true });
    copyFileSync(resolve(import.meta.dirname, "src/interaction-components.jsx"),
      resolve(target, "interaction-components.jsx"));
    copyFileSync(resolve(import.meta.dirname, "src/interaction-components.css"),
      resolve(target, "interaction-components.css"));
  }
};

export default defineConfig({
  plugins: [react(), publishInteractionSources],
  define: { "process.env.NODE_ENV": JSON.stringify("production") },
  build: {
    outDir: "../../inst/htmlwidgets/lib",
    emptyOutDir: false,
    cssCodeSplit: false,
    lib: {
      entry: resolve(import.meta.dirname, "src/interaction-components.jsx"),
      name: "ShinyCapabilitiesInteractionComponents",
      formats: ["iife"],
      fileName: () => "interaction-components.js"
    },
    rollupOptions: {
      output: { assetFileNames: asset => asset.name?.endsWith(".css") ? "interaction-components.css" : "[name][extname]" }
    }
  }
});
