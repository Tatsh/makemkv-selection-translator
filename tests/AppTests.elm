module AppTests exposing (suite)

import App exposing (Flags, Model, Msg(..), flagsDecoder, init, subscriptions, update)
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "App"
        [ flagsDecoderTests
        , initTests
        , updateTests
        , subscriptionsTests
        ]


flagsDecoderTests : Test
flagsDecoderTests =
    describe "flagsDecoder"
        [ test "decodes all fields" <|
            \_ ->
                let
                    json =
                        Encode.object
                            [ ( "syntaxRefOpen", Encode.bool True )
                            , ( "savedSelection", Encode.string "-sel:all" )
                            , ( "shareParam", Encode.string "+sel:video" )
                            ]
                in
                Decode.decodeValue flagsDecoder json
                    |> Expect.equal
                        (Ok
                            { syntaxRefOpen = True
                            , savedSelection = Just "-sel:all"
                            , shareParam = Just "+sel:video"
                            }
                        )
        , test "decodes with null savedSelection" <|
            \_ ->
                let
                    json =
                        Encode.object
                            [ ( "syntaxRefOpen", Encode.bool False )
                            , ( "savedSelection", Encode.null )
                            , ( "shareParam", Encode.null )
                            ]
                in
                Decode.decodeValue flagsDecoder json
                    |> Expect.equal
                        (Ok
                            { syntaxRefOpen = False
                            , savedSelection = Nothing
                            , shareParam = Nothing
                            }
                        )
        , test "decodes with missing optional fields" <|
            \_ ->
                let
                    json =
                        Encode.object
                            [ ( "syntaxRefOpen", Encode.bool False )
                            ]
                in
                Decode.decodeValue flagsDecoder json
                    |> Expect.equal
                        (Ok
                            { syntaxRefOpen = False
                            , savedSelection = Nothing
                            , shareParam = Nothing
                            }
                        )
        , test "fails for missing syntaxRefOpen" <|
            \_ ->
                Decode.decodeValue flagsDecoder (Encode.object [])
                    |> Expect.err
        ]


initTests : Test
initTests =
    describe "init"
        [ test "initialises with valid flags" <|
            \_ ->
                let
                    json =
                        Encode.object
                            [ ( "syntaxRefOpen", Encode.bool True )
                            , ( "savedSelection", Encode.string "-sel:all" )
                            ]

                    ( model, _ ) =
                        init json
                in
                Expect.all
                    [ \m -> m.selectionStr |> Expect.equal "-sel:all"
                    , \m -> m.syntaxRefOpen |> Expect.equal True
                    , \m -> m.translationResult |> Expect.ok
                    ]
                    model
        , test "shareParam takes priority over savedSelection" <|
            \_ ->
                let
                    json =
                        Encode.object
                            [ ( "syntaxRefOpen", Encode.bool False )
                            , ( "savedSelection", Encode.string "-sel:all" )
                            , ( "shareParam", Encode.string "+sel:video" )
                            ]

                    ( model, _ ) =
                        init json
                in
                model.selectionStr
                    |> Expect.equal "+sel:video"
        , test "uses savedSelection when shareParam is null" <|
            \_ ->
                let
                    json =
                        Encode.object
                            [ ( "syntaxRefOpen", Encode.bool False )
                            , ( "savedSelection", Encode.string "-sel:all" )
                            , ( "shareParam", Encode.null )
                            ]

                    ( model, _ ) =
                        init json
                in
                model.selectionStr
                    |> Expect.equal "-sel:all"
        , test "uses empty string when both optional fields missing" <|
            \_ ->
                let
                    json =
                        Encode.object
                            [ ( "syntaxRefOpen", Encode.bool False )
                            ]

                    ( model, _ ) =
                        init json
                in
                model.selectionStr
                    |> Expect.equal ""
        , test "falls back to default for invalid flags" <|
            \_ ->
                let
                    ( model, _ ) =
                        init Encode.null
                in
                Expect.all
                    [ \m -> m.selectionStr |> Expect.equal ""
                    , \m -> m.syntaxRefOpen |> Expect.equal False
                    , \m -> m.translationResult |> Expect.equal (Ok [])
                    ]
                    model
        , test "handles empty savedSelection with Nothing shareParam" <|
            \_ ->
                let
                    json =
                        Encode.object
                            [ ( "syntaxRefOpen", Encode.bool False )
                            , ( "savedSelection", Encode.null )
                            ]

                    ( model, _ ) =
                        init json
                in
                model.selectionStr
                    |> Expect.equal ""
        ]


updateTests : Test
updateTests =
    describe "update"
        [ test "SelectionStr updates model with valid selection" <|
            \_ ->
                let
                    model =
                        { selectionStr = ""
                        , translationResult = Ok []
                        , syntaxRefOpen = False
                        }

                    ( newModel, _ ) =
                        update (SelectionStr "-sel:all") model
                in
                Expect.all
                    [ \m -> m.selectionStr |> Expect.equal "-sel:all"
                    , \m -> m.translationResult |> Expect.ok
                    ]
                    newModel
        , test "SelectionStr updates model with invalid selection" <|
            \_ ->
                let
                    model =
                        { selectionStr = ""
                        , translationResult = Ok []
                        , syntaxRefOpen = False
                        }

                    ( newModel, _ ) =
                        update (SelectionStr "invalid!!!") model
                in
                Expect.all
                    [ \m -> m.selectionStr |> Expect.equal "invalid!!!"
                    , \m -> m.translationResult |> Expect.err
                    ]
                    newModel
        , test "ToggleSyntaxRef flips syntaxRefOpen" <|
            \_ ->
                let
                    model =
                        { selectionStr = ""
                        , translationResult = Ok []
                        , syntaxRefOpen = False
                        }

                    ( newModel, _ ) =
                        update ToggleSyntaxRef model
                in
                newModel.syntaxRefOpen
                    |> Expect.equal True
        , test "ToggleSyntaxRef flips back to False" <|
            \_ ->
                let
                    model =
                        { selectionStr = ""
                        , translationResult = Ok []
                        , syntaxRefOpen = True
                        }

                    ( newModel, _ ) =
                        update ToggleSyntaxRef model
                in
                newModel.syntaxRefOpen
                    |> Expect.equal False
        , test "AppendToSelection appends to existing selection" <|
            \_ ->
                let
                    model =
                        { selectionStr = "-sel:"
                        , translationResult = Ok []
                        , syntaxRefOpen = False
                        }

                    ( newModel, _ ) =
                        update (AppendToSelection "all") model
                in
                newModel.selectionStr
                    |> Expect.equal "-sel:all"
        , test "AppendToSelection with invalid result" <|
            \_ ->
                let
                    model =
                        { selectionStr = "invalid"
                        , translationResult = Ok []
                        , syntaxRefOpen = False
                        }

                    ( newModel, _ ) =
                        update (AppendToSelection "!!!") model
                in
                newModel.translationResult
                    |> Expect.err
        , test "ShareClicked preserves model" <|
            \_ ->
                let
                    model =
                        { selectionStr = "-sel:all"
                        , translationResult = Ok []
                        , syntaxRefOpen = False
                        }

                    ( newModel, _ ) =
                        update ShareClicked model
                in
                newModel
                    |> Expect.equal model
        ]


subscriptionsTests : Test
subscriptionsTests =
    describe "subscriptions"
        [ test "returns Sub.none" <|
            \_ ->
                let
                    model =
                        { selectionStr = ""
                        , translationResult = Ok []
                        , syntaxRefOpen = False
                        }
                in
                subscriptions model
                    |> Expect.equal Sub.none
        ]
