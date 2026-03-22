module MakeMkvSelectionParserTests exposing (suite)

import Expect
import MakeMkvSelectionParser exposing (Conditional(..), friendlyParseError, parse)
import Parser
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "MakeMkvSelectionParser"
        [ parseTests
        , friendlyParseErrorTests
        , selectableTokenTests
        , languageCodeTests
        , weightTests
        , operatorTests
        , ordinalTests
        , edgeCaseTests
        ]


parseTests : Test
parseTests =
    describe "parse"
        [ test "parses -sel:all as unselect all tracks" <|
            \_ ->
                parse "-sel:all"
                    |> Expect.equal
                        (Ok [ ( "unselect", And [ Or [ Prim "all tracks" ] ] ) ])
        , test "parses +sel:all as select all tracks" <|
            \_ ->
                parse "+sel:all"
                    |> Expect.equal
                        (Ok [ ( "select", And [ Or [ Prim "all tracks" ] ] ) ])
        , test "parses +sel:video as select video track" <|
            \_ ->
                parse "+sel:video"
                    |> Expect.equal
                        (Ok [ ( "select", And [ Or [ Prim "video track" ] ] ) ])
        , test "parses +sel:(favlang|nolang) as select with Or condition" <|
            \_ ->
                parse "+sel:(favlang|nolang)"
                    |> Expect.equal
                        (Ok
                            [ ( "select"
                              , And
                                    [ Or
                                        [ And
                                            [ Or
                                                [ Prim "favourite language"
                                                , Prim "tracks without a language set"
                                                ]
                                            ]
                                        ]
                                    ]
                              )
                            ]
                        )
        , test "parses multiple rules" <|
            \_ ->
                parse "-sel:all,+sel:subtitle"
                    |> Expect.equal
                        (Ok
                            [ ( "unselect", And [ Or [ Prim "all tracks" ] ] )
                            , ( "select", And [ Or [ Prim "subtitle track" ] ] )
                            ]
                        )
        , test "rejects invalid input with Err" <|
            \_ ->
                parse "not a rule"
                    |> Expect.err
        , test "rejects empty string with Err" <|
            \_ ->
                parse ""
                    |> Expect.err
        ]


friendlyParseErrorTests : Test
friendlyParseErrorTests =
    describe "friendlyParseError"
        [ test "formats error with column info from dead ends" <|
            \_ ->
                case parse "invalid!!!" of
                    Err deadEnds ->
                        friendlyParseError deadEnds
                            |> String.contains "around character"
                            |> Expect.equal True

                    Ok _ ->
                        Expect.fail "Expected parse to fail"
        , test "formats error with empty dead ends list" <|
            \_ ->
                friendlyParseError []
                    |> String.contains "in the input"
                    |> Expect.equal True
        , test "includes tip about comma-separated rules" <|
            \_ ->
                friendlyParseError []
                    |> String.contains "Separate each rule with a comma"
                    |> Expect.equal True
        ]


selectableTokenTests : Test
selectableTokenTests =
    describe "selectable tokens"
        [ test "parses audio" <|
            \_ ->
                parse "+sel:audio"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "audio track" ] ] ])
        , test "parses subtitle" <|
            \_ ->
                parse "+sel:subtitle"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "subtitle track" ] ] ])
        , test "parses mvcvideo" <|
            \_ ->
                parse "+sel:mvcvideo"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "multi-angle (3D) video track" ] ] ])
        , test "parses favlang" <|
            \_ ->
                parse "+sel:favlang"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "favourite language" ] ] ])
        , test "parses nolang" <|
            \_ ->
                parse "+sel:nolang"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "tracks without a language set" ] ] ])
        , test "parses special" <|
            \_ ->
                parse "+sel:special"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "special (director's comment, etc.)" ] ] ])
        , test "parses forced" <|
            \_ ->
                parse "+sel:forced"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "forced subtitle" ] ] ])
        , test "parses mono" <|
            \_ ->
                parse "+sel:mono"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "mono audio" ] ] ])
        , test "parses stereo" <|
            \_ ->
                parse "+sel:stereo"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "stereo audio" ] ] ])
        , test "parses multi" <|
            \_ ->
                parse "+sel:multi"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "multi-channel audio" ] ] ])
        , test "parses havemulti" <|
            \_ ->
                parse "+sel:havemulti"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "mono/stereo when multi exists in same language" ] ] ])
        , test "parses lossy" <|
            \_ ->
                parse "+sel:lossy"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "lossy audio" ] ] ])
        , test "parses lossless" <|
            \_ ->
                parse "+sel:lossless"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "lossless audio" ] ] ])
        , test "parses havelossless" <|
            \_ ->
                parse "+sel:havelossless"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "lossy when lossless exists in same language" ] ] ])
        , test "parses core" <|
            \_ ->
                parse "+sel:core"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "core audio (part of HD track)" ] ] ])
        , test "parses havecore" <|
            \_ ->
                parse "+sel:havecore"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "HD track with core audio" ] ] ])
        , test "parses single" <|
            \_ ->
                parse "+sel:single"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "single audio track" ] ] ])
        , test "parses numeric N (ordinal track)" <|
            \_ ->
                parse "+sel:1"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 1st (or higher) track of same type and language" ] ] ])
        , test "parses numeric 2 (ordinal track)" <|
            \_ ->
                parse "+sel:2"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 2nd (or higher) track of same type and language" ] ] ])
        , test "parses numeric 3 (ordinal track)" <|
            \_ ->
                parse "+sel:3"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 3rd (or higher) track of same type and language" ] ] ])
        , test "parses numeric 4 (ordinal track)" <|
            \_ ->
                parse "+sel:4"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 4th (or higher) track of same type and language" ] ] ])
        , test "parses numeric 11 (ordinal track with th)" <|
            \_ ->
                parse "+sel:11"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 11th (or higher) track of same type and language" ] ] ])
        , test "parses numeric 12 (ordinal track with th)" <|
            \_ ->
                parse "+sel:12"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 12th (or higher) track of same type and language" ] ] ])
        , test "parses numeric 13 (ordinal track with th)" <|
            \_ ->
                parse "+sel:13"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 13th (or higher) track of same type and language" ] ] ])
        , test "parses numeric 21 (ordinal track with st)" <|
            \_ ->
                parse "+sel:21"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 21st (or higher) track of same type and language" ] ] ])
        , test "parses numeric 22 (ordinal track with nd)" <|
            \_ ->
                parse "+sel:22"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 22nd (or higher) track of same type and language" ] ] ])
        , test "parses numeric 23 (ordinal track with rd)" <|
            \_ ->
                parse "+sel:23"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 23rd (or higher) track of same type and language" ] ] ])
        , test "parses unknown 3-letter lowercase code as language" <|
            \_ ->
                parse "+sel:xyz"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "language: xyz" ] ] ])
        ]


languageCodeTests : Test
languageCodeTests =
    describe "language codes"
        [ test "parses eng" <|
            \_ ->
                parse "+sel:eng"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "English" ] ] ])
        , test "parses fra" <|
            \_ ->
                parse "+sel:fra"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "French" ] ] ])
        , test "parses deu" <|
            \_ ->
                parse "+sel:deu"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "German" ] ] ])
        , test "parses jpn" <|
            \_ ->
                parse "+sel:jpn"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Japanese" ] ] ])
        , test "parses spa" <|
            \_ ->
                parse "+sel:spa"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Spanish" ] ] ])
        , test "parses ara" <|
            \_ ->
                parse "+sel:ara"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Arabic" ] ] ])
        , test "parses ben" <|
            \_ ->
                parse "+sel:ben"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Bengali" ] ] ])
        , test "parses zho" <|
            \_ ->
                parse "+sel:zho"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Chinese" ] ] ])
        , test "parses yue" <|
            \_ ->
                parse "+sel:yue"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Cantonese" ] ] ])
        , test "parses nld" <|
            \_ ->
                parse "+sel:nld"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Dutch" ] ] ])
        , test "parses fin" <|
            \_ ->
                parse "+sel:fin"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Finnish" ] ] ])
        , test "parses guj" <|
            \_ ->
                parse "+sel:guj"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Gujarati" ] ] ])
        , test "parses hin" <|
            \_ ->
                parse "+sel:hin"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Hindi" ] ] ])
        , test "parses ita" <|
            \_ ->
                parse "+sel:ita"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Italian" ] ] ])
        , test "parses jav" <|
            \_ ->
                parse "+sel:jav"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Javanese" ] ] ])
        , test "parses kan" <|
            \_ ->
                parse "+sel:kan"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Kannada" ] ] ])
        , test "parses kor" <|
            \_ ->
                parse "+sel:kor"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Korean" ] ] ])
        , test "parses msa" <|
            \_ ->
                parse "+sel:msa"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Malay" ] ] ])
        , test "parses mal" <|
            \_ ->
                parse "+sel:mal"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Malayalam" ] ] ])
        , test "parses mar" <|
            \_ ->
                parse "+sel:mar"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Marathi" ] ] ])
        , test "parses fas" <|
            \_ ->
                parse "+sel:fas"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Persian" ] ] ])
        , test "parses pol" <|
            \_ ->
                parse "+sel:pol"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Polish" ] ] ])
        , test "parses por" <|
            \_ ->
                parse "+sel:por"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Portuguese" ] ] ])
        , test "parses pan" <|
            \_ ->
                parse "+sel:pan"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Punjabi" ] ] ])
        , test "parses ron" <|
            \_ ->
                parse "+sel:ron"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Romanian" ] ] ])
        , test "parses rus" <|
            \_ ->
                parse "+sel:rus"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Russian" ] ] ])
        , test "parses tam" <|
            \_ ->
                parse "+sel:tam"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Tamil" ] ] ])
        , test "parses tel" <|
            \_ ->
                parse "+sel:tel"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Telugu" ] ] ])
        , test "parses tur" <|
            \_ ->
                parse "+sel:tur"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Turkish" ] ] ])
        , test "parses ukr" <|
            \_ ->
                parse "+sel:ukr"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Ukrainian" ] ] ])
        , test "parses urd" <|
            \_ ->
                parse "+sel:urd"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Urdu" ] ] ])
        , test "parses vie" <|
            \_ ->
                parse "+sel:vie"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "Vietnamese" ] ] ])
        ]


weightTests : Test
weightTests =
    describe "weight operations"
        [ test "parses +5:all as increase weight" <|
            \_ ->
                parse "+5:all"
                    |> Result.map (List.map Tuple.first)
                    |> Expect.equal (Ok [ "increase weight by 5 for" ])
        , test "parses -3:all as decrease weight" <|
            \_ ->
                parse "-3:all"
                    |> Result.map (List.map Tuple.first)
                    |> Expect.equal (Ok [ "decrease weight by 3 for" ])
        , test "parses =10:all as set weight" <|
            \_ ->
                parse "=10:all"
                    |> Result.map (List.map Tuple.first)
                    |> Expect.equal (Ok [ "set weight to 10 for" ])
        , test "rejects + without number or sel" <|
            \_ ->
                parse "+:all"
                    |> Expect.err
        , test "rejects - without number or sel" <|
            \_ ->
                parse "-:all"
                    |> Expect.err
        ]


operatorTests : Test
operatorTests =
    describe "operators"
        [ test "parses ! (not) operator" <|
            \_ ->
                parse "+sel:!all"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Not (Prim "all tracks") ] ] ])
        , test "parses ~ (not) operator" <|
            \_ ->
                parse "+sel:~all"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Not (Prim "all tracks") ] ] ])
        , test "parses & (and) operator" <|
            \_ ->
                parse "+sel:audio&video"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal
                        (Ok
                            [ And
                                [ Or [ Prim "audio track" ]
                                , Or [ Prim "video track" ]
                                ]
                            ]
                        )
        , test "parses * (and) operator" <|
            \_ ->
                parse "+sel:audio*video"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal
                        (Ok
                            [ And
                                [ Or [ Prim "audio track" ]
                                , Or [ Prim "video track" ]
                                ]
                            ]
                        )
        , test "parses | (or) operator" <|
            \_ ->
                parse "+sel:audio|video"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal
                        (Ok
                            [ And
                                [ Or
                                    [ Prim "audio track"
                                    , Prim "video track"
                                    ]
                                ]
                            ]
                        )
        , test "parses nested parentheses" <|
            \_ ->
                parse "+sel:(audio|video)&favlang"
                    |> Expect.ok
        , test "parses double not" <|
            \_ ->
                parse "+sel:!!all"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Not (Not (Prim "all tracks")) ] ] ])
        , test "parses spaces around operators" <|
            \_ ->
                parse "+sel:audio | video"
                    |> Expect.ok
        , test "parses spaces in not" <|
            \_ ->
                parse "+sel:! all"
                    |> Expect.ok
        ]


ordinalTests : Test
ordinalTests =
    describe "ordinal suffixes via parse"
        [ test "1st" <|
            \_ ->
                parse "+sel:1"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 1st (or higher) track of same type and language" ] ] ])
        , test "2nd" <|
            \_ ->
                parse "+sel:2"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 2nd (or higher) track of same type and language" ] ] ])
        , test "3rd" <|
            \_ ->
                parse "+sel:3"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 3rd (or higher) track of same type and language" ] ] ])
        , test "4th" <|
            \_ ->
                parse "+sel:4"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 4th (or higher) track of same type and language" ] ] ])
        , test "11th (special teen)" <|
            \_ ->
                parse "+sel:11"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 11th (or higher) track of same type and language" ] ] ])
        , test "12th (special teen)" <|
            \_ ->
                parse "+sel:12"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 12th (or higher) track of same type and language" ] ] ])
        , test "13th (special teen)" <|
            \_ ->
                parse "+sel:13"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 13th (or higher) track of same type and language" ] ] ])
        , test "21st" <|
            \_ ->
                parse "+sel:21"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 21st (or higher) track of same type and language" ] ] ])
        , test "100th" <|
            \_ ->
                parse "+sel:100"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 100th (or higher) track of same type and language" ] ] ])
        , test "111th (special teen hundred)" <|
            \_ ->
                parse "+sel:111"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 111th (or higher) track of same type and language" ] ] ])
        , test "112th (special teen hundred)" <|
            \_ ->
                parse "+sel:112"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 112th (or higher) track of same type and language" ] ] ])
        , test "113th (special teen hundred)" <|
            \_ ->
                parse "+sel:113"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 113th (or higher) track of same type and language" ] ] ])
        , test "101st" <|
            \_ ->
                parse "+sel:101"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 101st (or higher) track of same type and language" ] ] ])
        , test "102nd" <|
            \_ ->
                parse "+sel:102"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 102nd (or higher) track of same type and language" ] ] ])
        , test "103rd" <|
            \_ ->
                parse "+sel:103"
                    |> Result.map (List.map Tuple.second)
                    |> Expect.equal (Ok [ And [ Or [ Prim "matches if 103rd (or higher) track of same type and language" ] ] ])
        ]


edgeCaseTests : Test
edgeCaseTests =
    describe "edge cases"
        [ test "parses complex real-world selection" <|
            \_ ->
                parse "-sel:all,+sel:((multi|stereo|mono)&favlang)"
                    |> Expect.ok
        , test "parses three rules" <|
            \_ ->
                parse "-sel:all,+sel:video,+sel:audio"
                    |> Result.map List.length
                    |> Expect.equal (Ok 3)
        , test "rejects trailing comma" <|
            \_ ->
                parse "-sel:all,"
                    |> Expect.err
        ]
