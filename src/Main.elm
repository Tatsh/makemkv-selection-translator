module Main exposing (main)
import Browser
import Html exposing (Html, div, input, text)
import Html.Attributes exposing (type_, placeholder, value)
import Html.Events exposing (onInput)
import MakeMkvSelectionParser

-- Main
main =
  Browser.sandbox { init = init, update = update, view = view }

-- Model
type alias Model =
  { selectionStr : String
  , translation : String
  }

init : Model
init =
  Model "" ""

-- Update
type Msg
  = SelectionStr String

update : Msg -> Model -> Model
update msg model =
  case msg of
    SelectionStr selectionStr ->
      { model | selectionStr = selectionStr
      , translation =
          case MakeMkvSelectionParser.parse selectionStr of
            Err err -> Debug.toString err
            Ok s -> s}

-- View

view : Model -> Html Msg
view model =
  div []
    [ viewInput "text" "selection string" model.selectionStr SelectionStr,
      div [] [ text model.translation ]
    ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
  input [ type_ t, placeholder p, value v, onInput toMsg ] []
