module Translation
  exposing
    ( capitalize
    , conditionRendersAsListing
    , parseResult
    , viewConditional
    , viewRule
    , viewTranslation
    )

import Html exposing (Html, li, span, text, ul)
import Html.Attributes exposing (class)
import MakeMkvSelectionParser


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
        (List.map
          (\( action, cond ) ->
            li [ class "list-group-item" ]
              (viewRule action cond)
          )
          items
        )


conditionRendersAsListing : MakeMkvSelectionParser.Conditional -> Bool
conditionRendersAsListing cond =
  case cond of
    MakeMkvSelectionParser.Prim _ ->
      False
    MakeMkvSelectionParser.Not child ->
      conditionRendersAsListing child
    MakeMkvSelectionParser.Or list ->
      if List.length list > 1 then
        True
      else
        case list of
          [ single ] ->
            conditionRendersAsListing single
          _ ->
            False
    MakeMkvSelectionParser.And list ->
      if List.length list > 1 then
        True
      else
        case list of
          [ single ] ->
            conditionRendersAsListing single
          _ ->
            False


viewRule : String -> MakeMkvSelectionParser.Conditional -> List (Html msg)
viewRule action cond =
  let
    content =
      text (capitalize action ++ " ") :: viewConditional cond
    suffix =
      if conditionRendersAsListing cond then
        []
      else
        [ text "." ]
  in
  content ++ suffix


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
