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
    for (const name of ["direct-transport.js", "direct-react-vendor.jsx", "command-palette-direct.jsx", "command-palette-direct.css", "persistent-ui.js", "persistent-ui.css"])
      copyFileSync(resolve(root, `src/${name}`), resolve(sourceDir, name));
    copyFileSync(resolve(root, "src/direct-transport.js"), resolve(outDir, "direct-transport.js"));
    copyFileSync(resolve(root, "src/persistent-ui.js"), resolve(outDir, "persistent-ui.js"));
    copyFileSync(resolve(root, "src/persistent-ui.css"), resolve(outDir, "persistent-ui.css"));
  }
};
const target = process.env.SC_DIRECT_ENTRY || "vendor";
const isVendor = target === "vendor";
export default defineConfig({
  plugins: [react(), copySources], define: { "process.env.NODE_ENV": JSON.stringify("production") },
  build: { outDir, emptyOutDir: false, cssCodeSplit: false,
    lib: { entry: resolve(root, isVendor ? "src/direct-react-vendor.jsx" : "src/command-palette-direct.jsx"),
      name: isVendor ? "ShinyCapabilitiesReactVendorV1" : "ShinyCapabilitiesDirectPalette",
      formats: ["iife"], fileName: () => isVendor ? "react-vendor-v1.js" : "command-palette-direct.js" },
    rollupOptions: { output: { assetFileNames: asset => asset.name?.endsWith(".css") ? "command-palette-direct.css" : "[name][extname]" } }
  }
});
