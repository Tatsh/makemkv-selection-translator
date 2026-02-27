module Main exposing (main)

import Browser
import Html exposing (Html, button, code, div, h6, input, li, span, text, ul)
import Html.Attributes exposing (class, classList, id, type_, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import MakeMkvSelectionParser
import Ports
import Share


-- Main
main =
  Browser.element
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }


subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none


-- Model
type alias Model =
  { selectionStr : String
  , translationResult : Result String (List ( String, MakeMkvSelectionParser.Conditional ))
  , syntaxRefOpen : Bool
  }


type alias Flags =
  { syntaxRefOpen : Bool
  , savedSelection : Maybe String
  , shareParam : Maybe String
  }


flagsDecoder : Decode.Decoder Flags
flagsDecoder =
  Decode.map3 Flags
    (Decode.field "syntaxRefOpen" Decode.bool)
    (Decode.oneOf
      [ Decode.field "savedSelection" (Decode.maybe Decode.string)
      , Decode.succeed Nothing
      ]
    )
    (Decode.oneOf
      [ Decode.field "shareParam" (Decode.maybe Decode.string)
      , Decode.succeed Nothing
      ]
    )


init : Decode.Value -> ( Model, Cmd Msg )
init flagsValue =
  let
    default =
      ( Model "" (Ok []) False, Cmd.none )
    decoded =
      Decode.decodeValue flagsDecoder flagsValue
  in
  case decoded of
    Ok f ->
      let
        str =
          case f.shareParam of
            Just short ->
              Share.decodeSelection short
                |> Result.withDefault (Maybe.withDefault "" f.savedSelection)
            Nothing ->
              Maybe.withDefault "" f.savedSelection
      in
      ( Model str (parseResult str) f.syntaxRefOpen, Cmd.none )
    Err _ ->
      default


-- Update
type Msg
  = SelectionStr String
  | ToggleSyntaxRef
  | AppendToSelection String
  | ShareClicked


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SelectionStr selectionStr ->
      let
        result =
          parseResult selectionStr
        saveCmd =
          case result of
            Ok _ ->
              Ports.saveSelection selectionStr
            Err _ ->
              Cmd.none
      in
      ( { model
          | selectionStr = selectionStr
          , translationResult = result
        }
      , saveCmd
      )

    ToggleSyntaxRef ->
      ( { model | syntaxRefOpen = not model.syntaxRefOpen }
      , Ports.saveSyntaxRefOpen (not model.syntaxRefOpen)
      )

    AppendToSelection s ->
      let
        newStr =
          model.selectionStr ++ s
        result =
          parseResult newStr
        saveCmd =
          case result of
            Ok _ ->
              Ports.saveSelection newStr
            Err _ ->
              Cmd.none
      in
      ( { model
          | selectionStr = newStr
          , translationResult = result
        }
      , Cmd.batch [ Ports.focusInputAndSetCursorToEnd (), saveCmd ]
      )

    ShareClicked ->
      case Share.encodeSelection model.selectionStr of
        Just short ->
          ( model, Ports.requestShareUrl short )
        Nothing ->
          ( model, Cmd.none )


parseResult : String -> Result String (List ( String, MakeMkvSelectionParser.Conditional ))
parseResult selectionStr =
  if String.isEmpty selectionStr then
    Ok []
  else
    case MakeMkvSelectionParser.parse selectionStr of
      Err err ->
        Err (MakeMkvSelectionParser.friendlyParseError err)
      Ok list ->
        Ok list


-- View

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
            , li [] [ tokClickable "+N", text " / ", tokClickable "-N", text " / ", tokClickable "=N", text " — add / subtract / set weight" ]
            ]
        , h6 [ class "syntax-ref-heading mb-2 mt-0" ] [ text "Operators" ]
        , ul [ class "mb-3 ps-3" ]
            [ li [] [ tokClickable "|", text " — or" ]
            , li [] [ tokClickable "&", text " / ", tokClickable "*", text " — and" ]
            , li [] [ tokClickable "!", text " / ", tokClickable "~", text " — not" ]
            ]
        , h6 [ class "syntax-ref-heading mb-2 mt-0" ] [ text "Condition tokens" ]
        , ul [ class "mb-0 ps-3" ]
            [ li [] [ tokClickable "all", text " ", tokClickable "video", text " ", tokClickable "audio", text " ", tokClickable "subtitle", text " ", tokClickable "mvcvideo", text " ", tokClickable "favlang", text " ", tokClickable "nolang", text " ", tokClickable "special", text " ", tokClickable "forced" ]
            , li [] [ tokClickable "mono", text " ", tokClickable "stereo", text " ", tokClickable "multi", text " ", tokClickable "havemulti", text " ", tokClickable "lossy", text " ", tokClickable "lossless", text " ", tokClickable "havelossless", text " ", tokClickable "core", text " ", tokClickable "havecore", text " ", tokClickable "single" ]
            , li [] [ tokClickable "N", text " — nth track of same type and language" ]
            , li [] [ tokClickable "xxx", text " — 3-letter language code (e.g. ", tokClickable "eng", text " ", tokClickable "fra", text ")" ]
            ]
        ]
    ]

view : Model -> Html Msg
view model =
  div
    []
    [ syntaxReference model.syntaxRefOpen
    , div [ class "mb-3" ]
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
            [ class "btn btn-outline-primary btn-sm mt-2"
            , onClick ShareClicked
            ]
            [ text "Share" ]
        ]
    , div
        [ class "translation-output p-2 rounded bg-body-secondary border" ]
        [ viewTranslation model.translationResult ]
    ]


viewTranslation : Result String (List ( String, MakeMkvSelectionParser.Conditional )) -> Html msg
viewTranslation result =
  case result of
    Err err ->
      text err
    Ok [] ->
      text ""
    Ok items ->
      ul
        [ class "list-group list-group-flush list-group-numbered mb-0" ]
        (List.map (\( action, cond ) -> li [ class "list-group-item" ] (viewRule action cond)) items)


viewRule : String -> MakeMkvSelectionParser.Conditional -> List (Html msg)
viewRule action cond =
  text (capitalize action ++ " ") :: viewConditional cond


viewConditional : MakeMkvSelectionParser.Conditional -> List (Html msg)
viewConditional cond =
  case cond of
    MakeMkvSelectionParser.Prim s ->
      [ text s ]
    MakeMkvSelectionParser.Not child ->
      [ text "not ", span [ class "cond-not" ] (viewConditional child) ]
    MakeMkvSelectionParser.Or list ->
      case list of
        [single] ->
          viewConditional single
        _ ->
          [ ul
              [ class "list-unstyled mb-0 ms-3 cond-bullet-or" ]
              (List.map (\c -> li [] (viewConditional c)) list)
          ]
    MakeMkvSelectionParser.And list ->
      case list of
        [single] ->
          viewConditional single
        _ ->
          [ ul
              [ class "list-unstyled mb-0 ms-3 cond-bullet-and" ]
              (List.map (\c -> li [] (viewConditional c)) list)
          ]


capitalize : String -> String
capitalize s =
  case String.uncons s of
    Nothing -> s
    Just ( head, tail ) -> String.cons (Char.toUpper head) tail


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
