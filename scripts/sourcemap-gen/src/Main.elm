port module Main exposing (main)

import Browser
import Html exposing (Html, div)
import SourceMap exposing (Mapping, addMapping, empty, toString, withFile)

main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }

type alias Flags =
    { outputFile : String
    , sourceFile : String
    }

type alias Model =
    ()

type Msg
    = NoOp

init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        mapJson : String
        mapJson =
            empty
                |> withFile flags.outputFile
                |> addMapping
                    { generatedLine = 1
                    , generatedColumn = 1
                    , source = flags.sourceFile
                    , originalLine = 1
                    , originalColumn = 1
                    , name = Nothing
                    }
                |> toString
    in
    ( (), emitMap mapJson )

update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )

view : Model -> Html Msg
view _ =
    div [] []

subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none

port emitMap : String -> Cmd msg
