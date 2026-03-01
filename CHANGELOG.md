<!-- markdownlint-configure-file {"MD024": { "siblings_only": true } } -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [unreleased]

## [0.0.5] - 2025-02-28

### Added

- Pages workflow (on tag push): create zip and tar.gz of deploy assets, attest them with
  build provenance, and upload to the GitHub release. Repo name derived from
  `github.repository`; no hardcoded repo names in workflow.

### Changed

- GitHub fork ribbon script: added SPDX license and source URL (merrier/github-fork-ribbon).
- index: use fork ribbon library API (`githubForkRibbon.config`) with existence check;
  protocol-relative URL for repo link.
- Pages workflow: Prepare artifact uses `github.ref_type` and `github.ref_name` instead of
  `git tag --points-at`; deploy label URLs use `github.repository`. Bash variables in
  workflow steps use lowercase names.
- README: Elm badge updated.

## [0.0.4] - 2025-02-28

### Added

- Test suite: unit tests for MakeMkvSelectionParser (parse), Main (capitalize,
  conditionRendersAsListing), and Share (encodeSelection, decodeSelection, round-trip). elm-test
  with `elm-explorations/test`; CI Tests workflow runs tests and prints verbose results (JSON
  report).
- README: badges for Tests workflow, Elm, Yarn, markdownlint, cspell, pre-commit.

### Changed

- Tests: upgraded `elm-explorations/test` from 1.2.2 to 2.2.1 and added `elm/bytes` to
  test-dependencies for compatibility with the latest elm-test (2.x only).

## [0.0.3] - 2025-02-28

### Added

- Share: copy URL with selection in `?s=` (URI-encoded); on load, read `s`, prefill the input, and
  overwrite `lastSelection` in sessionStorage. After consuming `?s=`, remove it from the address bar
  (`history.replaceState`) so the URL is clean.
- Deploy footer (CI): placeholder in HTML replaced with either "Version:" (link to releases/tag) when
  the commit is tagged, or "Commit:" (link to commit) with 7-char SHA; plus deployment date/time in
  ISO format, GMT, no milliseconds.

### Changed

- Share: use the raw selection string in `?s=` (URI-encoded) instead of a short base64url-encoded
  format; Share encode/decode no longer used for the share URL.
- Share button is inline to the right of the textbox (Bootstrap input-group); textbox fills the rest
  of the row.
- Translation: statement-style lines (e.g. "Unselect all tracks") end with a period; lines that
  render as a list (OR/AND with multiple items, including nested) do not get a period.
- Syntax reference: language code placeholder in the bullet text changed from "xxx" to "YYY".
- CI: build step uses `yarn build:ci` (Elm with `--optimize`); prepare-artifact step injects deploy
  label and date into the footer placeholders.

### Removed

- Source map generation and deployment (the generated map only pointed at the start of the bundle).
  README documents that real source maps would require Elm compiler support.

## [0.0.2] - 2026-02-27

### Added

- Full MakeMKV selection syntax per [forum spec](https://forum.makemkv.com/forum/viewtopic.php?t=4386):
  `+sel`/`-sel`/`+N`/`-N`/`=N` actions; `|` `&` `*` `!` `~` operators; Not conditional.
- Condition tokens: `video`, `lossy`, `lossless`, `havelossless`, `forced`;
  `N` (nth track, with 1st/2nd/3rd ordinals); generic 3-letter ISO 639 language codes;
  `single`, `core`, `havemulti`, `havecore`; top 30 languages plus Cantonese (`yue`) and Dutch
  (`nld`).
- Structured translation: numbered top-level list; nested sublists with `|` and `&` bullets for
  OR/AND; "not" for negated conditions.
- Collapsible syntax reference with headers and bullets; clickable keywords append to the input and
  focus it with cursor at end.
- Friendly parse error messages; input shows error outline when parse fails.
- Persistence: syntax reference open/closed state in `localStorage`; last successful selection in
  `sessionStorage` (restored on load).
- Bootstrap 5 styling and dark theme (`data-bs-theme="dark"`).
- GitHub Pages workflow; live demo at <https://tatsh.github.io/makemkv-selection-translator/>.
- Live demo link in README.

### Changed

- Parser requires `+sel`/`-sel` for select/unselect (no optional `sel`).
- Translation output is a numbered list with nested bullet sublists instead of comma-separated text.

## [0.0.1] - 2026-02-24

First version.

[unreleased]: https://github.com/Tatsh/makemkv-selection-translator/compare/v0.0.5...HEAD
[0.0.5]: https://github.com/Tatsh/makemkv-selection-translator/compare/v0.0.4...v0.0.5
[0.0.4]: https://github.com/Tatsh/makemkv-selection-translator/compare/v0.0.3...v0.0.4
[0.0.3]: https://github.com/Tatsh/makemkv-selection-translator/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/Tatsh/makemkv-selection-translator/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/Tatsh/makemkv-selection-translator/releases/tag/v0.0.1
