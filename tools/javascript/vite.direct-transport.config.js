import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { copyFileSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";

const root = import.meta.dirname;
const outDir = resolve(root, "../../inst/www/direct-transport");
const sourceDir = resolve(root, "../../inst/www/direct-transport/src");
const copySources = {
  name: "publish-direct-transport-sources",
  closeBundle() {
    mkdirSync(sourceDir, { recursive: true });
    for (const name of ["direct-transport.js", "direct-react-vendor.jsx", "command-palette-direct.jsx", "command-palette-direct.css", "persistent-ui.js", "persistent-ui.css", "split-pane-direct.jsx", "split-pane.css"])
      copyFileSync(resolve(root, `src/${name}`), resolve(sourceDir, name));
    copyFileSync(resolve(root, "src/direct-transport.js"), resolve(outDir, "direct-transport.js"));
    copyFileSync(resolve(root, "src/persistent-ui.js"), resolve(outDir, "persistent-ui.js"));
    copyFileSync(resolve(root, "src/persistent-ui.css"), resolve(outDir, "persistent-ui.css"));
  }
};
const target = process.env.SC_DIRECT_ENTRY || "runtime";
const entries = {
  runtime: { source: "src/direct-react-vendor.jsx", name: "ShinyCapabilitiesBrowserRuntimeV1", file: "browser-runtime-v1.js" },
  palette: { source: "src/command-palette-direct.jsx", name: "ShinyCapabilitiesDirectPalette", file: "command-palette-direct.js" },
  split: { source: "src/split-pane-direct.jsx", name: "ShinyCapabilitiesDirectSplitPane", file: "split-pane-direct.js" }
};
const entry = entries[target];
if (!entry) throw new Error(`Unknown SC_DIRECT_ENTRY: ${target}`);
export default defineConfig({
  plugins: [react(), copySources], define: { "process.env.NODE_ENV": JSON.stringify("production") },
  build: { outDir, emptyOutDir: false, cssCodeSplit: false,
    lib: { entry: resolve(root, entry.source), name: entry.name,
      formats: ["iife"], fileName: () => entry.file },
    rollupOptions: {
      external: target === "split" ? ["react", "react-dom", "react-dom/client"] : [],
      output: {
        globals: { react: "ShinyCapabilitiesBrowserRuntimeV1.React",
          "react-dom": "ShinyCapabilitiesBrowserRuntimeV1.ReactDOM",
          "react-dom/client": "ShinyCapabilitiesBrowserRuntimeV1" },
        assetFileNames: asset => asset.name?.endsWith(".css") ?
          (target === "split" ? "split-pane-direct.css" : "command-palette-direct.css") : "[name][extname]"
      }
    }
  }
});
