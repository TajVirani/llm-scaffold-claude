#!/usr/bin/env bun
// Reports dependencies declared in >=2 workspaces, flagging version drift.
// Workspaces are the root package.json plus every package.json matched by its `workspaces` globs
// (array form or `{ packages: [...] }`); manifests outside those globs (fixtures, examples) are ignored.
// Run from repo root: bun .agents/skills/deps-update/scripts/drift.ts [--all]
import { Glob } from "bun";

const showAll = process.argv.includes("--all");

const root = await Bun.file("package.json").json();
const patterns: string[] = Array.isArray(root.workspaces) ? root.workspaces : (root.workspaces?.packages ?? []);

const manifests = new Set<string>(["package.json"]);
for (const pattern of patterns) {
  if (pattern.startsWith("!")) continue;
  const glob = new Glob(`${pattern.replace(/\/$/, "")}/package.json`);
  for await (const path of glob.scan({ dot: false })) {
    if (!path.includes("node_modules")) manifests.add(path);
  }
}

const byDep = new Map<string, Map<string, string>>();
for (const path of manifests) {
  const pkg = await Bun.file(path).json();
  const ws = path === "package.json" ? "root" : path.replace(/\/package\.json$/, "");
  for (const section of ["dependencies", "devDependencies", "peerDependencies"] as const) {
    for (const [name, range] of Object.entries(pkg[section] ?? {})) {
      if (String(range).startsWith("workspace:")) continue; // workspace protocol, not a version
      (byDep.get(name) ?? byDep.set(name, new Map()).get(name)!).set(ws, String(range));
    }
  }
}

let drifted = 0;
for (const name of [...byDep.keys()].sort()) {
  const locs = byDep.get(name)!;
  if (locs.size < 2) continue;
  const isDrift = new Set(locs.values()).size > 1;
  if (!isDrift && !showAll) continue;
  if (isDrift) drifted++;
  const flag = isDrift ? " ← DRIFT" : "";
  console.log(`${name}  (${locs.size} ws)${flag}`);
  for (const [ws, range] of locs) console.log(`    ${range}\t${ws}`);
}
console.log(`\n${drifted} drifting dep(s). Catalog candidates: everything above.`);
