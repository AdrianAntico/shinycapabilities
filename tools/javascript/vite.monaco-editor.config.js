import { defineConfig } from "vite";
import { copyFileSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";

const root = import.meta.dirname;
const outDir = resolve(root, "../../inst/www/direct-transport");
const sourceDir = resolve(root, "../../inst/www/direct-transport/src");

export default defineConfig({
  base: "./",
  define: { "process.env.NODE_ENV": JSON.stringify("production") },
  plugins: [{
    name: "publish-monaco-editor-source",
    closeBundle() {
      mkdirSync(sourceDir, { recursive: true });
      for (const name of ["code-editor.js", "code-editor.css"])
        copyFileSync(resolve(root, `src/${name}`), resolve(sourceDir, name));
    }
  }],
  build: {
    outDir,
    emptyOutDir: false,
    cssCodeSplit: false,
    lib: {
      entry: resolve(root, "src/code-editor.js"),
      name: "ShinyCapabilitiesCodeEditor",
      formats: ["es"],
      fileName: () => "code-editor.js"
    },
    rollupOptions: {
      output: {
        assetFileNames: asset => asset.name?.endsWith(".css") ?
          "code-editor.css" : "monaco-[name]-[hash][extname]"
      }
    }
  }
});
