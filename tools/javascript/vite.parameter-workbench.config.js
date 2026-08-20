import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { copyFileSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";

const publishSources = { name: "publish-parameter-workbench-sources", closeBundle() {
  const target = resolve(import.meta.dirname, "../../inst/htmlwidgets/src");
  mkdirSync(target, { recursive: true });
  for (const file of ["parameter-workbench.jsx", "parameter-workbench.css"])
    copyFileSync(resolve(import.meta.dirname, `src/${file}`), resolve(target, file));
}};

export default defineConfig({
  plugins: [react(), publishSources],
  define: { "process.env.NODE_ENV": JSON.stringify("production") },
  build: { outDir: "../../inst/htmlwidgets/lib", emptyOutDir: false, cssCodeSplit: false,
    lib: { entry: resolve(import.meta.dirname, "src/parameter-workbench.jsx"),
      name: "ShinyCapabilitiesParameterWorkbench", formats: ["iife"],
      fileName: () => "parameter-workbench.js" },
    rollupOptions: { output: { assetFileNames: asset => asset.name?.endsWith(".css") ? "parameter-workbench.css" : "[name][extname]" } }
  }
});
