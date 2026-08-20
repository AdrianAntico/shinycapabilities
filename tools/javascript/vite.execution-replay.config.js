import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { copyFileSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";

const publishSources = {
  name: "publish-execution-replay-sources",
  closeBundle() {
    const target = resolve(import.meta.dirname, "../../inst/htmlwidgets/src");
    mkdirSync(target, { recursive: true });
    copyFileSync(resolve(import.meta.dirname, "src/execution-replay.jsx"), resolve(target, "execution-replay.jsx"));
    copyFileSync(resolve(import.meta.dirname, "src/execution-replay.css"), resolve(target, "execution-replay.css"));
  }
};

export default defineConfig({
  plugins: [react(), publishSources],
  define: { "process.env.NODE_ENV": JSON.stringify("production") },
  build: {
    outDir: "../../inst/htmlwidgets/lib", emptyOutDir: false, cssCodeSplit: false,
    lib: { entry: resolve(import.meta.dirname, "src/execution-replay.jsx"),
      name: "ShinyCapabilitiesExecutionReplay", formats: ["iife"],
      fileName: () => "execution-replay.js" },
    rollupOptions: { output: { assetFileNames: asset => asset.name?.endsWith(".css") ? "execution-replay.css" : "[name][extname]" } }
  }
});
