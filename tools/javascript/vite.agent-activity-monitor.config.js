import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { copyFileSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";

const publishSources = {
  name: "publish-agent-activity-monitor-sources",
  closeBundle() {
    const target = resolve(import.meta.dirname, "../../inst/www/direct-transport/src");
    mkdirSync(target, { recursive: true });
    copyFileSync(resolve(import.meta.dirname, "src/agent-activity-monitor.jsx"), resolve(target, "agent-activity-monitor.jsx"));
    copyFileSync(resolve(import.meta.dirname, "src/agent-activity-monitor.css"), resolve(target, "agent-activity-monitor.css"));
  }
};

export default defineConfig({
  plugins: [react(), publishSources],
  define: { "process.env.NODE_ENV": JSON.stringify("production") },
  build: {
    outDir: "../../inst/www/direct-transport", emptyOutDir: false, cssCodeSplit: false,
    lib: { entry: resolve(import.meta.dirname, "src/agent-activity-monitor.jsx"),
      name: "ShinyCapabilitiesAgentActivityMonitor", formats: ["iife"],
      fileName: () => "agent-activity-monitor.js" },
    rollupOptions: { external: ["react", "react-dom", "react-dom/client", "@tanstack/react-virtual"],
      output: { globals: { react: "ShinyCapabilitiesBrowserRuntimeV1.React",
          "react-dom": "ShinyCapabilitiesBrowserRuntimeV1.ReactDOM",
          "react-dom/client": "ShinyCapabilitiesBrowserRuntimeV1",
          "@tanstack/react-virtual": "ShinyCapabilitiesBrowserRuntimeV1" },
        assetFileNames: asset => asset.name?.endsWith(".css") ? "agent-activity-monitor.css" : "[name][extname]" } }
  }
});
