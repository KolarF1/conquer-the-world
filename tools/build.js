// node tools/build.js  ->  build/ConquerTheWorld.rbxl (the place file you open in Studio to play)
// (tools/check.js builds build/check.rbxl instead, so running checks never rewrites an open place)
const { spawnSync } = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");
const root = path.join(__dirname, "..");
fs.mkdirSync(path.join(root, "build"), { recursive: true });
const r = spawnSync(path.join(os.homedir(), "tools", "rojo", "rojo.exe"), ["build", "-o", "build/ConquerTheWorld.rbxl"], { cwd: root, encoding: "utf8" });
process.stdout.write(r.stdout + r.stderr);
process.exit(r.status || 0);
