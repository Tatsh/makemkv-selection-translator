# MakeMKV track selection translator

[![GitHub tag (with filter)](https://img.shields.io/github/v/tag/Tatsh/makemkv-selection-translator)](https://github.com/Tatsh/makemkv-selection-translator/tags)
[![License](https://img.shields.io/github/license/Tatsh/makemkv-selection-translator)](https://github.com/Tatsh/makemkv-selection-translator/blob/master/LICENSE.txt)
[![GitHub commits since latest release (by SemVer including pre-releases)](https://img.shields.io/github/commits-since/Tatsh/makemkv-selection-translator/v0.0.1/master)](https://github.com/Tatsh/makemkv-selection-translator/compare/v0.0.1...master)
[![QA](https://github.com/Tatsh/makemkv-selection-translator/actions/workflows/qa.yml/badge.svg)](https://github.com/Tatsh/makemkv-selection-translator/actions/workflows/qa.yml)
[![Dependabot](https://img.shields.io/badge/Dependabot-enabled-blue?logo=dependabot)](https://github.com/dependabot)
[![GitHub Pages](https://github.com/Tatsh/makemkv-selection-translator/actions/workflows/pages.yml/badge.svg)](https://Tatsh.github.io/makemkv-selection-translator/)
[![Stargazers](https://img.shields.io/github/stars/Tatsh/makemkv-selection-translator?logo=github&style=flat)](https://github.com/Tatsh/makemkv-selection-translator/stargazers)
[![Prettier](https://img.shields.io/badge/Prettier-enabled-black?logo=prettier)](https://prettier.io/)

[![@Tatsh](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fpublic.api.bsky.app%2Fxrpc%2Fapp.bsky.actor.getProfile%2F%3Factor=did%3Aplc%3Auq42idtvuccnmtl57nsucz72&query=%24.followersCount&label=Follow+%40Tatsh&logo=bluesky&style=social)](https://bsky.app/profile/Tatsh.bsky.social)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Tatsh-black?logo=buymeacoffee)](https://buymeacoffee.com/Tatsh)
[![Libera.Chat](https://img.shields.io/badge/Libera.Chat-Tatsh-black?logo=liberadotchat)](irc://irc.libera.chat/Tatsh)
[![Mastodon Follow](https://img.shields.io/mastodon/follow/109370961877277568?domain=hostux.social&style=social)](https://hostux.social/@Tatsh)
[![Patreon](https://img.shields.io/badge/Patreon-Tatsh2-F96854?logo=patreon)](https://www.patreon.com/Tatsh2)

Translates a selection string to plain English. Serves as an example Elm project.

## MakeMKV selection syntax

Reference: [MakeMKV forum – Changing default track selection](https://forum.makemkv.com/forum/viewtopic.php?t=4386)

### Selection string

Comma-separated list of tokens. Each token: **{action}:{condition}**. Rules are evaluated left to
right. The condition is a boolean expression; parentheses and the operators below are allowed.

#### Actions

| Action | Meaning                                 |
| ------ | --------------------------------------- |
| `+sel` | Select track                            |
| `-sel` | Unselect track                          |
| `+N`   | Add N to track weight (order in output) |
| `-N`   | Subtract N from track weight            |
| `=N`   | Set track weight to N                   |

#### Operators in conditions

| Operator | Meaning             |
| -------- | ------------------- |
| `\|`     | Logical OR          |
| `&`      | Logical AND         |
| `*`      | Alias for `&` (AND) |
| `!`      | Logical NOT         |
| `~`      | Alias for `!` (NOT) |

#### Condition tokens

- **N** – decimal number: matches if Nth (or higher) track of same type and language
- `all` – always matches
- `audio` – audio track
- `core`, `havecore` – core audio / HD track with core
- `favlang` – favourite languages (or always if none set)
- `forced` – forced subtitle
- `havemulti` – mono/stereo when a multi-channel track exists in same language
- `lossy`, `lossless`, `havelossless` – lossy/lossless audio
- `mono`, `stereo`, `multi` – audio channel count
- `mvcvideo` – 3D multi-view video
- `nolang` – no language set
- `single` – single audio track (extension)
- `special` – special tracks (director’s comment, etc.)
- `subtitle` – subtitle track
- `video` – video track
- `xxx` – any ISO 639-2/639-3 3-letter language code (e.g. eng, fra, deu)

#### Example

```plain
-sel:all,+sel:(favlang|nolang),-sel:(havemulti|havecore),=100:all,-10:favlang
```

<!--## Naming template (reference)

Output naming format (separate from selection):

```plain
04-{:N2}-{NAME1}{-:CMNT1}{-:DT}{title:+DFLT}
```-->
