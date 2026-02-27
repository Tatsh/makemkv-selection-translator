port module Ports exposing (focusInputAndSetCursorToEnd, requestShareUrl, saveSelection, saveSyntaxRefOpen)

-- Save syntax reference open state to localStorage (key: syntaxRefOpen)
port saveSyntaxRefOpen : Bool -> Cmd msg

-- Save last successful selection string to sessionStorage (key: lastSelection)
port saveSelection : String -> Cmd msg

-- Request share URL: JS base64url-encodes short string and copies full URL
port requestShareUrl : String -> Cmd msg

-- Tell JS to focus the selection input and set cursor to end
port focusInputAndSetCursorToEnd : () -> Cmd msg
