import { defineConfig } from "vite";
import { copyFileSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";

const publishDataGridSources = {
  name: "publish-data-grid-sources",
  generateBundle(_options, bundle) {
    for (const output of Object.values(bundle)) {
      if (output.type === "chunk") output.code = output.code.replace(/[ \t]+$/gm, "");
    }
  },
  closeBundle() {
    const target = resolve(import.meta.dirname, "../../inst/htmlwidgets/src");
    mkdirSync(target, { recursive: true });
    copyFileSync(resolve(import.meta.dirname, "src/data-grid.js"), resolve(target, "data-grid.js"));
    copyFileSync(resolve(import.meta.dirname, "src/data-grid.css"), resolve(target, "data-grid.css"));
  }
};

export default defineConfig({
  plugins: [publishDataGridSources],
  build: {
    outDir: "../../inst/htmlwidgets/lib",
    emptyOutDir: false,
    cssCodeSplit: false,
    lib: {
      entry: resolve(import.meta.dirname, "src/data-grid.js"),
      name: "ShinyCapabilitiesDataGrid",
      formats: ["iife"],
      fileName: () => "data-grid.js"
    },
    rollupOptions: {
      output: { assetFileNames: asset => asset.name?.endsWith(".css") ? "data-grid.css" : "[name][extname]" }
    }
  }
});
