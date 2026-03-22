module MainView exposing (syntaxReference, tok, tokClickable, view, viewInput)

import App exposing (Model, Msg(..))
import Html exposing (Html, button, code, div, h6, input, li, text, ul)
import Html.Attributes exposing (class, classList, id, placeholder, type_, value)
import Html.Events exposing (onClick, onInput)
import Translation


tok : String -> Html msg
tok s =
  code [ class "syntax-tok" ] [ text s ]

tokClickable : String -> Html Msg
tokClickable s =
  code
    [ class "syntax-tok syntax-tok-clickable"
    , onClick (AppendToSelection s)
    ]
    [ text s ]

syntaxReference : Bool -> Html Msg
syntaxReference isOpen =
  div [ class "syntax-reference mb-3 border rounded overflow-hidden" ]
    [ div
        [ class "syntax-reference-summary px-3 py-2 bg-body-tertiary user-select-none"
        , onClick ToggleSyntaxRef
        ]
        [ text (if isOpen then "▾ " else "▸ ") , text "Syntax reference" ]
    , div
        [ class "syntax-ref-body px-3 py-2 small"
        , classList [ ( "d-none", not isOpen ) ]
        ]
        [ h6 [ class "syntax-ref-heading mb-2 mt-0" ] [ text "Actions" ]
        , ul [ class "mb-3 ps-3" ]
            [ li [] [ tokClickable "+sel", text " — select" ]
            , li [] [ tokClickable "-sel", text " — unselect" ]
            , li []
                [ tokClickable "+N"
                , text " / "
                , tokClickable "-N"
                , text " / "
                , tokClickable "=N"
                , text " — add / subtract / set weight"
                ]
            ]
        , h6 [ class "syntax-ref-heading mb-2 mt-0" ] [ text "Operators" ]
        , ul [ class "mb-3 ps-3" ]
            [ li [] [ tokClickable "|", text " — or" ]
            , li [] [ tokClickable "&", text " / ", tokClickable "*", text " — and" ]
            , li [] [ tokClickable "!", text " / ", tokClickable "~", text " — not" ]
            ]
        , h6 [ class "syntax-ref-heading mb-2 mt-0" ] [ text "Condition tokens" ]
        , ul [ class "mb-0 ps-3" ]
            [ li []
                [ tokClickable "all"
                , text " "
                , tokClickable "video"
                , text " "
                , tokClickable "audio"
                , text " "
                , tokClickable "subtitle"
                , text " "
                , tokClickable "mvcvideo"
                , text " "
                , tokClickable "favlang"
                , text " "
                , tokClickable "nolang"
                , text " "
                , tokClickable "special"
                , text " "
                , tokClickable "forced"
                ]
            , li []
                [ tokClickable "mono"
                , text " "
                , tokClickable "stereo"
                , text " "
                , tokClickable "multi"
                , text " "
                , tokClickable "havemulti"
                , text " "
                , tokClickable "lossy"
                , text " "
                , tokClickable "lossless"
                , text " "
                , tokClickable "havelossless"
                , text " "
                , tokClickable "core"
                , text " "
                , tokClickable "havecore"
                , text " "
                , tokClickable "single"
                ]
            , li [] [ tokClickable "N", text " — nth track of same type and language" ]
            , li []
                [ tokClickable "YYY"
                , text " — 3-letter language code (e.g. "
                , tokClickable "eng"
                , text " "
                , tokClickable "fra"
                , text ")"
                ]
            ]
        ]
    ]

view : Model -> Html Msg
view model =
  div
    []
    [ syntaxReference model.syntaxRefOpen
    , div [ class "mb-3" ]
        [ div [ class "input-group" ]
            [ viewInput
                "text"
                "-sel:all,+sel:((multi|stereo|mono)&favlang),..."
                model.selectionStr
                (case model.translationResult of
                    Err _ -> True
                    Ok _ -> False
                )
                SelectionStr
            , button
                [ class "btn btn-outline-primary"
                , onClick ShareClicked
                ]
                [ text "Share" ]
            ]
        ]
    , div
        [ class "translation-output p-2 rounded bg-body-secondary border" ]
        [ Translation.viewTranslation model.translationResult ]
    ]


viewInput : String -> String -> String -> Bool -> (String -> msg) -> Html msg
viewInput t p v hasError toMsg =
  input
    [ id "selection-input"
    , type_ t
    , classList [ ( "form-control", True ), ( "is-invalid", hasError ) ]
    , placeholder p
    , value v
    , onInput toMsg
    ]
    []
