import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { copyFileSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";
const publishSources={name:"publish-split-pane-sources",closeBundle(){const target=resolve(import.meta.dirname,"../../inst/htmlwidgets/src");mkdirSync(target,{recursive:true});for(const file of ["split-pane.jsx","split-pane.css"])copyFileSync(resolve(import.meta.dirname,`src/${file}`),resolve(target,file));}};
export default defineConfig({plugins:[react(),publishSources],define:{"process.env.NODE_ENV":JSON.stringify("production")},build:{outDir:"../../inst/htmlwidgets/lib",emptyOutDir:false,cssCodeSplit:false,lib:{entry:resolve(import.meta.dirname,"src/split-pane.jsx"),name:"ShinyCapabilitiesSplitPane",formats:["iife"],fileName:()=>"split-pane.js"},rollupOptions:{output:{assetFileNames:asset=>asset.name?.endsWith(".css")?"split-pane.css":"[name][extname]"}}}});
