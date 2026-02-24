module MakeMkvSelectionParser exposing (Conditional(..), friendlyParseError, parse)

import Parser exposing
  ( (|.), (|=), DeadEnd, Parser, Step(..), andThen, chompIf, chompWhile, end, getChompedString
  , lazy, loop, map, oneOf, problem, run, spaces, succeed, symbol, token
  )

-- Structured conditional (OR/AND/NOT nest recursively)
type Conditional
  = Prim String
  | Or (List Conditional)
  | And (List Conditional)
  | Not Conditional

-- Parser
parse : String -> Result (List DeadEnd) (List ( String, Conditional ))
parse string =
  run startParse string

friendlyParseError : List DeadEnd -> String
friendlyParseError deadEnds =
  let
    pos =
      case List.head deadEnds of
        Just d ->
          "around character " ++ String.fromInt d.col
        Nothing ->
          "in the input"
    tip =
      "Separate each rule with a comma (e.g. -sel:all,+sel:subtitle)."
  in
  "Invalid selection. Problem " ++ pos ++ ". " ++ tip

-- One rule: {action}:{condition}  actions: +sel -sel +N -N =N
oneRule : Parser ( String, Conditional )
oneRule =
  succeed Tuple.pair
    |= prefix
    |. symbol ":"
    |. spaces
    |= conditional

prefix : Parser String
prefix =
  oneOf
    [ succeed identity
        |. token "="
        |= getChompedString (chompWhile Char.isDigit)
        |> andThen (\s -> weightResult "set weight to" s)
    , succeed identity
        |. token "+"
        |= oneOf
            [ getChompedString (chompWhile Char.isDigit)
                |> andThen
                    (\s ->
                      if s == "" then
                        problem "expected number or sel"
                      else
                        weightResult "increase weight by" s
                    )
            , succeed "select" |. token "sel"
            ]
    , succeed identity
        |. token "-"
        |= oneOf
            [ getChompedString (chompWhile Char.isDigit)
                |> andThen
                    (\s ->
                      if s == "" then
                        problem "expected number or sel"
                      else
                        weightResult "decrease weight by" s
                    )
            , succeed "unselect" |. token "sel"
            ]
    ]

weightResult : String -> String -> Parser String
weightResult verb s =
  case String.toInt s of
    Just n ->
      succeed (verb ++ " " ++ String.fromInt n ++ " for")
    Nothing ->
      problem "expected number"

-- conditional := and_expr
-- and_expr := or_expr ( (&|*) or_expr)*
-- or_expr := not_expr (| not_expr)*
-- not_expr := factor | ! not_expr | ~ not_expr
-- factor := selectable | ( conditional )
conditional : Parser Conditional
conditional =
  lazy (\_ -> andExpr)

andExpr : Parser Conditional
andExpr =
  succeed (\first rest -> And (first :: rest))
    |= orExpr
    |= loop [] andLoop

andOp : Parser ()
andOp =
  oneOf [ symbol "&", symbol "*" ]

andLoop : List Conditional -> Parser (Step (List Conditional) (List Conditional))
andLoop rev =
  oneOf
    [ succeed (\c -> Loop (c :: rev))
        |. spaces
        |. andOp
        |. spaces
        |= orExpr
    , succeed (Done (List.reverse rev))
    ]

orExpr : Parser Conditional
orExpr =
  succeed (\first rest -> Or (first :: rest))
    |= notExpr
    |= loop [] orLoop

orLoop : List Conditional -> Parser (Step (List Conditional) (List Conditional))
orLoop rev =
  oneOf
    [ succeed (\c -> Loop (c :: rev))
        |. spaces
        |. symbol "|"
        |. spaces
        |= notExpr
    , succeed (Done (List.reverse rev))
    ]

notExpr : Parser Conditional
notExpr =
  oneOf
    [ succeed Not
        |. oneOf [ symbol "!", symbol "~" ]
        |. spaces
        |= lazy (\_ -> notExpr)
    , factor
    ]

factor : Parser Conditional
factor =
  oneOf
    [ selectable |> map Prim
    , succeed identity
        |. symbol "("
        |. spaces
        |= lazy (\_ -> conditional)
        |. spaces
        |. symbol ")"
    ]

selectable : Parser String
selectable =
  oneOf
    [ succeed "all tracks"                    |. token "all"
    , succeed "video track"                   |. token "video"
    , succeed "audio track"                   |. token "audio"
    , succeed "subtitle track"                |. token "subtitle"
    , succeed "multi-angle (3D) video track" |. token "mvcvideo"
    , succeed "favourite language"           |. token "favlang"
    , succeed "tracks without a language set" |. token "nolang"
    , succeed "special (director's comment, etc.)" |. token "special"
    , succeed "forced subtitle"               |. token "forced"
    , succeed "mono audio"                    |. token "mono"
    , succeed "stereo audio"                 |. token "stereo"
    , succeed "multi-channel audio"           |. token "multi"
    , succeed "mono/stereo when multi exists in same language" |. token "havemulti"
    , succeed "lossy audio"                   |. token "lossy"
    , succeed "lossless audio"                |. token "lossless"
    , succeed "lossy when lossless exists in same language" |. token "havelossless"
    , succeed "core audio (part of HD track)" |. token "core"
    , succeed "HD track with core audio"     |. token "havecore"
    , succeed "single audio track"            |. token "single"
    -- ISO 639-2 (3-letter) codes, top 30 languages
    , succeed "Arabic"        |. token "ara"
    , succeed "Bengali"        |. token "ben"
    , succeed "Chinese"        |. token "zho"
    , succeed "Cantonese"       |. token "yue"
    , succeed "Dutch"           |. token "nld"
    , succeed "English"         |. token "eng"
    , succeed "Finnish"        |. token "fin"
    , succeed "French"         |. token "fra"
    , succeed "German"         |. token "deu"
    , succeed "Gujarati"       |. token "guj"
    , succeed "Hindi"          |. token "hin"
    , succeed "Italian"        |. token "ita"
    , succeed "Japanese"       |. token "jpn"
    , succeed "Javanese"       |. token "jav"
    , succeed "Kannada"        |. token "kan"
    , succeed "Korean"         |. token "kor"
    , succeed "Malay"          |. token "msa"
    , succeed "Malayalam"      |. token "mal"
    , succeed "Marathi"        |. token "mar"
    , succeed "Persian"        |. token "fas"
    , succeed "Polish"         |. token "pol"
    , succeed "Portuguese"    |. token "por"
    , succeed "Punjabi"        |. token "pan"
    , succeed "Romanian"       |. token "ron"
    , succeed "Russian"        |. token "rus"
    , succeed "Spanish"        |. token "spa"
    , succeed "Tamil"          |. token "tam"
    , succeed "Telugu"         |. token "tel"
    , succeed "Turkish"        |. token "tur"
    , succeed "Ukrainian"      |. token "ukr"
    , succeed "Urdu"           |. token "urd"
    , succeed "Vietnamese"     |. token "vie"
    -- N = Nth (or higher) track of same type and language
    , getChompedString (chompWhile Char.isDigit)
        |> andThen
            (\s ->
              if s == "" then
                problem "expected digits"
              else
                succeed ("matches if " ++ s ++ "th (or higher) track of same type and language")
            )
    -- Any ISO 639-2/3 3-letter language code
    , getChompedString
        (succeed ()
            |. chompIf Char.isLower
            |. chompIf Char.isLower
            |. chompIf Char.isLower
        )
        |> map (\code -> "language: " ++ code)
    ]

-- Comma-separated rules
startParse : Parser (List ( String, Conditional ))
startParse =
  succeed (\first rest -> first :: rest)
    |= oneRule
    |= loop [] rulesLoop

rulesLoop : List ( String, Conditional ) -> Parser (Step (List ( String, Conditional )) (List ( String, Conditional )))
rulesLoop rev =
  oneOf
    [ succeed (\r -> Loop (r :: rev))
        |. spaces
        |. symbol ","
        |. spaces
        |= oneRule
    , succeed (Done (List.reverse rev))
        |. end
    ]