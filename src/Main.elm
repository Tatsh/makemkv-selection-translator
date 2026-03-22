module Main exposing (main)

import App
import Browser
import MainView


main =
  Browser.element
    { init = App.init
    , update = App.update
    , view = MainView.view
    , subscriptions = App.subscriptions
    }
