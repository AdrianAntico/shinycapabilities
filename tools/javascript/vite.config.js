import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { copyFileSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";

const publishWidgetSource = {
  name: "publish-widget-source-contract",
  closeBundle() {
    const target = resolve(import.meta.dirname, "../../inst/htmlwidgets/src");
    mkdirSync(target, { recursive: true });
    copyFileSync(
      resolve(import.meta.dirname, "src/widget.jsx"),
      resolve(target, "widget.jsx")
    );
  }
};

export default defineConfig({
  plugins: [react(), publishWidgetSource],
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
