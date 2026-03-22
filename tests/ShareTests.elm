module ShareTests exposing (suite)

import Expect
import Share
    exposing
        ( actionToShort
        , decodeSelection
        , descToCode
        , encodeSelection
        , langNameToCode
        , takeShortToken
        )
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Share"
        [ encodeSelectionTests
        , decodeSelectionTests
        , roundTripTests
        , encodeAllTokenTests
        , decodeAllCodeTests
        , weightEncodingTests
        , conditionStructureTests
        , internalFunctionTests
        ]


encodeSelectionTests : Test
encodeSelectionTests =
    describe "encodeSelection"
        [ test "encodes -sel:all as M:((a))" <|
            \_ ->
                encodeSelection "-sel:all"
                    |> Expect.equal (Just "M:((a))")
        , test "encodes +sel:all as P:((a))" <|
            \_ ->
                encodeSelection "+sel:all"
                    |> Expect.equal (Just "P:((a))")
        , test "encodes +sel:(favlang|nolang) as P:((((f|n))))" <|
            \_ ->
                encodeSelection "+sel:(favlang|nolang)"
                    |> Expect.equal (Just "P:((((f|n))))")
        , test "returns Nothing for invalid input" <|
            \_ ->
                encodeSelection "not valid"
                    |> Expect.equal Nothing
        , test "returns Nothing for empty string" <|
            \_ ->
                encodeSelection ""
                    |> Expect.equal Nothing
        ]


decodeSelectionTests : Test
decodeSelectionTests =
    describe "decodeSelection"
        [ test "decodes M:((a)) to -sel:((all))" <|
            \_ ->
                decodeSelection "M:((a))"
                    |> Expect.equal (Ok "-sel:((all))")
        , test "decodes P:((a)) to +sel:((all))" <|
            \_ ->
                decodeSelection "P:((a))"
                    |> Expect.equal (Ok "+sel:((all))")
        , test "decodes P:(f|n) to +sel:(favlang|nolang)" <|
            \_ ->
                decodeSelection "P:(f|n)"
                    |> Expect.equal (Ok "+sel:(favlang|nolang)")
        , test "decodes multiple rules" <|
            \_ ->
                decodeSelection "M:((a)),P:(f|n)"
                    |> Expect.equal (Ok "-sel:((all)),+sel:(favlang|nolang)")
        , test "returns Err for invalid rule format" <|
            \_ ->
                decodeSelection "no-colon"
                    |> Expect.err
        , test "decodes empty string to Ok empty string" <|
            \_ ->
                decodeSelection ""
                    |> Expect.equal (Ok "")
        ]


roundTripTests : Test
roundTripTests =
    describe "encodeSelection round-trip with decodeSelection"
        [ test "encode then decode yields parseable selection string" <|
            \_ ->
                encodeSelection "-sel:all"
                    |> Maybe.andThen (decodeSelection >> Result.toMaybe)
                    |> Expect.notEqual Nothing
        , test "encode then decode for +sel:(favlang|nolang) yields parseable string" <|
            \_ ->
                encodeSelection "+sel:(favlang|nolang)"
                    |> Maybe.andThen (decodeSelection >> Result.toMaybe)
                    |> Expect.notEqual Nothing
        , test "encode then decode for weight operations" <|
            \_ ->
                encodeSelection "+5:all"
                    |> Maybe.andThen (decodeSelection >> Result.toMaybe)
                    |> Expect.notEqual Nothing
        , test "encode then decode for not condition" <|
            \_ ->
                encodeSelection "+sel:!audio"
                    |> Maybe.andThen (decodeSelection >> Result.toMaybe)
                    |> Expect.notEqual Nothing
        , test "encode then decode for and condition" <|
            \_ ->
                encodeSelection "+sel:audio&video"
                    |> Maybe.andThen (decodeSelection >> Result.toMaybe)
                    |> Expect.notEqual Nothing
        ]


encodeAllTokenTests : Test
encodeAllTokenTests =
    describe "encodeSelection covers all selectable tokens"
        [ test "encodes video" <|
            \_ ->
                encodeSelection "+sel:video"
                    |> Expect.equal (Just "P:((v))")
        , test "encodes audio" <|
            \_ ->
                encodeSelection "+sel:audio"
                    |> Expect.equal (Just "P:((u))")
        , test "encodes subtitle" <|
            \_ ->
                encodeSelection "+sel:subtitle"
                    |> Expect.equal (Just "P:((t))")
        , test "encodes mvcvideo" <|
            \_ ->
                encodeSelection "+sel:mvcvideo"
                    |> Expect.equal (Just "P:((3))")
        , test "encodes favlang" <|
            \_ ->
                encodeSelection "+sel:favlang"
                    |> Expect.equal (Just "P:((f))")
        , test "encodes nolang" <|
            \_ ->
                encodeSelection "+sel:nolang"
                    |> Expect.equal (Just "P:((n))")
        , test "encodes special" <|
            \_ ->
                encodeSelection "+sel:special"
                    |> Expect.equal (Just "P:((e))")
        , test "encodes forced" <|
            \_ ->
                encodeSelection "+sel:forced"
                    |> Expect.equal (Just "P:((o))")
        , test "encodes mono" <|
            \_ ->
                encodeSelection "+sel:mono"
                    |> Expect.equal (Just "P:((1))")
        , test "encodes stereo" <|
            \_ ->
                encodeSelection "+sel:stereo"
                    |> Expect.equal (Just "P:((2))")
        , test "encodes multi" <|
            \_ ->
                encodeSelection "+sel:multi"
                    |> Expect.equal (Just "P:((4))")
        , test "encodes havemulti" <|
            \_ ->
                encodeSelection "+sel:havemulti"
                    |> Expect.equal (Just "P:((h))")
        , test "encodes lossy" <|
            \_ ->
                encodeSelection "+sel:lossy"
                    |> Expect.equal (Just "P:((y))")
        , test "encodes lossless" <|
            \_ ->
                encodeSelection "+sel:lossless"
                    |> Expect.equal (Just "P:((l))")
        , test "encodes havelossless" <|
            \_ ->
                encodeSelection "+sel:havelossless"
                    |> Expect.equal (Just "P:((k))")
        , test "encodes core" <|
            \_ ->
                encodeSelection "+sel:core"
                    |> Expect.equal (Just "P:((c))")
        , test "encodes havecore" <|
            \_ ->
                encodeSelection "+sel:havecore"
                    |> Expect.equal (Just "P:((C))")
        , test "encodes single" <|
            \_ ->
                encodeSelection "+sel:single"
                    |> Expect.equal (Just "P:((5))")
        , test "encodes numeric track (ordinal)" <|
            \_ ->
                encodeSelection "+sel:5"
                    |> Expect.equal (Just "P:((65))")
        , test "encodes unknown 3-letter language" <|
            \_ ->
                encodeSelection "+sel:xyz"
                    |> Expect.equal (Just "P:((xyz))")
        , test "encodes eng" <|
            \_ ->
                encodeSelection "+sel:eng"
                    |> Expect.equal (Just "P:((eng))")
        , test "encodes fra" <|
            \_ ->
                encodeSelection "+sel:fra"
                    |> Expect.equal (Just "P:((fra))")
        , test "encodes deu" <|
            \_ ->
                encodeSelection "+sel:deu"
                    |> Expect.equal (Just "P:((deu))")
        , test "encodes jpn" <|
            \_ ->
                encodeSelection "+sel:jpn"
                    |> Expect.equal (Just "P:((jpn))")
        , test "encodes spa" <|
            \_ ->
                encodeSelection "+sel:spa"
                    |> Expect.equal (Just "P:((spa))")
        , test "encodes ara" <|
            \_ ->
                encodeSelection "+sel:ara"
                    |> Expect.equal (Just "P:((ara))")
        , test "encodes ben" <|
            \_ ->
                encodeSelection "+sel:ben"
                    |> Expect.equal (Just "P:((ben))")
        , test "encodes zho" <|
            \_ ->
                encodeSelection "+sel:zho"
                    |> Expect.equal (Just "P:((zho))")
        , test "encodes yue" <|
            \_ ->
                encodeSelection "+sel:yue"
                    |> Expect.equal (Just "P:((yue))")
        , test "encodes nld" <|
            \_ ->
                encodeSelection "+sel:nld"
                    |> Expect.equal (Just "P:((nld))")
        , test "encodes fin" <|
            \_ ->
                encodeSelection "+sel:fin"
                    |> Expect.equal (Just "P:((fin))")
        , test "encodes guj" <|
            \_ ->
                encodeSelection "+sel:guj"
                    |> Expect.equal (Just "P:((guj))")
        , test "encodes hin" <|
            \_ ->
                encodeSelection "+sel:hin"
                    |> Expect.equal (Just "P:((hin))")
        , test "encodes ita" <|
            \_ ->
                encodeSelection "+sel:ita"
                    |> Expect.equal (Just "P:((ita))")
        , test "encodes jav" <|
            \_ ->
                encodeSelection "+sel:jav"
                    |> Expect.equal (Just "P:((jav))")
        , test "encodes kan" <|
            \_ ->
                encodeSelection "+sel:kan"
                    |> Expect.equal (Just "P:((kan))")
        , test "encodes kor" <|
            \_ ->
                encodeSelection "+sel:kor"
                    |> Expect.equal (Just "P:((kor))")
        , test "encodes msa" <|
            \_ ->
                encodeSelection "+sel:msa"
                    |> Expect.equal (Just "P:((msa))")
        , test "encodes mal" <|
            \_ ->
                encodeSelection "+sel:mal"
                    |> Expect.equal (Just "P:((mal))")
        , test "encodes mar" <|
            \_ ->
                encodeSelection "+sel:mar"
                    |> Expect.equal (Just "P:((mar))")
        , test "encodes fas" <|
            \_ ->
                encodeSelection "+sel:fas"
                    |> Expect.equal (Just "P:((fas))")
        , test "encodes pol" <|
            \_ ->
                encodeSelection "+sel:pol"
                    |> Expect.equal (Just "P:((pol))")
        , test "encodes por" <|
            \_ ->
                encodeSelection "+sel:por"
                    |> Expect.equal (Just "P:((por))")
        , test "encodes pan" <|
            \_ ->
                encodeSelection "+sel:pan"
                    |> Expect.equal (Just "P:((pan))")
        , test "encodes ron" <|
            \_ ->
                encodeSelection "+sel:ron"
                    |> Expect.equal (Just "P:((ron))")
        , test "encodes rus" <|
            \_ ->
                encodeSelection "+sel:rus"
                    |> Expect.equal (Just "P:((rus))")
        , test "encodes tam" <|
            \_ ->
                encodeSelection "+sel:tam"
                    |> Expect.equal (Just "P:((tam))")
        , test "encodes tel" <|
            \_ ->
                encodeSelection "+sel:tel"
                    |> Expect.equal (Just "P:((tel))")
        , test "encodes tur" <|
            \_ ->
                encodeSelection "+sel:tur"
                    |> Expect.equal (Just "P:((tur))")
        , test "encodes ukr" <|
            \_ ->
                encodeSelection "+sel:ukr"
                    |> Expect.equal (Just "P:((ukr))")
        , test "encodes urd" <|
            \_ ->
                encodeSelection "+sel:urd"
                    |> Expect.equal (Just "P:((urd))")
        , test "encodes vie" <|
            \_ ->
                encodeSelection "+sel:vie"
                    |> Expect.equal (Just "P:((vie))")
        ]


decodeAllCodeTests : Test
decodeAllCodeTests =
    describe "decodeSelection covers all short codes"
        [ test "decodes v to video" <|
            \_ ->
                decodeSelection "P:v"
                    |> Expect.equal (Ok "+sel:video")
        , test "decodes u to audio" <|
            \_ ->
                decodeSelection "P:u"
                    |> Expect.equal (Ok "+sel:audio")
        , test "decodes t to subtitle" <|
            \_ ->
                decodeSelection "P:t"
                    |> Expect.equal (Ok "+sel:subtitle")
        , test "decodes 3 to mvcvideo" <|
            \_ ->
                decodeSelection "P:3"
                    |> Expect.equal (Ok "+sel:mvcvideo")
        , test "decodes f to favlang" <|
            \_ ->
                decodeSelection "P:f"
                    |> Expect.equal (Ok "+sel:favlang")
        , test "decodes n to nolang" <|
            \_ ->
                decodeSelection "P:n"
                    |> Expect.equal (Ok "+sel:nolang")
        , test "decodes e to special" <|
            \_ ->
                decodeSelection "P:e"
                    |> Expect.equal (Ok "+sel:special")
        , test "decodes o to forced" <|
            \_ ->
                decodeSelection "P:o"
                    |> Expect.equal (Ok "+sel:forced")
        , test "decodes 1 to mono" <|
            \_ ->
                decodeSelection "P:1"
                    |> Expect.equal (Ok "+sel:mono")
        , test "decodes 2 to stereo" <|
            \_ ->
                decodeSelection "P:2"
                    |> Expect.equal (Ok "+sel:stereo")
        , test "decodes 4 to multi" <|
            \_ ->
                decodeSelection "P:4"
                    |> Expect.equal (Ok "+sel:multi")
        , test "decodes h to havemulti" <|
            \_ ->
                decodeSelection "P:h"
                    |> Expect.equal (Ok "+sel:havemulti")
        , test "decodes y to lossy" <|
            \_ ->
                decodeSelection "P:y"
                    |> Expect.equal (Ok "+sel:lossy")
        , test "decodes l to lossless" <|
            \_ ->
                decodeSelection "P:l"
                    |> Expect.equal (Ok "+sel:lossless")
        , test "decodes k to havelossless" <|
            \_ ->
                decodeSelection "P:k"
                    |> Expect.equal (Ok "+sel:havelossless")
        , test "decodes c to core" <|
            \_ ->
                decodeSelection "P:c"
                    |> Expect.equal (Ok "+sel:core")
        , test "decodes C to havecore" <|
            \_ ->
                decodeSelection "P:C"
                    |> Expect.equal (Ok "+sel:havecore")
        , test "decodes 5 to single" <|
            \_ ->
                decodeSelection "P:5"
                    |> Expect.equal (Ok "+sel:single")
        , test "decodes 3-letter lowercase as language code" <|
            \_ ->
                decodeSelection "P:eng"
                    |> Expect.equal (Ok "+sel:eng")
        , test "decodes 6N as ordinal track number" <|
            \_ ->
                decodeSelection "P:65"
                    |> Expect.equal (Ok "+sel:5")
        , test "decodes unknown single code as all" <|
            \_ ->
                decodeSelection "P:Z"
                    |> Expect.equal (Ok "+sel:all")
        , test "decodes not condition" <|
            \_ ->
                decodeSelection "P:!a"
                    |> Expect.equal (Ok "+sel:!all")
        , test "decodes or condition" <|
            \_ ->
                decodeSelection "P:(a|v)"
                    |> Expect.equal (Ok "+sel:(all|video)")
        , test "decodes and condition" <|
            \_ ->
                decodeSelection "P:(a&v)"
                    |> Expect.equal (Ok "+sel:(all&video)")
        , test "decodes nested parentheses" <|
            \_ ->
                decodeSelection "P:((a|v)&f)"
                    |> Expect.equal (Ok "+sel:((all|video)&favlang)")
        , test "decodes empty condition" <|
            \_ ->
                decodeSelection "P:"
                    |> Expect.equal (Ok "+sel:")
        ]


weightEncodingTests : Test
weightEncodingTests =
    describe "weight encoding/decoding"
        [ test "encodes +5:all with increase weight" <|
            \_ ->
                encodeSelection "+5:all"
                    |> Expect.equal (Just "I5:((a))")
        , test "encodes -3:all with decrease weight" <|
            \_ ->
                encodeSelection "-3:all"
                    |> Expect.equal (Just "D3:((a))")
        , test "encodes =10:all with set weight" <|
            \_ ->
                encodeSelection "=10:all"
                    |> Expect.equal (Just "S10:((a))")
        , test "decodes S10 to =10" <|
            \_ ->
                decodeSelection "S10:a"
                    |> Expect.equal (Ok "=10:all")
        , test "decodes D3 to -3" <|
            \_ ->
                decodeSelection "D3:a"
                    |> Expect.equal (Ok "-3:all")
        , test "decodes I5 to +5" <|
            \_ ->
                decodeSelection "I5:a"
                    |> Expect.equal (Ok "+5:all")
        , test "decodes unknown action prefix as +sel" <|
            \_ ->
                decodeSelection "X:a"
                    |> Expect.equal (Ok "+sel:all")
        ]


conditionStructureTests : Test
conditionStructureTests =
    describe "condition structures"
        [ test "encodes not condition" <|
            \_ ->
                encodeSelection "+sel:!audio"
                    |> Expect.equal (Just "P:((!u))")
        , test "encodes and condition" <|
            \_ ->
                encodeSelection "+sel:audio&video"
                    |> Expect.equal (Just "P:((u)&(v))")
        , test "encodes or condition" <|
            \_ ->
                encodeSelection "+sel:audio|video"
                    |> Expect.equal (Just "P:((u|v))")
        , test "encodes multiple rules" <|
            \_ ->
                encodeSelection "-sel:all,+sel:subtitle"
                    |> Expect.equal (Just "M:((a)),P:((t))")
        , test "encodes complex nested condition" <|
            \_ ->
                encodeSelection "+sel:(audio|video)&favlang"
                    |> Expect.notEqual Nothing
        , test "decodes closing paren handled correctly" <|
            \_ ->
                decodeSelection "P:(a)"
                    |> Expect.equal (Ok "+sel:(all)")
        , test "encodes double not" <|
            \_ ->
                encodeSelection "+sel:!!audio"
                    |> Expect.equal (Just "P:((!!u))")
        , test "decodes empty parens" <|
            \_ ->
                decodeSelection "P:()"
                    |> Expect.equal (Ok "+sel:()")
        , test "decodes nested parens in shortCondToLong" <|
            \_ ->
                decodeSelection "P:((a&v)|f)"
                    |> Expect.equal (Ok "+sel:((all&video)|favlang)")
        , test "decodes short condition with closing paren at start" <|
            \_ ->
                -- shortCondToLong handles ')' by returning ""
                decodeSelection "P:(a)"
                    |> Expect.ok
        , test "decodes uppercase non-single code character" <|
            \_ ->
                -- takeShortToken with uppercase char not in singleCodes
                decodeSelection "P:Z"
                    |> Expect.equal (Ok "+sel:all")
        , test "decodes 6 without following digits" <|
            \_ ->
                -- takeShortToken '6' path with no trailing digits
                decodeSelection "P:6"
                    |> Expect.equal (Ok "+sel:all")
        , test "decodes 6 with multi-digit number" <|
            \_ ->
                decodeSelection "P:612"
                    |> Expect.equal (Ok "+sel:12")
        , test "decodes single code followed by more" <|
            \_ ->
                decodeSelection "P:av"
                    |> Expect.equal (Ok "+sel:allvideo")
        , test "decodes less than 3 lowercase chars falls through" <|
            \_ ->
                -- Short lowercase string that's < 3 chars
                decodeSelection "P:ab"
                    |> Expect.ok
        , test "decodes multiple colons returns Err" <|
            \_ ->
                decodeSelection "P:a:b"
                    |> Expect.err
        , test "decodes unclosed paren" <|
            \_ ->
                decodeSelection "P:("
                    |> Expect.equal (Ok "+sel:()")
        , test "decodes trailing closing paren in shortCondToLong" <|
            \_ ->
                -- After takeShortToken consumes "a", rest is ")" which hits the ')' branch
                decodeSelection "P:a)"
                    |> Expect.equal (Ok "+sel:all")
        , test "decodes lowercase char not in singleCodes with length < 3" <|
            \_ ->
                -- 'b' is not in singleCodes, string "b" is < 3 chars
                decodeSelection "P:b"
                    |> Expect.equal (Ok "+sel:all")
        , test "decodes short condition with nested unclosed parens" <|
            \_ ->
                decodeSelection "P:((a"
                    |> Expect.equal (Ok "+sel:((all))")
        ]


internalFunctionTests : Test
internalFunctionTests =
    describe "internal functions"
        [ test "takeShortToken with empty string returns empty pair" <|
            \_ ->
                takeShortToken ""
                    |> Expect.equal ( "", "" )
        , test "actionToShort with unknown action falls back to P" <|
            \_ ->
                actionToShort "unknown action"
                    |> Expect.equal "P"
        , test "langNameToCode with unknown name falls back to a" <|
            \_ ->
                langNameToCode "UnknownLanguage"
                    |> Expect.equal "a"
        , test "descToCode with unknown description calls langNameToCode" <|
            \_ ->
                descToCode "UnknownDescription"
                    |> Expect.equal "a"
        , test "descToCode with 3-letter lowercase returns it directly" <|
            \_ ->
                descToCode "xyz"
                    |> Expect.equal "xyz"
        ]
