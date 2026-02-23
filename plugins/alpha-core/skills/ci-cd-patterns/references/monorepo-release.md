# Monorepo Tools and Release Automation

## When to load
Load when configuring Turborepo, Nx, or Bazel for monorepos, or setting up semantic-release, changesets, or release-please.

## Monorepo Build Tool Comparison

| Feature | Turborepo | Nx | Bazel |
|---------|-----------|-----|-------|
| **Primary language** | JS/TS | JS/TS (extensible) | Multi-language |
| **Config format** | `turbo.json` | `nx.json` + `project.json` | `BUILD` files (Starlark) |
| **Remote cache** | Vercel Remote Cache | Nx Cloud | Remote Execution + Cache |
| **Affected detection** | Hash-based | Dependency graph | Content-addressable |
| **Learning curve** | Low | Medium | High |
| **Best for** | JS/TS monorepos | JS/TS + growing polyglot | Large polyglot codebases |

## Turborepo Configuration
```json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env"],
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**"]
    },
    "test": {
      "dependsOn": ["build"],
      "inputs": ["src/**", "test/**"]
    },
    "lint": {},
    "deploy": {
      "dependsOn": ["build", "test", "lint"]
    }
  }
}
```

## Nx Configuration
```json
{
  "targetDefaults": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["production", "^production"],
      "cache": true
    },
    "test": {
      "inputs": ["default", "^production"],
      "cache": true
    }
  },
  "namedInputs": {
    "production": ["default", "!{projectRoot}/**/*.spec.ts"]
  }
}
```

## Release Automation Tools

### semantic-release
```json
{
  "branches": ["main", { "name": "beta", "prerelease": true }],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm",
    "@semantic-release/github",
    ["@semantic-release/git", { "assets": ["CHANGELOG.md", "package.json"] }]
  ]
}
```
```yaml
release:
  runs-on: ubuntu-latest
  if: github.ref == 'refs/heads/main'
  steps:
    - uses: actions/checkout@v4
      with: { fetch-depth: 0 }
    - run: npx semantic-release
      env: { GITHUB_TOKEN: '${{ secrets.GITHUB_TOKEN }}', NPM_TOKEN: '${{ secrets.NPM_TOKEN }}' }
```

### changesets
```bash
# Developer adds a changeset
npx changeset
# Prompts: Which packages? Major/minor/patch? Description?
# Creates .changeset/happy-fish-dance.md
```
```yaml
version-or-publish:
  steps:
    - uses: changesets/action@v1
      with: { publish: npm run release }
      env: { GITHUB_TOKEN: '${{ secrets.GITHUB_TOKEN }}', NPM_TOKEN: '${{ secrets.NPM_TOKEN }}' }
```

### release-please
```yaml
release:
  steps:
    - uses: googleapis/release-please-action@v4
      id: release
      with: { release-type: node }
    - uses: actions/checkout@v4
      if: ${{ steps.release.outputs.release_created }}
    - run: npm ci && npm publish
      if: ${{ steps.release.outputs.release_created }}
```

## Deployment Infrastructure Tools
- **Terraform / OpenTofu**: Infrastructure provisioning (HCL), state management, plan/apply
- **Helm**: Kubernetes package management, charts, values overrides, hooks, rollback
- **Kustomize**: Kubernetes configuration customization, overlays, patches
- **Pulumi**: Infrastructure as code with real programming languages (TS, Python, Go, C#)
- **CDK (AWS)**: Infrastructure as code synthesizing CloudFormation
- **Skaffold / Tilt**: Local Kubernetes development with live update and dashboard
