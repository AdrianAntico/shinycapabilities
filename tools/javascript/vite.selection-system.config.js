import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { copyFileSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";

const publishSelectionSource = {
  name: "publish-selection-source-contract",
  closeBundle() {
    const target = resolve(import.meta.dirname, "../../inst/www/direct-transport/src");
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
    outDir: "../../inst/www/direct-transport",
    emptyOutDir: false,
    cssCodeSplit: false,
    lib: {
      entry: resolve(import.meta.dirname, "src/selection-system.jsx"),
      name: "ShinyCapabilitiesSelectionSystem",
      formats: ["iife"],
      fileName: () => "selection-system.js"
    },
    rollupOptions: {
      external: ["react", "react-dom", "react-dom/client", "@tanstack/react-virtual"],
      output: { globals: { react: "ShinyCapabilitiesBrowserRuntimeV1.React",
          "react-dom": "ShinyCapabilitiesBrowserRuntimeV1.ReactDOM",
          "react-dom/client": "ShinyCapabilitiesBrowserRuntimeV1",
          "@tanstack/react-virtual": "ShinyCapabilitiesBrowserRuntimeV1" },
        assetFileNames: asset => asset.name?.endsWith(".css") ? "selection-system.css" : "[name][extname]" }
    }
  }
});
