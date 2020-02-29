module Main exposing (main)
import Browser
import Html exposing (Html, div, input)
import Html.Attributes exposing (type_, placeholder, value)
import Html.Events exposing (onInput)

-- Main
main =
  Browser.sandbox { init = init, update = update, view = view }

-- Model
-- type SelectionStr = String
type alias Model =
  { selectionStr : String }

init : Model
init =
  Model ""

-- Update
type Msg
    = SelectionStr String

update : Msg -> Model -> Model
update msg model =
  case msg of
    SelectionStr selectionStr ->
      { model | selectionStr = selectionStr }

-- View

view : Model -> Html Msg
view model =
  div []
    [ viewInput "text" "selection string" model.selectionStr SelectionStr
    ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
  input [ type_ t, placeholder p, value v, onInput toMsg ] []
