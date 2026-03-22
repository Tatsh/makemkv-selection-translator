module App exposing (Flags, Model, Msg(..), flagsDecoder, init, subscriptions, update)

import Json.Decode as Decode
import MakeMkvSelectionParser
import Ports
import Translation


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
            Just selection ->
              selection
            Nothing ->
              Maybe.withDefault "" f.savedSelection
      in
      ( Model str (Translation.parseResult str) f.syntaxRefOpen, Cmd.none )
    Err _ ->
      default


subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none


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
          Translation.parseResult selectionStr
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
          Translation.parseResult newStr
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
      ( model, Ports.requestShareUrl model.selectionStr )
