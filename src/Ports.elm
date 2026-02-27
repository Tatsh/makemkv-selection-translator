port module Ports exposing (focusInputAndSetCursorToEnd, saveSelection, saveSyntaxRefOpen)

-- Save syntax reference open state to localStorage (key: syntaxRefOpen)
port saveSyntaxRefOpen : Bool -> Cmd msg

-- Save last successful selection string to sessionStorage (key: lastSelection)
port saveSelection : String -> Cmd msg

-- Tell JS to focus the selection input and set cursor to end
port focusInputAndSetCursorToEnd : () -> Cmd msg
