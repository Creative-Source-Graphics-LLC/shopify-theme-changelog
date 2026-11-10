# Shopify Theme Changelog

[![Marketplace](https://img.shields.io/badge/Marketplace-Shopify%20Theme%20Changelog-ffffff?style=flat&logo=github&logoColor=white&labelColor=000000)](https://github.com/marketplace/actions/shopify-theme-changelog)
[![Release](https://img.shields.io/github/v/release/Creative-Source-Graphics-LLC/shopify-theme-changelog?style=flat&labelColor=000000&color=ffffff)](https://github.com/Creative-Source-Graphics-LLC/shopify-theme-changelog/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-ffffff?style=flat&labelColor=000000)](LICENSE)
![Shopify themes](https://img.shields.io/badge/Shopify-themes-ffffff?style=flat&logo=shopify&logoColor=white&labelColor=000000)
![Language: Liquid](https://img.shields.io/badge/Language-Liquid-ffffff?style=flat&labelColor=000000)

A GitHub Action that keeps a `CHANGELOG.md` in your Shopify theme repo. Every push is recorded with the time, the branch, who pushed and each commit, so the whole team can see what changed and when.

Built for repos connected to Shopify's GitHub integration: commits Shopify makes when someone saves in the theme editor ("Update from Shopify for theme ...") are labeled **Theme editor** and list the files they changed, so editor saves and code changes are easy to tell apart.

## What it looks like

```markdown
## 2026-11-06 11:20 UTC - `production` - pushed by alex

- 2026-11-06 06:17  Alex Rivera  `06ba123`  Add size chart to product pages
- 2026-11-06 06:02  **Theme editor**  `e7f6753`  changed `templates/index.json`, `config/settings_data.json`

## 2026-11-05 16:41 UTC - `dev` - pushed by sam

- 2026-11-05 16:38  Sam Lee  `3b36cd5`  Fix header spacing on mobile
```

Newest pushes go at the top. Merge commits and the action's own changelog commits are left out.

## Usage

Add `.github/workflows/changelog.yml` to your theme repo:

```yaml
name: Changelog

on:
  push:
    branches: ['**']

permissions:
  contents: write

jobs:
  changelog:
    if: github.actor != 'github-actions[bot]'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: Creative-Source-Graphics-LLC/shopify-theme-changelog@v1
```

`fetch-depth: 0` is needed so every commit in the push can be read. The `if:` line stops the action's own commit from starting another run.

Shopify ignores `CHANGELOG.md` in the repo root, so the file never shows up in your theme.

## Options

| Input | Default | What it does |
|---|---|---|
| `file` | `CHANGELOG.md` | Where the changelog is written. |
| `title` | `Changelog` | Heading at the top of the file. |
| `label-theme-editor` | `true` | Label theme editor commits and list the files they changed. |
| `skip-settings-only` | `false` | Leave out theme editor commits that only change `config/settings_data.json` (handy when the editor saves often). |
| `commit-message` | `Update CHANGELOG` | Message for the changelog commit. |
| `push` | `true` | Commit and push the changelog. Set to `false` to only write the file, for example to commit it in a later step. |

Output: `entries`, the number of commits recorded for the push.

## Notes

- New branches and force pushes record the latest commit only, since there's no earlier commit to compare against.
- If two pushes land at the same time, the action rebases and retries the push up to 3 times.
- Branch protection that blocks pushes from GitHub Actions will stop the changelog commit. Allow the `github-actions[bot]` to push, or set `push: false` and handle the commit yourself.

## License

MIT, by [Creative Source Graphics, LLC](https://creativesourcegraphics.com).
