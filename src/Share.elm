module Share exposing (decodeSelection, encodeSelection)

import MakeMkvSelectionParser exposing (Conditional(..))

{-| Encode a selection string to a short Game Genie-style string.
Returns Nothing if the string does not parse.
-}
encodeSelection : String -> Maybe String
encodeSelection input =
  case MakeMkvSelectionParser.parse input of
    Err _ ->
      Nothing
    Ok rules ->
      Just (String.join "," (List.map ruleToShort rules))

{-| Decode a short string back to the full selection string.
-}
decodeSelection : String -> Result String String
decodeSelection short =
  parseShortRules short

ruleToShort : ( String, Conditional ) -> String
ruleToShort ( action, cond ) =
  actionToShort action ++ ":" ++ condToShort cond

actionToShort : String -> String
actionToShort action =
  if action == "select" then
    "P"
  else if action == "unselect" then
    "M"
  else if String.startsWith "set weight to " action then
    "S" ++ extractWeight action
  else if String.startsWith "decrease weight by " action then
    "D" ++ extractWeight action
  else if String.startsWith "increase weight by " action then
    "I" ++ extractWeight action
  else
    "P"

extractWeight : String -> String
extractWeight s =
  s
    |> String.words
    |> List.drop 3
    |> List.head
    |> Maybe.withDefault "0"

condToShort : Conditional -> String
condToShort c =
  case c of
    Prim desc ->
      primToCode desc
    Or list ->
      "(" ++ String.join "|" (List.map condToShort list) ++ ")"
    And list ->
      "(" ++ String.join "&" (List.map condToShort list) ++ ")"
    Not inner ->
      "!" ++ condToShort inner

primToCode : String -> String
primToCode desc =
  if String.startsWith "matches if " desc then
    "6" ++ extractNth desc
  else if String.startsWith "language: " desc then
    String.dropLeft 10 desc
  else
    descToCode desc

extractNth : String -> String
extractNth s =
  s
    |> String.dropLeft 11
    |> takeLeadingDigits

takeLeadingDigits : String -> String
takeLeadingDigits s =
  case String.uncons s of
    Nothing ->
      ""
    Just ( c, rest ) ->
      if Char.isDigit c then
        String.cons c (takeLeadingDigits rest)
      else
        ""

descToCode : String -> String
descToCode d =
  case d of
    "all tracks" -> "a"
    "video track" -> "v"
    "audio track" -> "u"
    "subtitle track" -> "t"
    "multi-angle (3D) video track" -> "3"
    "favourite language" -> "f"
    "tracks without a language set" -> "n"
    "special (director's comment, etc.)" -> "e"
    "forced subtitle" -> "o"
    "mono audio" -> "1"
    "stereo audio" -> "2"
    "multi-channel audio" -> "4"
    "mono/stereo when multi exists in same language" -> "h"
    "lossy audio" -> "y"
    "lossless audio" -> "l"
    "lossy when lossless exists in same language" -> "k"
    "core audio (part of HD track)" -> "c"
    "HD track with core audio" -> "C"
    "single audio track" -> "5"
    _ ->
      if String.length d == 3 && String.all Char.isLower d then
        d
      else
        langNameToCode d

langNameToCode : String -> String
langNameToCode name =
  case name of
    "Arabic" -> "ara"
    "Bengali" -> "ben"
    "Chinese" -> "zho"
    "Cantonese" -> "yue"
    "Dutch" -> "nld"
    "English" -> "eng"
    "Finnish" -> "fin"
    "French" -> "fra"
    "German" -> "deu"
    "Gujarati" -> "guj"
    "Hindi" -> "hin"
    "Italian" -> "ita"
    "Japanese" -> "jpn"
    "Javanese" -> "jav"
    "Kannada" -> "kan"
    "Korean" -> "kor"
    "Malay" -> "msa"
    "Malayalam" -> "mal"
    "Marathi" -> "mar"
    "Persian" -> "fas"
    "Polish" -> "pol"
    "Portuguese" -> "por"
    "Punjabi" -> "pan"
    "Romanian" -> "ron"
    "Russian" -> "rus"
    "Spanish" -> "spa"
    "Tamil" -> "tam"
    "Telugu" -> "tel"
    "Turkish" -> "tur"
    "Ukrainian" -> "ukr"
    "Urdu" -> "urd"
    "Vietnamese" -> "vie"
    _ -> "a"

codeToToken : String -> String
codeToToken c =
  case c of
    "a" -> "all"
    "v" -> "video"
    "u" -> "audio"
    "t" -> "subtitle"
    "3" -> "mvcvideo"
    "f" -> "favlang"
    "n" -> "nolang"
    "e" -> "special"
    "o" -> "forced"
    "1" -> "mono"
    "2" -> "stereo"
    "4" -> "multi"
    "h" -> "havemulti"
    "y" -> "lossy"
    "l" -> "lossless"
    "k" -> "havelossless"
    "c" -> "core"
    "C" -> "havecore"
    "5" -> "single"
    _ ->
      if String.length c == 3 && String.all Char.isLower c then
        c
      else if String.startsWith "6" c && String.length c > 1 then
        String.dropLeft 1 c
      else
        "all"

parseShortRules : String -> Result String String
parseShortRules s =
  if String.isEmpty s then
    Ok ""
  else
    s
      |> String.split ","
      |> List.map parseShortRule
      |> combineResults
      |> Result.map (String.join ",")

combineResults : List (Result e a) -> Result e (List a)
combineResults list =
  case list of
    [] ->
      Ok []
    r :: rs ->
      Result.map2 (::) r (combineResults rs)

parseShortRule : String -> Result String String
parseShortRule rule =
  case String.split ":" rule of
    [ act, cond ] ->
      Ok (shortActionToLong act ++ ":" ++ shortCondToLong cond)
    _ ->
      Err ("Invalid rule: " ++ rule)

shortActionToLong : String -> String
shortActionToLong a =
  if a == "P" then
    "+sel"
  else if a == "M" then
    "-sel"
  else if String.startsWith "S" a then
    "=" ++ String.dropLeft 1 a
  else if String.startsWith "D" a then
    "-" ++ String.dropLeft 1 a
  else if String.startsWith "I" a then
    "+" ++ String.dropLeft 1 a
  else
    "+sel"

shortCondToLong : String -> String
shortCondToLong s =
  if String.isEmpty s then
    ""
  else if String.startsWith "!" s then
    "!" ++ shortCondToLong (String.dropLeft 1 s)
  else if String.startsWith "(" s then
    let
      ( inner, rest ) = splitParens (String.dropLeft 1 s) 0
    in
    "(" ++ shortCondToLong inner ++ ")" ++ shortCondToLong rest
  else if String.startsWith "|" s then
    "|" ++ shortCondToLong (String.dropLeft 1 s)
  else if String.startsWith "&" s then
    "&" ++ shortCondToLong (String.dropLeft 1 s)
  else if String.startsWith ")" s then
    -- Closing paren is structure; rest after splitParens may start with ')'.
    -- Must not recurse without consuming (takeShortToken returns ("", s)).
    ""
  else
    let
      ( token, rest ) = takeShortToken s
    in
    codeToToken token ++ shortCondToLong rest

splitParens : String -> Int -> ( String, String )
splitParens str depth =
  case String.uncons str of
    Nothing ->
      ( "", "" )
    Just ( ')', rest ) ->
      if depth == 0 then
        ( "", rest )
      else
        let
          ( inner, after ) = splitParens rest (depth - 1)
        in
        ( ")" ++ inner, after )
    Just ( '(', rest ) ->
      let
        ( inner, after ) = splitParens rest (depth + 1)
        ( cont, rest2 ) = splitParens after depth
      in
      ( "(" ++ inner ++ ")" ++ cont, rest2 )
    Just ( c, rest ) ->
      let
        ( cont, rest2 ) = splitParens rest depth
      in
      ( String.cons c cont, rest2 )

singleCodes : List Char
singleCodes =
  [ 'a', 'v', 'u', 't', 'f', 'n', 'e', 'o', 'h', 'y', 'l', 'k', 'c', 'C'
  , '1', '2', '3', '4', '5'
  ]

takeShortToken : String -> ( String, String )
takeShortToken s =
  case String.uncons s of
    Nothing ->
      ( "", "" )
    Just ( '(', _ ) ->
      ( "", s )
    Just ( ')', _ ) ->
      ( "", s )
    Just ( '|', _ ) ->
      ( "", s )
    Just ( '&', _ ) ->
      ( "", s )
    Just ( '!', _ ) ->
      ( "", s )
    Just ( '6', rest ) ->
      let
        digits = takeLeadingDigits rest
        tail = String.dropLeft (String.length digits) rest
      in
      ( "6" ++ digits, tail )
    Just ( c, rest ) ->
      if List.member c singleCodes then
        ( String.fromChar c, rest )
      else if Char.isLower c then
        ( String.left 3 s, String.dropLeft 3 s )
      else
        ( String.fromChar c, rest )
