# MakeMKV track selection translator

Translates a selection string to plain English. Serves as an example Elm project.

## MakeMKV selection syntax

Reference: [MakeMKV forum – Changing default track selection](https://forum.makemkv.com/forum/viewtopic.php?t=4386)

### Selection string

Comma-separated list of tokens. Each token: **{action}:{condition}**. Rules are evaluated left to
right. The condition is a boolean expression; parentheses and the operators below are allowed.

#### Actions

| Action | Meaning |
|--------|--------|
| `+sel` | Select track |
| `-sel` | Unselect track |
| `+N`   | Add N to track weight (order in output) |
| `-N`   | Subtract N from track weight |
| `=N`   | Set track weight to N |

#### Operators in conditions

| Operator | Meaning |
|----------|--------|
| `\|` | Logical OR |
| `&`  | Logical AND |
| `*`  | Alias for `&` (AND) |
| `!`  | Logical NOT |
| `~`  | Alias for `!` (NOT) |

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

```
-sel:all,+sel:(favlang|nolang),-sel:(havemulti|havecore),=100:all,-10:favlang
```

<!--## Naming template (reference)

Output naming format (separate from selection):

```
04-{:N2}-{NAME1}{-:CMNT1}{-:DT}{title:+DFLT}
```-->
