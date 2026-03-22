module MainViewTests exposing (suite)

import App exposing (Model)
import Expect
import MainView exposing (syntaxReference, tok, tokClickable, view, viewInput)
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "MainView"
        [ tokTests
        , tokClickableTests
        , syntaxReferenceTests
        , viewTests
        , viewInputTests
        ]


tokTests : Test
tokTests =
    describe "tok"
        [ test "renders code element with syntax-tok class" <|
            \_ ->
                tok "+sel"
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "code"
                        , Selector.class "syntax-tok"
                        , Selector.text "+sel"
                        ]
        ]


tokClickableTests : Test
tokClickableTests =
    describe "tokClickable"
        [ test "renders code element with clickable class" <|
            \_ ->
                tokClickable "all"
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "code"
                        , Selector.class "syntax-tok-clickable"
                        , Selector.text "all"
                        ]
        ]


syntaxReferenceTests : Test
syntaxReferenceTests =
    describe "syntaxReference"
        [ test "renders with open indicator when isOpen is True" <|
            \_ ->
                syntaxReference True
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "▾ " ]
        , test "renders with closed indicator when isOpen is False" <|
            \_ ->
                syntaxReference False
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "▸ " ]
        ]


viewTests : Test
viewTests =
    describe "view"
        [ test "renders with valid model" <|
            \_ ->
                let
                    model : Model
                    model =
                        { selectionStr = "-sel:all"
                        , translationResult = Ok []
                        , syntaxRefOpen = False
                        }
                in
                view model
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "translation-output" ]
        , test "renders with error result (is-invalid class on input)" <|
            \_ ->
                let
                    model : Model
                    model =
                        { selectionStr = "invalid"
                        , translationResult = Err "some error"
                        , syntaxRefOpen = False
                        }
                in
                view model
                    |> Query.fromHtml
                    |> Query.find [ Selector.id "selection-input" ]
                    |> Query.has [ Selector.class "is-invalid" ]
        , test "renders without is-invalid class on success" <|
            \_ ->
                let
                    model : Model
                    model =
                        { selectionStr = ""
                        , translationResult = Ok []
                        , syntaxRefOpen = False
                        }
                in
                view model
                    |> Query.fromHtml
                    |> Query.find [ Selector.id "selection-input" ]
                    |> Query.hasNot [ Selector.class "is-invalid" ]
        ]


viewInputTests : Test
viewInputTests =
    describe "viewInput"
        [ test "renders input with given attributes" <|
            \_ ->
                viewInput "text" "placeholder" "value" False identity
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "input"
                        , Selector.id "selection-input"
                        , Selector.class "form-control"
                        ]
        , test "renders input with is-invalid when hasError is True" <|
            \_ ->
                viewInput "text" "placeholder" "value" True identity
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "is-invalid" ]
        , test "renders input without is-invalid when hasError is False" <|
            \_ ->
                viewInput "text" "placeholder" "value" False identity
                    |> Query.fromHtml
                    |> Query.hasNot [ Selector.class "is-invalid" ]
        ]
