port module Effect exposing
    ( Effect
    , none, batch
    , sendCmd, sendMsg
    , pushRoute, replaceRoute
    , map, toCmd
    , set
    , sendGetRequest
    , createWebsocket
    , sendWebsocketMessage
    , subscribeToWebsocket
    , subscribeToCursorPositionUpdates
    , saveFontSize
    , saveScrollableClues
    , setupFocusInputOnClick
    , sendCursorPositionUpdate
    , shareLink
    , showToast
    )

{-| This file was generated automatically by running elm-land customize effect
I then fixed the elm-review errors (mostly removing unused functions) - if you need to get these back check out
<https://github.com/elm-land/elm-land/blob/main/projects/cli/src/templates/_elm-land/customizable/Effect.elm>

@docs Effect

@docs none, batch
@docs sendCmd, sendMsg

@docs pushRoute, replaceRoute

@docs map, toCmd

@docs set

@docs sendGetRequest
@docs createWebsocket
@docs sendWebsocketMessage
@docs subscribeToWebsocket
@docs subscribeToCursorPositionUpdates
@docs saveFontSize
@docs saveScrollableClues
@docs setupFocusInputOnClick
@docs sendCursorPositionUpdate
@docs shareLink
@docs showToast

-}

import Browser.Navigation
import Data.FilledLetters exposing (FilledLetters)
import Data.Grid exposing (Coordinate)
import Dict exposing (Dict)
import Http
import Json.Decode
import Json.Encode
import RemoteData exposing (WebData)
import Route
import Route.Path
import Shared.Model
import Shared.Msg
import Task
import Url exposing (Url)


type Effect msg
    = -- BASICS
      None
    | Batch (List (Effect msg))
    | SendCmd (Cmd msg)
      -- ROUTING
    | PushUrl String
    | ReplaceUrl String
    | SendGetRequest { endpoint : String, decoder : Json.Decode.Decoder msg, onHttpError : Http.Error -> msg }
    | SendMessageToJavaScript { tag : String, data : Json.Encode.Value }



-- BASICS


set : Effect msg -> model -> ( model, Effect msg )
set effect model =
    ( model, effect )


{-| Don't send any effect.
-}
none : Effect msg
none =
    None


{-| Send multiple effects at once.
-}
batch : List (Effect msg) -> Effect msg
batch =
    Batch


{-| Send a normal `Cmd msg` as an effect, something like `Http.get` or `Random.generate`.
-}
sendCmd : Cmd msg -> Effect msg
sendCmd =
    SendCmd


{-| Send a message as an effect. Useful when emitting events from UI components.
-}
sendMsg : msg -> Effect msg
sendMsg msg =
    Task.succeed msg
        |> Task.perform identity
        |> SendCmd



-- ROUTING


{-| Set the new route, and make the back button go back to the current route.
-}
pushRoute :
    { path : Route.Path.Path
    , query : Dict String String
    , hash : Maybe String
    }
    -> Effect msg
pushRoute route =
    PushUrl (Route.toString route)


{-| Set the new route, but replace the previous one, so clicking the back
button **won't** go back to the previous route.
-}
replaceRoute :
    { path : Route.Path.Path
    , query : Dict String String
    , hash : Maybe String
    }
    -> Effect msg
replaceRoute route =
    ReplaceUrl (Route.toString route)



-- INTERNALS


{-| Elm Land depends on this function to connect pages and layouts
together into the overall app.
-}
map : (msg1 -> msg2) -> Effect msg1 -> Effect msg2
map fn effect =
    case effect of
        None ->
            None

        Batch list ->
            Batch (List.map (map fn) list)

        SendCmd cmd ->
            SendCmd (Cmd.map fn cmd)

        PushUrl url ->
            PushUrl url

        ReplaceUrl url ->
            ReplaceUrl url

        SendGetRequest data ->
            SendGetRequest
                { endpoint = data.endpoint
                , decoder = Json.Decode.map fn data.decoder
                , onHttpError = data.onHttpError >> fn
                }

        SendMessageToJavaScript message ->
            SendMessageToJavaScript message


{-| Elm Land depends on this function to perform your effects.
-}
toCmd :
    { key : Browser.Navigation.Key
    , url : Url
    , shared : Shared.Model.Model
    , fromSharedMsg : Shared.Msg.Msg -> msg
    , batch : List msg -> msg
    , toCmd : msg -> Cmd msg
    }
    -> Effect msg
    -> Cmd msg
toCmd options effect =
    case effect of
        None ->
            Cmd.none

        Batch list ->
            Cmd.batch (List.map (toCmd options) list)

        SendCmd cmd ->
            cmd

        PushUrl url ->
            Browser.Navigation.pushUrl options.key url

        ReplaceUrl url ->
            Browser.Navigation.replaceUrl options.key url

        SendGetRequest data ->
            Http.request
                { method = "GET"
                , url = options.shared.apiUrl ++ data.endpoint
                , headers = []
                , body = Http.emptyBody
                , expect =
                    Http.expectJson
                        (\httpResult ->
                            case httpResult of
                                Ok msg ->
                                    msg

                                Err httpError ->
                                    data.onHttpError httpError
                        )
                        data.decoder
                , timeout = Just 15000
                , tracker = Nothing
                }

        SendMessageToJavaScript message ->
            outgoing message


sendGetRequest : { endpoint : String, decoder : Json.Decode.Decoder value, onResponse : WebData value -> msg } -> Effect msg
sendGetRequest options =
    SendGetRequest
        { endpoint = options.endpoint
        , decoder =
            options.decoder
                |> Json.Decode.map Ok
                |> Json.Decode.map (RemoteData.fromResult >> options.onResponse)
        , onHttpError = Err >> RemoteData.fromResult >> options.onResponse
        }


setupFocusInputOnClick : Effect msg
setupFocusInputOnClick =
    SendMessageToJavaScript
        { tag = "SETUP_FOCUS_INPUT_ON_CLICK"
        , data = Json.Encode.null
        }


sendWebsocketMessage : String -> List ( Coordinate, Char ) -> Effect msg
sendWebsocketMessage username messages =
    SendMessageToJavaScript
        { tag = "SEND_WEBSOCKET_MESSAGE"
        , data =
            Json.Encode.list
                (\( ( x, y ), value ) ->
                    Json.Encode.object
                        [ ( "value", Json.Encode.string (String.fromChar value) )
                        , ( "x", Json.Encode.int x )
                        , ( "y", Json.Encode.int y )
                        , ( "modified_by", Json.Encode.string username )
                        ]
                )
                messages
        }


shareLink : { url : String, title : String, text : String } -> Effect msg
shareLink { url, title, text } =
    SendMessageToJavaScript
        { tag = "SHARE_LINK"
        , data =
            Json.Encode.object
                [ ( "url", Json.Encode.string url )
                , ( "title", Json.Encode.string title )
                , ( "text", Json.Encode.string text )
                ]
        }


showToast : String -> String -> Effect msg
showToast text toastType =
    SendMessageToJavaScript
        { tag = "SHOW_TOAST"
        , data =
            Json.Encode.object
                [ ( "text", Json.Encode.string text )
                , ( "type", Json.Encode.string toastType )
                ]
        }


saveFontSize : String -> Effect msg
saveFontSize fontSize =
    SendMessageToJavaScript
        { tag = "SAVE_FONT_SIZE"
        , data = Json.Encode.string fontSize
        }


saveScrollableClues : String -> Effect msg
saveScrollableClues value =
    SendMessageToJavaScript
        { tag = "SAVE_SCROLLABLE_CLUES"
        , data = Json.Encode.string value
        }


sendCursorPositionUpdate : String -> Coordinate -> Effect msg
sendCursorPositionUpdate username ( x, y ) =
    SendMessageToJavaScript
        { tag = "SEND_WEBSOCKET_MESSAGE"
        , data =
            Json.Encode.object
                [ ( "x", Json.Encode.int x )
                , ( "y", Json.Encode.int y )
                , ( "user", Json.Encode.string username )
                ]
        }


createWebsocket : String -> String -> Effect msg
createWebsocket crosswordId teamId =
    SendMessageToJavaScript
        { tag = "CREATE_WEBSOCKET"
        , data =
            Json.Encode.object
                [ ( "crosswordId", Json.Encode.string crosswordId )
                , ( "teamId", Json.Encode.string teamId )
                ]
        }


subscribeToWebsocket : (FilledLetters -> msg) -> msg -> Sub msg
subscribeToWebsocket successMsg failureMsg =
    messageReceiver
        (\string ->
            case
                Json.Decode.decodeString
                    (Json.Decode.map Dict.fromList <|
                        Json.Decode.list
                            (Json.Decode.map3
                                (\x y value ->
                                    let
                                        coordinate : Coordinate
                                        coordinate =
                                            ( x, y )

                                        letter : Char
                                        letter =
                                            List.head (String.toList value)
                                                |> Maybe.withDefault ' '
                                    in
                                    ( coordinate, letter )
                                )
                                (Json.Decode.field "x" Json.Decode.int)
                                (Json.Decode.field "y" Json.Decode.int)
                                (Json.Decode.field "value" Json.Decode.string)
                            )
                    )
                    string
            of
                Ok filledLetters ->
                    successMsg filledLetters

                Err _ ->
                    failureMsg
        )


subscribeToCursorPositionUpdates : (String -> Coordinate -> msg) -> msg -> Sub msg
subscribeToCursorPositionUpdates successMsg failureMsg =
    messageReceiver
        (\string ->
            -- Try to decode as cursor position update
            -- Cursor position messages are objects with x, y, and user/modified_by
            -- Filled letters messages are arrays, so they won't match this decoder
            case
                Json.Decode.decodeString
                    (Json.Decode.map3
                        (\x y user ->
                            successMsg user ( x, y )
                        )
                        (Json.Decode.field "x" Json.Decode.int)
                        (Json.Decode.field "y" Json.Decode.int)
                        (Json.Decode.oneOf
                            [ Json.Decode.field "user" Json.Decode.string
                            , Json.Decode.field "modified_by" Json.Decode.string
                            ]
                        )
                    )
                    string
            of
                Ok msg ->
                    msg

                Err _ ->
                    -- Not a cursor position message (might be filled letters array or other format)
                    -- Return failureMsg which will be ignored, allowing other subscriptions to handle it
                    failureMsg
        )



-- PORTS


port outgoing : { tag : String, data : Json.Encode.Value } -> Cmd msg


port messageReceiver : (String -> msg) -> Sub msg
