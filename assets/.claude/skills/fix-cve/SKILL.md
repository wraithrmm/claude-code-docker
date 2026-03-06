---
name: fix-cve
description: Fix CVE vulnerabilities in Docker images. Use when asked to address CVE failures, fix security scan results, or remediate vulnerabilities in a Docker image.
user-invocable: false
---

# Fix CVE

## Workflow

1. **Obtain the CVE report**: Use the report provided. If no report is available, run the project's existing Docker image security scan to generate one (check the project CLAUDE.md for scan commands).

2. **Break down each CVE into a separate review**: Parse the report and create an individual assessment for each CVE, noting the package, severity, and affected image layer.

3. **Research mitigations online**: For each CVE, search online for known mitigations, patches, and vendor advisories. Do not guess at fixes.

4. **Cross-reference findings**: Before implementing, group CVEs that share a common root cause (e.g., same base image, same package). Resolve common issues together to avoid redundant or conflicting fixes.

5. **Use agent teams**: Always use agent teams to parallelise the research and implementation work across CVEs.

6. **Implement fixes**: Apply the identified mitigations (package upgrades, base image changes, Dockerfile modifications, etc.).

7. **Build and scan**: After fixes are applied, build the Docker image locally and re-run the security scan to confirm the fixes resolved the CVEs.

---

## Best Practice SOPs

### Classifying CVEs: Fixable vs Suppressible

Before implementing any fix, classify each CVE into one of two categories:

- **Fixable**: The vulnerable package is installed via a package manager we control (npm, apt, pip). We can upgrade it.
- **Suppressible only**: The vulnerability is inside a compiled binary we install from upstream (e.g., Go binaries like `dockerd`, `tflint`, `terraform`, `docker-compose`). We cannot patch compiled binaries — add them to `.trivyignore.yml` with a clear statement explaining why.

### Locating Vulnerable Packages in the Image

When a scan reports a vulnerable package, determine **where** it is installed before choosing a fix strategy. Use `--entrypoint ""` to bypass any entrypoint checks:

```bash
docker run --rm --entrypoint "" <image> find / -path "*/<package-name>/package.json" -exec grep -l '"<version>"' {} \;
```

The location determines the fix approach:

| Location | Fix approach |
|----------|-------------|
| `/workspace/node_modules/` (local project) | npm overrides in `package.json` |
| `/usr/lib/node_modules/npm/node_modules/` (npm bundled) | Patch npm's bundled deps (see SOP below) |
| `/usr/lib/node_modules/<global-pkg>/` (global npm package) | Upgrade the global package or wait for upstream |
| `/usr/bin/<binary>` (compiled Go binary) | Suppress in `.trivyignore.yml` |

### Patching npm's Bundled Transitive Dependencies

npm bundles its own copies of packages like `minimatch` and `tar` at `/usr/lib/node_modules/npm/node_modules/`. These are **not** affected by `package.json` overrides (overrides only apply to local project installs).

**SOP — `npm install --install-strategy=nested` approach:**

```dockerfile
RUN set -e && \
    NPM_NM=/usr/lib/node_modules/npm/node_modules && \
    mkdir -p /tmp/npm-patches && cd /tmp/npm-patches && \
    npm init -y --silent && \
    npm install <pkg>@<version> --install-strategy=nested --silent && \
    rm -rf "$NPM_NM/<pkg>" && \
    cp -r node_modules/<pkg> "$NPM_NM/<pkg>" && \
    rm -rf /tmp/npm-patches && \
    node -e "console.log('<pkg>: ' + require('$NPM_NM/<pkg>/package.json').version)"
```

**Why `--install-strategy=nested`**: Each package gets its own `node_modules/` containing all transitive dependencies. This is critical because npm's public registry versions may use different (unscoped) dependency names than npm's internally-bundled versions (e.g., `brace-expansion` vs `@isaacs/brace-expansion`). Nested installation makes each patched package self-contained, avoiding missing-module errors.

**Why not `npm pack`**: While `npm pack` downloads only the package tarball (no transitive deps), this fails when the patched version has different transitive dependency names than the original. You end up manually chasing each transitive dep. The `--install-strategy=nested` approach handles this automatically.

**Key rules:**
- Download all tarballs / install all packages **before** replacing anything in npm's tree — npm uses its own bundled packages to operate, so replacing `minimatch` then trying to run `npm pack` will break npm
- Always verify npm still works after patching: `npm --version`
- Always verify the patched version: `node -e "require('...package.json').version"`

### Writing .trivyignore.yml Suppressions

For compiled Go binary CVEs and other unfixable vulnerabilities, add entries to `.trivyignore.yml`:

```yaml
  # <Brief description of the vulnerability>
  # Affects <list of binaries> (compiled Go binaries)
  # Requires <what upstream needs to do>
  - id: CVE-YYYY-NNNNN
    statement: Cannot patch compiled Go binary, awaiting upstream release with <package> <fixed-version>+
```

Group related entries together with shared comments. Always include:
- What binaries are affected
- What the upstream fix requirement is
- The suppression statement explaining why we can't fix it

### Iterative Scan-Fix Cycle

After implementing fixes, always rebuild and rescan. New CVEs may appear that were not in the original report because:
- Packages were re-downloaded at newer (or different) versions during the rebuild
- The scanner itself may have been updated with new advisory databases

Treat newly-appearing CVEs with the same classify-fix-or-suppress approach. Continue the build-scan cycle until the scan is clean for HIGH and CRITICAL.
