import React from "react";
import * as ReactDOM from "react-dom";
import { createRoot } from "react-dom/client";
import { useVirtualizer } from "@tanstack/react-virtual";
import * as ResizablePanels from "react-resizable-panels";

const identity = Object.freeze({ name: "shinycapabilities-browser-runtime", major: 1,
  version: "1.0.0", react: React.version, tanstackVirtual: "3.13.12" });
const existing = window.ShinyCapabilitiesBrowserRuntimeV1;
if (existing && existing.identity?.major !== identity.major)
  throw new Error(`Incompatible shinycapabilities browser runtime: expected major ${identity.major}.`);
const runtime = existing || Object.freeze({ identity, React, ReactDOM, createRoot, useVirtualizer,
  ResizablePanels,
  assertCompatible(requiredMajor = 1) {
    if (requiredMajor !== identity.major) throw new Error(`Component requires browser runtime major ${requiredMajor}; loaded ${identity.major}.`);
    return true;
  }
});
window.ShinyCapabilitiesBrowserRuntimeV1 = runtime;
window.ShinyCapabilitiesReactVendorV1 = runtime;
