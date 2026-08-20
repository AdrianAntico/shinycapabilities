import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { copyFileSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";

const publishSources = { name: "publish-relationship-graph-sources", closeBundle() {
  const target = resolve(import.meta.dirname, "../../inst/htmlwidgets/src");
  mkdirSync(target, { recursive: true });
  copyFileSync(resolve(import.meta.dirname, "src/relationship-graph.jsx"), resolve(target, "relationship-graph.jsx"));
  copyFileSync(resolve(import.meta.dirname, "src/relationship-graph.css"), resolve(target, "relationship-graph.css"));
}};

export default defineConfig({ plugins: [react(), publishSources],
  define: { "process.env.NODE_ENV": JSON.stringify("production") },
  build: { outDir: "../../inst/htmlwidgets/lib", emptyOutDir: false, cssCodeSplit: false,
    lib: { entry: resolve(import.meta.dirname, "src/relationship-graph.jsx"), name: "ShinyCapabilitiesRelationshipGraph",
      formats: ["iife"], fileName: () => "relationship-graph.js" },
    rollupOptions: { output: { assetFileNames: asset => asset.name?.endsWith(".css") ? "relationship-graph.css" : "[name][extname]" } }
  }
});
