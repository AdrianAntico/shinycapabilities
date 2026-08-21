import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { copyFileSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";

const publishInteractionSources = {
  name: "publish-interaction-component-sources",
  closeBundle() {
    const target = resolve(import.meta.dirname, "../../inst/www/direct-transport/src");
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
    outDir: "../../inst/www/direct-transport",
    emptyOutDir: false,
    cssCodeSplit: false,
    lib: {
      entry: resolve(import.meta.dirname, "src/interaction-components.jsx"),
      name: "ShinyCapabilitiesInteractionComponents",
      formats: ["iife"],
      fileName: () => "interaction-components.js"
    },
    rollupOptions: {
      external: ["react", "react-dom", "react-dom/client", "@tanstack/react-virtual"],
      output: { globals: { react: "ShinyCapabilitiesBrowserRuntimeV1.React",
          "react-dom": "ShinyCapabilitiesBrowserRuntimeV1.ReactDOM",
          "react-dom/client": "ShinyCapabilitiesBrowserRuntimeV1",
          "@tanstack/react-virtual": "ShinyCapabilitiesBrowserRuntimeV1" },
        assetFileNames: asset => asset.name?.endsWith(".css") ? "interaction-components.css" : "[name][extname]" }
    }
  }
});
