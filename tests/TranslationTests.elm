module TranslationTests exposing (suite)

import Expect
import Html
import MakeMkvSelectionParser exposing (Conditional(..))
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Translation exposing (capitalize, conditionRendersAsListing, parseResult, viewConditional, viewRule, viewTranslation)


suite : Test
suite =
    describe "Translation"
        [ capitalizeTests
        , conditionRendersAsListingTests
        , parseResultTests
        , viewTranslationTests
        , viewRuleTests
        , viewConditionalTests
        ]


capitalizeTests : Test
capitalizeTests =
    describe "capitalize"
        [ test "uppercases first character of non-empty string" <|
            \_ ->
                capitalize "select"
                    |> Expect.equal "Select"
        , test "returns empty string unchanged" <|
            \_ ->
                capitalize ""
                    |> Expect.equal ""
        , test "handles single character" <|
            \_ ->
                capitalize "a"
                    |> Expect.equal "A"
        , test "handles already capitalised" <|
            \_ ->
                capitalize "Select"
                    |> Expect.equal "Select"
        ]


conditionRendersAsListingTests : Test
conditionRendersAsListingTests =
    describe "conditionRendersAsListing"
        [ test "Prim is not a listing" <|
            \_ ->
                conditionRendersAsListing (Prim "all tracks")
                    |> Expect.equal False
        , test "Or with multiple items is a listing" <|
            \_ ->
                conditionRendersAsListing
                    (Or [ Prim "favourite language", Prim "tracks without a language set" ])
                    |> Expect.equal True
        , test "And with multiple items is a listing" <|
            \_ ->
                conditionRendersAsListing
                    (And [ Prim "video track", Prim "audio track" ])
                    |> Expect.equal True
        , test "Or with single item is not a listing when inner is Prim" <|
            \_ ->
                conditionRendersAsListing (Or [ Prim "all tracks" ])
                    |> Expect.equal False
        , test "Not of Prim is not a listing" <|
            \_ ->
                conditionRendersAsListing (Not (Prim "forced subtitle"))
                    |> Expect.equal False
        , test "Not of Or with multiple items is a listing" <|
            \_ ->
                conditionRendersAsListing
                    (Not (Or [ Prim "favlang", Prim "nolang" ]))
                    |> Expect.equal True
        , test "And with single item delegates to inner" <|
            \_ ->
                conditionRendersAsListing (And [ Prim "all tracks" ])
                    |> Expect.equal False
        , test "And with single item that is Or with multiple is a listing" <|
            \_ ->
                conditionRendersAsListing
                    (And [ Or [ Prim "a", Prim "b" ] ])
                    |> Expect.equal True
        , test "Or with single item that is And with multiple is a listing" <|
            \_ ->
                conditionRendersAsListing
                    (Or [ And [ Prim "a", Prim "b" ] ])
                    |> Expect.equal True
        , test "Or with empty list is not a listing" <|
            \_ ->
                conditionRendersAsListing (Or [])
                    |> Expect.equal False
        , test "And with empty list is not a listing" <|
            \_ ->
                conditionRendersAsListing (And [])
                    |> Expect.equal False
        , test "Not of Not of Prim is not a listing" <|
            \_ ->
                conditionRendersAsListing (Not (Not (Prim "all")))
                    |> Expect.equal False
        ]


parseResultTests : Test
parseResultTests =
    describe "parseResult"
        [ test "returns Ok empty list for empty string" <|
            \_ ->
                parseResult ""
                    |> Expect.equal (Ok [])
        , test "returns Ok list for valid selection" <|
            \_ ->
                parseResult "-sel:all"
                    |> Expect.ok
        , test "returns Err with friendly message for invalid input" <|
            \_ ->
                case parseResult "invalid!!!" of
                    Err msg ->
                        msg
                            |> String.contains "Invalid selection"
                            |> Expect.equal True

                    Ok _ ->
                        Expect.fail "Expected parse to fail"
        , test "returns Ok for valid multi-rule" <|
            \_ ->
                parseResult "-sel:all,+sel:subtitle"
                    |> Result.map List.length
                    |> Expect.equal (Ok 2)
        ]


viewTranslationTests : Test
viewTranslationTests =
    describe "viewTranslation"
        [ test "renders error message for Err" <|
            \_ ->
                viewTranslation (Err "some error")
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "some error" ]
        , test "renders empty for Ok []" <|
            \_ ->
                viewTranslation (Ok [])
                    |> Query.fromHtml
                    |> Query.has []
        , test "renders list for Ok items" <|
            \_ ->
                viewTranslation (Ok [ ( "select", Prim "all tracks" ) ])
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "ul" ]
        , test "renders multiple items" <|
            \_ ->
                viewTranslation
                    (Ok
                        [ ( "select", Prim "all tracks" )
                        , ( "unselect", Prim "video track" )
                        ]
                    )
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "li" ]
                    |> Query.count (Expect.equal 2)
        ]


viewRuleTests : Test
viewRuleTests =
    describe "viewRule"
        [ test "renders action capitalised with Prim condition and period" <|
            \_ ->
                viewRule "select" (Prim "all tracks")
                    |> Html.div []
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Select ", Selector.text "all tracks", Selector.text "." ]
        , test "renders without period when condition is a listing (Or multiple)" <|
            \_ ->
                viewRule "select" (Or [ Prim "a", Prim "b" ])
                    |> Html.div []
                    |> Query.fromHtml
                    |> Query.hasNot [ Selector.text "." ]
        , test "renders without period when condition is a listing (And multiple)" <|
            \_ ->
                viewRule "unselect" (And [ Prim "a", Prim "b" ])
                    |> Html.div []
                    |> Query.fromHtml
                    |> Query.hasNot [ Selector.text "." ]
        ]


viewConditionalTests : Test
viewConditionalTests =
    describe "viewConditional"
        [ test "renders Prim as text" <|
            \_ ->
                viewConditional (Prim "all tracks")
                    |> Html.div []
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "all tracks" ]
        , test "renders Not with 'not' prefix and span" <|
            \_ ->
                viewConditional (Not (Prim "forced subtitle"))
                    |> Html.div []
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "not ", Selector.text "forced subtitle" ]
        , test "renders Or with single item as that item" <|
            \_ ->
                viewConditional (Or [ Prim "audio track" ])
                    |> Html.div []
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "audio track" ]
        , test "renders Or with multiple items as list with or bullets" <|
            \_ ->
                viewConditional (Or [ Prim "a", Prim "b" ])
                    |> Html.div []
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "cond-bullet-or" ]
        , test "renders And with single item as that item" <|
            \_ ->
                viewConditional (And [ Prim "video track" ])
                    |> Html.div []
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "video track" ]
        , test "renders And with multiple items as list with and bullets" <|
            \_ ->
                viewConditional (And [ Prim "a", Prim "b" ])
                    |> Html.div []
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "cond-bullet-and" ]
        , test "renders nested Not of Or" <|
            \_ ->
                viewConditional (Not (Or [ Prim "a", Prim "b" ]))
                    |> Html.div []
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "not ", Selector.class "cond-bullet-or" ]
        , test "renders Or with empty list as list" <|
            \_ ->
                viewConditional (Or [])
                    |> Html.div []
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "cond-bullet-or" ]
        , test "renders And with empty list as list" <|
            \_ ->
                viewConditional (And [])
                    |> Html.div []
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "cond-bullet-and" ]
        ]
