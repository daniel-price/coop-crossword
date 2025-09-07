module Pages.Crossword.Series_.Id_.TeamId_ exposing (LoadedModel, Model, Msg, page)

import Browser.Events
import Components.CountdownButton as CountdownButton
import Data.Cell as Cell exposing (Cell)
import Data.Clue as Clue exposing (Clue)
import Data.Crossword as Crossword exposing (Crossword)
import Data.Direction as Direction exposing (Direction(..))
import Data.FilledLetters exposing (FilledLetters)
import Data.Grid as Grid exposing (Coordinate, Grid)
import Dict
import Effect exposing (Effect)
import Html exposing (Attribute, Html, a, div, i, input, span, text)
import Html.Attributes exposing (class, href, id, style, value)
import Html.Events exposing (on, onClick, targetValue)
import Html.Parser
import Html.Parser.Util
import Json.Decode as JD
import List.Extra
import Page exposing (Page)
import RemoteData exposing (RemoteData(..), WebData)
import Route exposing (Route)
import Route.Path
import Shared
import Util.Build as Build
import Util.String
import View exposing (View)


page : Shared.Model -> Route { series : String, id : String, teamId : String } -> Page Model Msg
page sharedModel route =
    Page.new
        { init = init route.params.series route.params.id route.params.teamId sharedModel.username
        , update = update
        , subscriptions = subscriptions
        , view = view sharedModel
        }



-- INIT


type alias LoadedModel =
    { crossword : Crossword
    , selectedCoordinate : ( Int, Int )
    , selectedDirection : Direction
    , filledLetters : FilledLetters
    , otherUsersCursorPositions : Dict.Dict String Coordinate
    , countdownButtonCheckModel : CountdownButton.Model
    , countdownButtonRevealModel : CountdownButton.Model
    , countdownButtonClearModel : CountdownButton.Model
    , username : String
    }


type alias Model =
    WebData LoadedModel


init : String -> String -> String -> String -> () -> ( Model, Effect Msg )
init series seriesNo teamId username () =
    ( Loading
    , Crossword.fetch { series = series, id = seriesNo, onResponse = \result -> CrosswordFetched seriesNo teamId username result }
    )



-- UPDATE


type ArrowDirection
    = ArrowLeft
    | ArrowRight
    | ArrowUp
    | ArrowDown


type Key
    = Unknown
    | Backspace
    | Arrow ArrowDirection


type CrosswordUpdatedMsg
    = CellSelected Coordinate
    | CellLetterAdded Coordinate Char
    | FilledLettersUpdated FilledLetters
    | CursorPositionUpdated String Coordinate
    | KeyDown Key
    | ClueSelected Clue
    | Check
    | CheckAll
    | Clear
    | ClearAll
    | Reveal
    | RevealAll
      --Button messages
    | CountdownButtonCheckMsg (CountdownButton.Msg Msg)
    | CountdownButtonRevealMsg (CountdownButton.Msg Msg)
    | CountdownButtonClearMsg (CountdownButton.Msg Msg)


type Msg
    = NoOp
    | CrosswordFetched String String String (WebData Crossword)
    | CrosswordUpdated CrosswordUpdatedMsg
    | NavigateToHome


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case ( msg, model ) of
        ( CrosswordFetched id teamId username response, Loading ) ->
            let
                loadedModel : WebData LoadedModel
                loadedModel =
                    response
                        |> RemoteData.map
                            (\crossword ->
                                let
                                    selectedCoordinate : ( Int, Int )
                                    selectedCoordinate =
                                        crossword.grid
                                            |> Grid.findCoordinate Cell.isWhite
                                            |> Maybe.withDefault ( 0, 0 )

                                    selectedDirection : Direction
                                    selectedDirection =
                                        crossword.grid
                                            |> Grid.get (Tuple.mapFirst ((+) 1) selectedCoordinate)
                                            |> Maybe.andThen
                                                (\cell ->
                                                    if Cell.isWhite cell then
                                                        Just Direction.Across

                                                    else
                                                        Nothing
                                                )
                                            |> Maybe.withDefault Direction.Down
                                in
                                { crossword = crossword
                                , selectedCoordinate = selectedCoordinate
                                , selectedDirection = selectedDirection
                                , filledLetters = Dict.empty
                                , otherUsersCursorPositions = Dict.empty
                                , countdownButtonCheckModel = CountdownButton.init
                                , countdownButtonRevealModel = CountdownButton.init
                                , countdownButtonClearModel = CountdownButton.init
                                , username = username
                                }
                            )

                effect : Effect Msg
                effect =
                    case loadedModel of
                        Success loadedModelData ->
                            let
                                initialCoordinate : Coordinate
                                initialCoordinate =
                                    loadedModelData.selectedCoordinate
                            in
                            Effect.batch
                                [ Effect.createWebsocket id teamId
                                , Effect.setupFocusInputOnClick
                                , Effect.sendCursorPositionUpdate loadedModelData.username initialCoordinate
                                ]

                        _ ->
                            Effect.none
            in
            loadedModel |> Effect.set effect

        ( CrosswordUpdated crosswordUpdatedMsg, Success loadedModel ) ->
            loadedModel
                |> resetFields crosswordUpdatedMsg
                |> updateCrossword crosswordUpdatedMsg
                |> Tuple.mapFirst Success

        ( NavigateToHome, _ ) ->
            model |> Effect.set (Effect.pushRoute { path = Route.Path.Home_, query = Dict.empty, hash = Nothing })

        _ ->
            model |> Effect.set Effect.none


resetFields : CrosswordUpdatedMsg -> LoadedModel -> LoadedModel
resetFields msg loadedModel =
    case msg of
        FilledLettersUpdated _ ->
            loadedModel

        _ ->
            { loadedModel
                | countdownButtonCheckModel =
                    case msg of
                        Check ->
                            loadedModel.countdownButtonCheckModel

                        CountdownButtonCheckMsg _ ->
                            loadedModel.countdownButtonCheckModel

                        _ ->
                            CountdownButton.init
                , countdownButtonRevealModel =
                    case msg of
                        Reveal ->
                            loadedModel.countdownButtonRevealModel

                        CountdownButtonRevealMsg _ ->
                            loadedModel.countdownButtonRevealModel

                        _ ->
                            CountdownButton.init
                , countdownButtonClearModel =
                    case msg of
                        Clear ->
                            loadedModel.countdownButtonClearModel

                        CountdownButtonClearMsg _ ->
                            loadedModel.countdownButtonClearModel

                        _ ->
                            CountdownButton.init
            }


updateCrossword : CrosswordUpdatedMsg -> LoadedModel -> ( LoadedModel, Effect Msg )
updateCrossword msg loadedModel =
    case msg of
        CellSelected coordinate ->
            loadedModel
                |> updateCellSelected coordinate
                |> Effect.set (Effect.sendCursorPositionUpdate loadedModel.username coordinate)

        CellLetterAdded coordinate letter ->
            let
                nextCoordinate : Coordinate
                nextCoordinate =
                    loadedModel.crossword
                        |> Crossword.getNextClueCoordinate loadedModel.selectedCoordinate loadedModel.selectedDirection
            in
            loadedModel
                |> (nextCoordinate
                        |> setSelectedCoordinate
                   )
                |> (loadedModel.filledLetters
                        |> Dict.insert coordinate letter
                        |> setFilledLetters
                   )
                |> Effect.set (Effect.batch [ Effect.sendWebsocketMessage loadedModel.username [ ( coordinate, letter ) ], Effect.sendCursorPositionUpdate loadedModel.username nextCoordinate ])

        FilledLettersUpdated filledLetters ->
            loadedModel
                |> setFilledLetters (Dict.union filledLetters loadedModel.filledLetters)
                |> Effect.set Effect.none

        CursorPositionUpdated username coordinate ->
            loadedModel
                |> setOtherUsersCursorPosition username coordinate
                |> Effect.set Effect.none

        KeyDown key ->
            case key of
                Backspace ->
                    case Dict.get loadedModel.selectedCoordinate loadedModel.filledLetters of
                        Just _ ->
                            loadedModel
                                |> setFilledLetters (Dict.remove loadedModel.selectedCoordinate loadedModel.filledLetters)
                                |> Effect.set (Effect.sendWebsocketMessage loadedModel.username [ ( loadedModel.selectedCoordinate, ' ' ) ])

                        Nothing ->
                            loadedModel
                                |> setSelectedCoordinate
                                    (loadedModel.crossword
                                        |> Crossword.getPreviousClueCoordinate loadedModel.selectedCoordinate loadedModel.selectedDirection
                                    )
                                |> Effect.set Effect.none

                Unknown ->
                    loadedModel
                        |> Effect.set Effect.none

                Arrow arrowDirection ->
                    let
                        newCoordinate : Coordinate
                        newCoordinate =
                            case arrowDirection of
                                ArrowLeft ->
                                    Crossword.getPreviousWhiteCoordinate loadedModel.selectedCoordinate Across loadedModel.crossword

                                ArrowRight ->
                                    Crossword.getNextWhiteCoordinate loadedModel.selectedCoordinate Across loadedModel.crossword

                                ArrowUp ->
                                    Crossword.getPreviousWhiteCoordinate loadedModel.selectedCoordinate Down loadedModel.crossword

                                ArrowDown ->
                                    Crossword.getNextWhiteCoordinate loadedModel.selectedCoordinate Down loadedModel.crossword
                    in
                    loadedModel
                        |> updateCellSelected newCoordinate
                        |> Effect.set (Effect.sendCursorPositionUpdate loadedModel.username newCoordinate)

        ClueSelected clue ->
            let
                newCoordinate : Coordinate
                newCoordinate =
                    loadedModel.crossword.grid
                        |> Grid.findCoordinate (\cell -> Cell.getNumber cell == Just (Clue.getNumber clue))
                        |> Maybe.withDefault loadedModel.selectedCoordinate
            in
            loadedModel
                |> setSelectedCoordinate newCoordinate
                |> setSelectedDirection (Clue.getDirection clue)
                |> Effect.set (Effect.sendCursorPositionUpdate loadedModel.username newCoordinate)

        Check ->
            loadedModel.crossword
                |> Crossword.getClueCoordinates loadedModel.selectedCoordinate loadedModel.selectedDirection
                |> handleCheck loadedModel

        CheckAll ->
            loadedModel.crossword
                |> Crossword.getAllWhiteCoordinates
                |> handleCheck loadedModel

        Reveal ->
            loadedModel.crossword
                |> Crossword.getClueCoordinates loadedModel.selectedCoordinate loadedModel.selectedDirection
                |> handleReveal loadedModel

        RevealAll ->
            loadedModel.crossword
                |> Crossword.getAllWhiteCoordinates
                |> handleReveal loadedModel

        Clear ->
            loadedModel.crossword
                |> Crossword.getClueCoordinates loadedModel.selectedCoordinate loadedModel.selectedDirection
                |> handleClear loadedModel

        ClearAll ->
            loadedModel.crossword
                |> Crossword.getAllWhiteCoordinates
                |> handleClear loadedModel

        CountdownButtonCheckMsg buttonMsg ->
            CountdownButton.update
                { model =
                    loadedModel.countdownButtonCheckModel
                , msg = buttonMsg
                , toParentModel = \model -> { loadedModel | countdownButtonCheckModel = model }
                }

        CountdownButtonRevealMsg buttonMsg ->
            CountdownButton.update
                { model =
                    loadedModel.countdownButtonRevealModel
                , msg = buttonMsg
                , toParentModel = \model -> { loadedModel | countdownButtonRevealModel = model }
                }

        CountdownButtonClearMsg buttonMsg ->
            CountdownButton.update
                { model =
                    loadedModel.countdownButtonClearModel
                , msg = buttonMsg
                , toParentModel = \model -> { loadedModel | countdownButtonClearModel = model }
                }


handleClear : LoadedModel -> List Coordinate -> ( LoadedModel, Effect Msg )
handleClear loadedModel coordinates =
    let
        changedLetters : List ( Coordinate, Char )
        changedLetters =
            coordinates
                |> List.map (\coord -> ( coord, ' ' ))
    in
    updateCoordinateLetters loadedModel changedLetters


handleReveal : LoadedModel -> List Coordinate -> ( LoadedModel, Effect Msg )
handleReveal loadedModel coordinates =
    let
        changedLetters : List ( Coordinate, Char )
        changedLetters =
            coordinates
                |> List.map
                    (\coord ->
                        loadedModel.crossword.grid
                            |> Grid.get coord
                            |> Maybe.andThen (\cell -> Cell.getLetter cell)
                            |> Maybe.map (\letter -> ( coord, letter ))
                            |> Maybe.withDefault ( coord, ' ' )
                    )
    in
    updateCoordinateLetters loadedModel changedLetters


handleCheck : LoadedModel -> List Coordinate -> ( LoadedModel, Effect Msg )
handleCheck loadedModel coordinates =
    let
        incorrectCoordinates : List Coordinate
        incorrectCoordinates =
            coordinates
                |> getIncorrectCoordinates loadedModel.crossword.grid loadedModel.filledLetters

        changedLetters : List ( Coordinate, Char )
        changedLetters =
            incorrectCoordinates
                |> List.map (\coord -> ( coord, ' ' ))
    in
    updateCoordinateLetters loadedModel changedLetters


updateCoordinateLetters : LoadedModel -> List ( Coordinate, Char ) -> ( LoadedModel, Effect Msg )
updateCoordinateLetters loadedModel changedLetters =
    let
        newFilledLetters : FilledLetters
        newFilledLetters =
            changedLetters
                |> List.foldl
                    (\( coordinate, letter ) filledLetters ->
                        if letter == ' ' then
                            Dict.remove coordinate filledLetters

                        else
                            Dict.insert coordinate letter filledLetters
                    )
                    loadedModel.filledLetters
    in
    loadedModel
        |> setFilledLetters newFilledLetters
        |> Effect.set (Effect.sendWebsocketMessage loadedModel.username changedLetters)


getIncorrectCoordinates : Grid Cell -> FilledLetters -> List Coordinate -> List Coordinate
getIncorrectCoordinates grid filledLetters coordinates =
    coordinates
        |> List.filter
            (\coord ->
                grid
                    |> Grid.get coord
                    |> Maybe.andThen (\cell -> Cell.getLetter cell)
                    |> Maybe.andThen
                        (\cellLetter ->
                            filledLetters |> Dict.get coord |> Maybe.map (\filledLetter -> filledLetter /= cellLetter)
                        )
                    |> Maybe.withDefault True
            )


updateCellSelected : Coordinate -> LoadedModel -> LoadedModel
updateCellSelected coordinate loadedModel =
    let
        isDirection : Direction -> Bool
        isDirection direction =
            loadedModel.crossword
                |> Crossword.getClueCoordinates coordinate direction
                |> List.any (\c -> c /= coordinate)

        isAcross : Bool
        isAcross =
            isDirection Across

        isDown : Bool
        isDown =
            isDirection Down

        updatedDirection : Direction
        updatedDirection =
            if isAcross && isDown then
                if loadedModel.selectedCoordinate == coordinate then
                    case loadedModel.selectedDirection of
                        Across ->
                            Down

                        Down ->
                            Across

                else
                    loadedModel.selectedDirection

            else if isAcross then
                Across

            else
                Down
    in
    loadedModel
        |> setSelectedCoordinate coordinate
        |> setSelectedDirection updatedDirection


setSelectedCoordinate : Coordinate -> LoadedModel -> LoadedModel
setSelectedCoordinate selectedCoordinate model =
    { model | selectedCoordinate = selectedCoordinate }


setSelectedDirection : Direction -> LoadedModel -> LoadedModel
setSelectedDirection selectedDirection model =
    { model | selectedDirection = selectedDirection }


setFilledLetters : FilledLetters -> LoadedModel -> LoadedModel
setFilledLetters filledLetters model =
    { model | filledLetters = filledLetters |> Dict.filter (\_ letter -> letter /= ' ') }


setOtherUsersCursorPosition : String -> Coordinate -> LoadedModel -> LoadedModel
setOtherUsersCursorPosition username coordinate model =
    { model | otherUsersCursorPositions = Dict.insert username coordinate model.otherUsersCursorPositions }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    model
        |> RemoteData.map
            (\loadedModel ->
                Sub.batch
                    [ Effect.subscribeToWebsocket (CrosswordUpdated << FilledLettersUpdated) NoOp
                    , Effect.subscribeToCursorPositionUpdates
                        (\username coordinate ->
                            CrosswordUpdated (CursorPositionUpdated username coordinate)
                        )
                        NoOp
                    , keyDownSubscription
                    , CountdownButton.subscriptions loadedModel.countdownButtonCheckModel (CountdownButtonCheckMsg >> CrosswordUpdated)
                    , CountdownButton.subscriptions loadedModel.countdownButtonRevealModel (CountdownButtonRevealMsg >> CrosswordUpdated)
                    , CountdownButton.subscriptions loadedModel.countdownButtonClearModel (CountdownButtonClearMsg >> CrosswordUpdated)
                    ]
            )
        |> RemoteData.withDefault Sub.none


keyDownSubscription : Sub Msg
keyDownSubscription =
    let
        keyDownToMsg : String -> Msg
        keyDownToMsg eventKeyString =
            (case eventKeyString of
                "Backspace" ->
                    Backspace

                "ArrowLeft" ->
                    Arrow ArrowLeft

                "ArrowRight" ->
                    Arrow ArrowRight

                "ArrowUp" ->
                    Arrow ArrowUp

                "ArrowDown" ->
                    Arrow ArrowDown

                _ ->
                    Unknown
            )
                |> KeyDown
                |> CrosswordUpdated
    in
    JD.string
        |> JD.field "key"
        |> JD.map keyDownToMsg
        |> Browser.Events.onKeyDown



-- VIEW


view : Shared.Model -> Model -> View Msg
view _ model =
    { title = "Crossword"
    , body =
        case model of
            NotAsked ->
                [ div [ class "loading-text" ] [ text "Preparing your crossword..." ] ]

            Loading ->
                [ div [ class "loading-text" ] [ text "Loading puzzle..." ] ]

            Failure _ ->
                [ div [ class "error-state" ] [ text "Oops! Couldn't load this crossword. Please try again." ] ]

            Success loadedModel ->
                [ viewCrossword loadedModel ]
    }


viewCrossword : LoadedModel -> Html Msg
viewCrossword loadedModel =
    let
        { crossword, selectedCoordinate, selectedDirection } =
            loadedModel

        highlightedCoordinates : List Coordinate
        highlightedCoordinates =
            loadedModel.crossword
                |> Crossword.getClueCoordinates selectedCoordinate selectedDirection

        maybeHighlightedClue : Maybe Clue
        maybeHighlightedClue =
            loadedModel.crossword
                |> Crossword.getCurrentClue selectedCoordinate selectedDirection

        attributes : List (Html.Attribute Msg)
        attributes =
            [ id "crossword" ]

        children : List (Html Msg)
        children =
            []
                |> Build.add (viewGridContainer highlightedCoordinates maybeHighlightedClue loadedModel)
                |> Build.add (viewClues loadedModel.crossword loadedModel.filledLetters maybeHighlightedClue crossword.clues)
    in
    div attributes children


viewInfo : Crossword -> Html Msg
viewInfo crossword =
    let
        attributes : List (Html.Attribute Msg)
        attributes =
            [ id "info" ]

        setByString : String
        setByString =
            if crossword.setter == "" then
                ""

            else
                " set by " ++ crossword.setter

        children : List (Html Msg)
        children =
            []
                |> Build.add (span [ class "home-icon", onClick NavigateToHome ] [ i [ class "fas fa-home" ] [] ])
                |> Build.add (text (Util.String.capitalizeFirstLetter crossword.series ++ " " ++ crossword.seriesNo ++ " - " ++ crossword.date ++ " -" ++ setByString ++ " for "))
                |> Build.add
                    (a [ href ("https://www.theguardian.com/crosswords/" ++ crossword.series ++ "/" ++ crossword.seriesNo) ] [ text "the Guardian" ])
    in
    div attributes children


viewGridContainer : List Coordinate -> Maybe Clue -> LoadedModel -> Html Msg
viewGridContainer highlightedCoordinates maybeHighlightedClue loadedModel =
    let
        attributes : List (Html.Attribute Msg)
        attributes =
            [ id "grid-container" ]

        children : List (Html Msg)
        children =
            []
                |> Build.add (viewCrosswordGrid highlightedCoordinates maybeHighlightedClue loadedModel)
                |> Build.add (viewButtons loadedModel)
                |> Build.add (viewInfo loadedModel.crossword)
    in
    div attributes children


viewCrosswordGrid : List Coordinate -> Maybe Clue -> LoadedModel -> Html Msg
viewCrosswordGrid highlightedCoordinates maybeHighlightedClue loadedModel =
    let
        attributes : List (Attribute msg)
        attributes =
            [ id "crossword-grid" ]

        children : List (Html Msg)
        children =
            []
                |> Build.addMaybeMap viewCurrentClue maybeHighlightedClue
                |> Build.add (Grid.view [ id "grid" ] [ viewInput loadedModel.selectedCoordinate (Grid.getNumberOfRows loadedModel.crossword.grid) ] (viewCell highlightedCoordinates loadedModel) loadedModel.crossword.grid)
    in
    div attributes children


viewButtons : LoadedModel -> Html Msg
viewButtons loadedModel =
    let
        shouldShowCheckAndReveal : Bool
        shouldShowCheckAndReveal =
            loadedModel.crossword.grid
                |> Grid.filterCoordinates (\cell -> Cell.getLetter cell == Just ' ')
                |> List.isEmpty

        attributes : List (Html.Attribute Msg)
        attributes =
            [ class "buttons" ]

        children : List (Html Msg)
        children =
            []
                |> Build.addIf shouldShowCheckAndReveal
                    (CountdownButton.view
                        { model = loadedModel.countdownButtonCheckModel
                        , initial =
                            { text = "Check"
                            , color = "#2b945a"
                            , onClick = CrosswordUpdated Check
                            }
                        , clicked =
                            { text = "Check All"
                            , color = "#006400"
                            , onClick = CrosswordUpdated CheckAll
                            }
                        , toParentMsg = CountdownButtonCheckMsg >> CrosswordUpdated
                        , additionalAttributes = [ class "button" ]
                        }
                    )
                |> Build.addIf shouldShowCheckAndReveal
                    (CountdownButton.view
                        { model = loadedModel.countdownButtonRevealModel
                        , initial =
                            { text = "Reveal"
                            , color = "#4078c0"
                            , onClick = CrosswordUpdated Reveal
                            }
                        , clicked =
                            { text = "Reveal All"
                            , color = "#174175"
                            , onClick = CrosswordUpdated RevealAll
                            }
                        , toParentMsg = CountdownButtonRevealMsg >> CrosswordUpdated
                        , additionalAttributes = [ class "button" ]
                        }
                    )
                |> Build.add
                    (CountdownButton.view
                        { model = loadedModel.countdownButtonClearModel
                        , initial =
                            { text = "Clear"
                            , color = "#db3535"
                            , onClick = CrosswordUpdated Clear
                            }
                        , clicked =
                            { text = "Clear All"
                            , color = "#9c1f1f"
                            , onClick = CrosswordUpdated ClearAll
                            }
                        , toParentMsg = CountdownButtonClearMsg >> CrosswordUpdated
                        , additionalAttributes = [ class "button" ]
                        }
                    )
    in
    div attributes children


viewCurrentClue : Clue -> Html Msg
viewCurrentClue clue =
    let
        attributes : List (Html.Attribute Msg)
        attributes =
            [ id "current-clue" ]

        children : List (Html Msg)
        children =
            []
                |> Build.add (text (Clue.getNumberString clue ++ " "))
                |> Build.concat (viewClueText clue)
    in
    div attributes children


{-| Have an input floating on top of the grid so that the user can type.

    We can't just use onInput on the currently selected cell as switching focus
    isn't fast enough to keep up with the user typing fast.

    Don't use Html.Events.onInput as it stops propogation which leads to weird backspace behaviour on mobile

-}
viewInput : Coordinate -> Int -> Html Msg
viewInput selectedCoordinate numberOfRows =
    let
        onInput : (String -> msg) -> Attribute msg
        onInput tagger =
            on "input" (JD.map tagger targetValue)

        xString : String
        xString =
            Tuple.first selectedCoordinate
                |> String.fromInt

        yString : String
        yString =
            Tuple.second selectedCoordinate
                |> String.fromInt

        numberOfRowsString : String
        numberOfRowsString =
            String.fromInt numberOfRows

        calcExpression : String -> String
        calcExpression coordinate =
            "calc(min(99vw, 800px) * " ++ coordinate ++ ".5 / " ++ numberOfRowsString
    in
    input
        [ id "input"
        , style "top" (calcExpression yString)
        , style "left" (calcExpression xString)
        , onInput
            (\string ->
                String.toList string
                    |> List.reverse
                    |> List.head
                    |> Maybe.map
                        (\char ->
                            char
                                |> Char.toUpper
                                |> CellLetterAdded selectedCoordinate
                                |> CrosswordUpdated
                        )
                    |> Maybe.withDefault NoOp
            )
        , value ""
        ]
        []


viewCell : List Coordinate -> LoadedModel -> Coordinate -> Cell -> Html Msg
viewCell highlightedCoordinates loadedModel coordinate cell =
    let
        isWhite : Bool
        isWhite =
            Cell.isWhite cell

        isHighlighted : Bool
        isHighlighted =
            List.member coordinate highlightedCoordinates

        usersAtCoordinate : List String
        usersAtCoordinate =
            loadedModel.otherUsersCursorPositions
                |> Dict.filter (\username _ -> username /= loadedModel.username)
                |> Dict.toList
                |> List.filter (\( _, userCoordinate ) -> userCoordinate == coordinate)
                |> List.map Tuple.first

        maybeLetter : Maybe String
        maybeLetter =
            Dict.get coordinate loadedModel.filledLetters
                |> Maybe.map String.fromChar

        attributes : List (Html.Attribute Msg)
        attributes =
            [ class "cell"
            , class
                (if isWhite then
                    "white"

                 else
                    "black"
                )
            ]
                |> Build.addIf (coordinate == loadedModel.selectedCoordinate) (class "cell-selected")
                |> Build.addIf (not (List.isEmpty usersAtCoordinate)) (style "position" "relative")
                |> Build.addIf isWhite (onClick (CrosswordUpdated (CellSelected coordinate)))
                |> Build.addIf isHighlighted (class "cell-highlighted")

        children : List (Html Msg)
        children =
            []
                |> Build.addMaybeMap viewCellNumber (Cell.getNumber cell)
                |> Build.addMaybeMap text maybeLetter
                |> Build.addIf (not (List.isEmpty usersAtCoordinate)) (viewOtherUserIndicators usersAtCoordinate)
    in
    div attributes children


viewCellNumber : Int -> Html Msg
viewCellNumber cellNumber =
    let
        attributes : List (Html.Attribute Msg)
        attributes =
            [ class "cell-number" ]

        children : List (Html Msg)
        children =
            [ text (String.fromInt cellNumber) ]
    in
    div attributes children


viewOtherUserIndicators : List String -> Html Msg
viewOtherUserIndicators usernames =
    div
        [ style "position" "absolute"
        , style "top" "0.1em"
        , style "right" "0.1em"
        , style "display" "flex"
        , style "flex-direction" "row"
        , style "z-index" "2"
        ]
        (List.map viewOtherUserIndicator usernames)


viewOtherUserIndicator : String -> Html Msg
viewOtherUserIndicator username =
    let
        attributes : List (Html.Attribute Msg)
        attributes =
            [ style "width" "0.3em"
            , style "height" "0.3em"
            , style "background-color" (getUserColor username)
            , style "border-radius" "0.05em"
            , style "margin-left" "0.05em"
            ]
    in
    div attributes []


getUserColor : String -> String
getUserColor username =
    let
        colors : List String
        colors =
            [ "#E74C3C" -- Red
            , "#3498DB" -- Blue
            , "#2ECC71" -- Green
            , "#F39C12" -- Orange
            , "#9B59B6" -- Purple
            , "#E67E22" -- Dark Orange
            , "#1ABC9C" -- Teal
            , "#E91E63" -- Pink
            , "#34495E" -- Dark Blue
            , "#F1C40F" -- Yellow
            , "#8E44AD" -- Dark Purple
            , "#16A085" -- Dark Teal
            ]

        hash : Int
        hash =
            String.foldl (\char acc -> acc * 31 + Char.toCode char) 0 username
    in
    List.Extra.getAt (modBy (List.length colors) (abs hash)) colors
        |> Maybe.withDefault "#E74C3C"


viewClues : Crossword -> FilledLetters -> Maybe Clue -> List Clue -> Html Msg
viewClues crossword filledLetters maybeHighlightedClue clues =
    let
        acrossClues : List Clue
        acrossClues =
            Clue.getDirectionClues Across clues

        downClues : List Clue
        downClues =
            Clue.getDirectionClues Down clues

        attributes : List (Html.Attribute Msg)
        attributes =
            [ id "clues" ]

        children : List (Html Msg)
        children =
            []
                |> Build.add (viewCluesList Across crossword filledLetters maybeHighlightedClue acrossClues)
                |> Build.add (viewCluesList Down crossword filledLetters maybeHighlightedClue downClues)
    in
    div attributes children


viewCluesList : Direction -> Crossword -> FilledLetters -> Maybe Clue -> List Clue -> Html Msg
viewCluesList direction crossword filledLetters maybeHighlightedClue clues =
    let
        attributes : List (Html.Attribute Msg)
        attributes =
            [ class "clues-list" ]

        children : List (Html Msg)
        children =
            []
                |> Build.add (viewClueTitle direction)
                |> Build.concat (List.map (viewClue crossword filledLetters maybeHighlightedClue) clues)
    in
    div attributes children


viewClueTitle : Direction -> Html Msg
viewClueTitle direction =
    div
        [ class "clue-title" ]
        [ text (Direction.toString direction) ]


viewClue : Crossword -> FilledLetters -> Maybe Clue -> Clue -> Html Msg
viewClue crossword filledLetters maybeHighlightedClue clue =
    let
        isClueFilled : Bool
        isClueFilled =
            Crossword.getFirstClueCoordinate clue crossword
                |> Maybe.map
                    (\coordinate ->
                        Crossword.getClueCoordinates coordinate (Clue.getDirection clue) crossword
                            |> List.Extra.findMap
                                (\coord ->
                                    let
                                        filledLetter : Char
                                        filledLetter =
                                            filledLetters |> Dict.get coord |> Maybe.withDefault ' '
                                    in
                                    if filledLetter == ' ' then
                                        Just False

                                    else
                                        Nothing
                                )
                            |> Maybe.withDefault True
                    )
                |> Maybe.withDefault False

        attributes : List (Html.Attribute Msg)
        attributes =
            [ class "clue" ]
                |> Build.addIf (maybeHighlightedClue == Just clue) (id "clue-selected")
                |> Build.addIf isClueFilled (class "clue-filled")
                |> Build.add (onClick (CrosswordUpdated (ClueSelected clue)))

        children : List (Html Msg)
        children =
            []
                |> Build.add (viewClueNumber (Clue.getNumberString clue))
                |> Build.concat (viewClueText clue)
    in
    div attributes children


viewClueText : Clue -> List (Html Msg)
viewClueText clue =
    let
        clueText : String
        clueText =
            Clue.getText clue
    in
    case Html.Parser.run clueText of
        Ok nodes ->
            Html.Parser.Util.toVirtualDom nodes

        Err _ ->
            [ text clueText ]


viewClueNumber : String -> Html Msg
viewClueNumber clueNumber =
    div
        [ class "clue-number" ]
        [ text clueNumber ]
