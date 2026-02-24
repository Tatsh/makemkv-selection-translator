module Main exposing (main)
import Browser
import Html exposing (Html, div, input, li, span, text, ul)
import Html.Attributes exposing (class, classList, type_, placeholder, value)
import Html.Events exposing (onInput)
import MakeMkvSelectionParser

-- Main
main =
  Browser.sandbox { init = init, update = update, view = view }

-- Model
type alias Model =
  { selectionStr : String
  , translationResult : Result String (List ( String, MakeMkvSelectionParser.Conditional ))
  }

init : Model
init =
  Model "" (Ok [])

-- Update
type Msg
  = SelectionStr String

update : Msg -> Model -> Model
update msg model =
  case msg of
    SelectionStr selectionStr ->
      { model | selectionStr = selectionStr
      , translationResult =
          if String.isEmpty selectionStr then
            Ok []
          else
            case MakeMkvSelectionParser.parse selectionStr of
              Err err -> Err (MakeMkvSelectionParser.friendlyParseError err)
              Ok list -> Ok list
      }

-- View

view : Model -> Html Msg
view model =
  div []
    [ div [ class "mb-3" ]
        [ viewInput "text"
            "-sel:all,+sel:((multi|stereo|mono)&favlang),..."
            model.selectionStr
            (case model.translationResult of
              Err _ -> True
              Ok _ -> False)
            SelectionStr
        ]
    , div [ class "translation-output p-2 rounded bg-body-secondary border" ]
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
      ul [ class "list-group list-group-flush list-group-numbered mb-0" ]
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
        [ single ] ->
          viewConditional single
        _ ->
          [ ul [ class "list-unstyled mb-0 ms-3 cond-bullet-or" ]
              (List.map (\c -> li [] (viewConditional c)) list)
          ]
    MakeMkvSelectionParser.And list ->
      case list of
        [ single ] ->
          viewConditional single
        _ ->
          [ ul [ class "list-unstyled mb-0 ms-3 cond-bullet-and" ]
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
    [ type_ t
    , classList [ ( "form-control", True ), ( "is-invalid", hasError ) ]
    , placeholder p
    , value v
    , onInput toMsg
    ]
    []
