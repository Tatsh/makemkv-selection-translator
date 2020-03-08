module MakeMkvSelectionParser exposing (parse)
import Parser exposing ((|.), (|=), DeadEnd, Parser, andThen, chompWhile, end,
  getChompedString, oneOf, problem, run, spaces, succeed, symbol, token)

-- Parser
parse : String -> Result (List DeadEnd) String
parse string =
  run startParse string

onOff : Parser String
onOff =
  oneOf [ succeed identity
            |. token "+"
            |= selOrWeight "in" ""
            |. token ":"
        , succeed identity
            |. token "-"
            |= selOrWeight "de" "de"
            |. token ":"
        , succeed identity
            |. token "="
            |. chompWhile (\c -> Char.isDigit c || c == ':')
            |> getChompedString
            |> andThen
                (\s ->
                  case s |> String.dropLeft 1
                         |> String.dropRight 1
                         |> String.toInt of
                    Just a ->
                      succeed ("set weight to " ++ String.fromInt a ++ " for ")
                    Nothing ->
                      problem "not a number"
                )
        ]

selOrWeight : String -> String -> Parser String
selOrWeight y x =
  oneOf [ succeed (x ++ "select") |. token "sel"
        , succeed ()
            |. chompWhile Char.isDigit
            |> getChompedString
            |> andThen
                (\s ->
                  case s |> String.toInt of
                    Just a ->
                      succeed (y ++ "crease weight by " ++ String.fromInt a ++
                               " for ")
                    Nothing ->
                      problem "not a number"
                )
        ]


conditional : Parser String
conditional =
  oneOf [ selectable
        ]

commaOrEnd : Parser (String -> String)
commaOrEnd =
  oneOf [ succeed (\x -> "then " ++ x) |. symbol ","
        , succeed (\_ -> "")     |. end
        ]

selectable : Parser String
selectable =
  oneOf [ succeed "multi-channel audio tracks"    |. token "multi"
        , succeed "stereo audio tracks"           |. token "stereo"
        , succeed "mono audio tracks"             |. token "mono"
        , succeed "all tracks"                    |. token "all"
        , succeed "multi-angle video tracks"      |. token "mvcvideo"
        , succeed "favourite language tracks"     |. token "favlang"
        , succeed "subtitled tracks"              |. token "subtitle"
        , succeed "tracks with audio"             |. token "audio"
        , succeed "tracks without a language set" |. token "nolang"
        ]

selection : Parser (String, String)
selection =
  succeed Tuple.pair
    |= onOff
    |. spaces
    |= conditional


startParse : Parser String
startParse =
  succeed (\(x, y) -> x ++ " " ++ y)
    |= selection
    |. commaOrEnd
