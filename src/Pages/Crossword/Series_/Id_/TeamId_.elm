module Pages.Crossword.Series_.Id_.TeamId_ exposing (FontSize(..), LoadedModel, Model, Msg, page)

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
import Html exposing (Attribute, Html, a, button, div, h2, i, input, span, text)
import Html.Attributes exposing (class, href, placeholder, style, value)
import Html.Events exposing (custom, on, onBlur, onClick, onInput, targetValue)
import Html.Parser
import Html.Parser.Util
import Json.Decode as JD
import List.Extra
import Page exposing (Page)
import Process
import RemoteData exposing (RemoteData(..), WebData)
import Route exposing (Route)
import Route.Path
import Shared
import Task
import Url
import Util.Build as Build
import Util.String
import View exposing (View)


page : Shared.Model -> Route { series : String, id : String, teamId : String } -> Page Model Msg
page sharedModel route =
    Page.new
        { init = init route.params.series route.params.id route.params.teamId sharedModel.username sharedModel.fontSize sharedModel.scrollableClues
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
    , showInfoPanel : Bool
    , showSettingsPanel : Bool
    , fontSize : FontSize
    , scrollableClues : Bool
    , teamId : String
    , teamIdInput : String
    , nameJustSaved : Bool
    }


type alias Model =
    WebData LoadedModel


init : String -> String -> String -> String -> String -> String -> () -> ( Model, Effect Msg )
init series seriesNo teamId username fontSizeString scrollableCluesString () =
    let
        fontSize : FontSize
        fontSize =
            stringToFontSize fontSizeString

        scrollableClues : Bool
        scrollableClues =
            stringToScrollableClues scrollableCluesString
    in
    ( Loading
    , Crossword.fetch { series = series, id = seriesNo, onResponse = \result -> CrosswordFetched seriesNo teamId username fontSize scrollableClues result }
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
    | Escape


type FontSize
    = Normal
    | Large
    | ExtraLarge


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
      -- Info panel
    | ToggleInfo
    | ToggleSettings
    | SetUsername String
    | SaveNameChanges
    | ClearNameSavedFeedback
    | SetFontSize FontSize
    | SetScrollableClues Bool
    | SetTeamIdInput String
    | ApplyTeamId
    | ShareLink


type Msg
    = NoOp
    | CrosswordFetched String String String FontSize Bool (WebData Crossword)
    | CrosswordUpdated CrosswordUpdatedMsg


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case ( msg, model ) of
        ( CrosswordFetched id teamId username fontSize scrollableClues response, Loading ) ->
            let
                decodedTeamId : String
                decodedTeamId =
                    Url.percentDecode teamId |> Maybe.withDefault teamId

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
                                , showInfoPanel = False
                                , showSettingsPanel = False
                                , fontSize = fontSize
                                , scrollableClues = scrollableClues
                                , teamId = decodedTeamId
                                , teamIdInput = decodedTeamId
                                , nameJustSaved = False
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
                                [ Effect.createWebsocket id decodedTeamId
                                , Effect.setupFocusInputOnClick
                                , Effect.sendCursorPositionUpdate loadedModelData.username initialCoordinate
                                ]

                        _ ->
                            Effect.none
            in
            loadedModel |> Effect.set effect

        ( CrosswordUpdated crosswordUpdatedMsg, Success loadedModel ) ->
            loadedModel
                |> updateCrossword crosswordUpdatedMsg
                |> Tuple.mapFirst Success

        _ ->
            model |> Effect.set Effect.none


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
            let
                isNewJoin : Bool
                isNewJoin =
                    username
                        /= loadedModel.username
                        && not (Dict.member username loadedModel.otherUsersCursorPositions)

                joinEffect : Effect Msg
                joinEffect =
                    if isNewJoin then
                        Effect.showToast (username ++ " joined") "info"

                    else
                        Effect.none
            in
            loadedModel
                |> setOtherUsersCursorPosition username coordinate
                |> Effect.set joinEffect

        KeyDown key ->
            case key of
                Escape ->
                    ( if loadedModel.showSettingsPanel then
                        loadedModel
                            |> setShowSettingsPanel False
                            |> (\m -> { m | nameJustSaved = False })

                      else if loadedModel.showInfoPanel then
                        loadedModel |> setShowInfoPanel False

                      else
                        loadedModel
                    , Effect.none
                    )

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

        ToggleInfo ->
            loadedModel
                |> setShowInfoPanel (not loadedModel.showInfoPanel)
                |> Effect.set Effect.none

        ToggleSettings ->
            let
                m : LoadedModel
                m =
                    loadedModel
                        |> setShowSettingsPanel (not loadedModel.showSettingsPanel)
            in
            ( if loadedModel.showSettingsPanel then
                { m | nameJustSaved = False }

              else
                m
            , Effect.none
            )

        SetFontSize fontSize ->
            loadedModel
                |> setFontSize fontSize
                |> Effect.set (Effect.saveFontSize (fontSizeToString fontSize))

        SetScrollableClues value ->
            loadedModel
                |> setScrollableClues value
                |> Effect.set (Effect.saveScrollableClues (scrollableCluesToString value))

        SetUsername username ->
            ( { loadedModel | username = username, nameJustSaved = False }
            , Effect.none
            )

        SaveNameChanges ->
            ( { loadedModel | nameJustSaved = True }
            , Effect.batch
                [ Effect.saveUsername loadedModel.username
                , Effect.sendCmd
                    (Process.sleep 2000
                        |> Task.perform (\_ -> CrosswordUpdated ClearNameSavedFeedback)
                    )
                ]
            )

        ClearNameSavedFeedback ->
            ( { loadedModel | nameJustSaved = False }
            , Effect.none
            )

        SetTeamIdInput str ->
            ( { loadedModel | teamIdInput = str }
            , Effect.none
            )

        ApplyTeamId ->
            let
                newTeamId : String
                newTeamId =
                    String.trim loadedModel.teamIdInput
            in
            if newTeamId /= loadedModel.teamId && not (String.isEmpty newTeamId) then
                ( loadedModel
                , Effect.replaceRoute
                    { path =
                        Route.Path.Crossword_Series__Id__TeamId_
                            { series = loadedModel.crossword.series
                            , id = loadedModel.crossword.seriesNo
                            , teamId = newTeamId
                            }
                    , query = Dict.empty
                    , hash = Nothing
                    }
                )

            else
                ( { loadedModel | teamIdInput = loadedModel.teamId }
                , Effect.none
                )

        ShareLink ->
            let
                linkUrl : String
                linkUrl =
                    "https://allcluedin.com/crossword/" ++ loadedModel.crossword.series ++ "/" ++ loadedModel.crossword.seriesNo ++ "/" ++ loadedModel.teamId

                title : String
                title =
                    Util.String.capitalizeFirstLetter loadedModel.crossword.series ++ " " ++ loadedModel.crossword.seriesNo

                text : String
                text =
                    "Solve this crossword with me: " ++ title
            in
            loadedModel
                |> Effect.set (Effect.shareLink { url = linkUrl, title = title, text = text })


setShowInfoPanel : Bool -> LoadedModel -> LoadedModel
setShowInfoPanel showInfoPanel model =
    { model | showInfoPanel = showInfoPanel }


setShowSettingsPanel : Bool -> LoadedModel -> LoadedModel
setShowSettingsPanel showSettingsPanel model =
    { model | showSettingsPanel = showSettingsPanel }


setFontSize : FontSize -> LoadedModel -> LoadedModel
setFontSize fontSize model =
    { model | fontSize = fontSize }


setScrollableClues : Bool -> LoadedModel -> LoadedModel
setScrollableClues scrollableClues model =
    { model | scrollableClues = scrollableClues }


stringToScrollableClues : String -> Bool
stringToScrollableClues string =
    string == "true"


scrollableCluesToString : Bool -> String
scrollableCluesToString value =
    if value then
        "true"

    else
        "false"


stringToFontSize : String -> FontSize
stringToFontSize string =
    case string of
        "Large" ->
            Large

        "ExtraLarge" ->
            ExtraLarge

        _ ->
            Normal


fontSizeToString : FontSize -> String
fontSizeToString fontSize =
    case fontSize of
        Normal ->
            "Normal"

        Large ->
            "Large"

        ExtraLarge ->
            "ExtraLarge"


fontSizeToMultiplier : FontSize -> Float
fontSizeToMultiplier fontSize =
    case fontSize of
        Normal ->
            1.0

        Large ->
            1.25

        ExtraLarge ->
            1.5


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

                "Escape" ->
                    Escape

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

        fontSizeStyle : String
        fontSizeStyle =
            String.fromFloat (fontSizeToMultiplier loadedModel.fontSize * 0.375) ++ "rem"

        attributes : List (Html.Attribute Msg)
        attributes =
            [ class "crossword-page"
            , style "font-size" fontSizeStyle
            ]

        children : List (Html Msg)
        children =
            [ div [ class "crossword-page__content-wrapper" ]
                [ viewHeader loadedModel.showInfoPanel loadedModel.showSettingsPanel
                , div [ class "crossword-page__container" ]
                    ([]
                        |> Build.add (viewGridContainer highlightedCoordinates loadedModel maybeHighlightedClue)
                        |> Build.add (viewClues loadedModel.scrollableClues loadedModel.crossword loadedModel.filledLetters maybeHighlightedClue crossword.clues)
                    )
                , viewInfoModal loadedModel
                , viewSettingsModal loadedModel
                ]
            ]
    in
    div attributes children


viewGridContainer : List Coordinate -> LoadedModel -> Maybe Clue -> Html Msg
viewGridContainer highlightedCoordinates loadedModel maybeHighlightedClue =
    let
        attributes : List (Html.Attribute Msg)
        attributes =
            [ class "grid-container" ]

        children : List (Html Msg)
        children =
            []
                |> Build.addMaybeMap viewCurrentClue maybeHighlightedClue
                |> Build.addMaybeMap viewCurrentClueDuplicate maybeHighlightedClue
                |> Build.add (viewCrosswordGrid highlightedCoordinates loadedModel)
                |> Build.add (viewButtons loadedModel)
    in
    div attributes children


viewCrosswordGrid : List Coordinate -> LoadedModel -> Html Msg
viewCrosswordGrid highlightedCoordinates loadedModel =
    let
        attributes : List (Attribute msg)
        attributes =
            [ class "grid-container__grid" ]

        children : List (Html Msg)
        children =
            []
                |> Build.add
                    (Grid.view
                        [ class "grid" ]
                        [ viewInput loadedModel.selectedCoordinate (Grid.getNumberOfRows loadedModel.crossword.grid) ]
                        (viewCell highlightedCoordinates loadedModel)
                        loadedModel.crossword.grid
                    )
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
                            , color = "#000000"
                            , onClick = CrosswordUpdated Check
                            }
                        , clicked =
                            { text = "Check All"
                            , color = "#646464"
                            , onClick = CrosswordUpdated CheckAll
                            }
                        , toParentMsg = CountdownButtonCheckMsg >> CrosswordUpdated
                        , additionalAttributes = [ class "button button--primary" ]
                        }
                    )
                |> Build.addIf shouldShowCheckAndReveal
                    (CountdownButton.view
                        { model = loadedModel.countdownButtonRevealModel
                        , initial =
                            { text = "Reveal"
                            , color = "#ffffff"
                            , onClick = CrosswordUpdated Reveal
                            }
                        , clicked =
                            { text = "Reveal All"
                            , color = "#bfbfbf"
                            , onClick = CrosswordUpdated RevealAll
                            }
                        , toParentMsg = CountdownButtonRevealMsg >> CrosswordUpdated
                        , additionalAttributes = [ class "button button--secondary" ]
                        }
                    )
                |> Build.add
                    (CountdownButton.view
                        { model = loadedModel.countdownButtonClearModel
                        , initial =
                            { text = "Clear"
                            , color = "#ffffff"
                            , onClick = CrosswordUpdated Clear
                            }
                        , clicked =
                            { text = "Clear All"
                            , color = "#bfbfbf"
                            , onClick = CrosswordUpdated ClearAll
                            }
                        , toParentMsg = CountdownButtonClearMsg >> CrosswordUpdated
                        , additionalAttributes = [ class "button button--secondary" ]
                        }
                    )
    in
    div attributes children


viewHeader : Bool -> Bool -> Html Msg
viewHeader showInfoPanel showSettingsPanel =
    let
        attributes : List (Html.Attribute Msg)
        attributes =
            [ class "header" ]

        children : List (Html Msg)
        children =
            []
                |> Build.add viewHeaderFavicon
                |> Build.add (viewHeaderRight showInfoPanel showSettingsPanel)
    in
    div attributes children


viewHeaderFavicon : Html Msg
viewHeaderFavicon =
    let
        attributes : List (Html.Attribute Msg)
        attributes =
            [ class "header__favicon", href "/" ]

        children : List (Html Msg)
        children =
            [ i [ class "fas fa-home" ] [] ]
    in
    a attributes children


viewHeaderRight : Bool -> Bool -> Html Msg
viewHeaderRight showInfoPanel showSettingsPanel =
    let
        attributes : List (Html.Attribute Msg)
        attributes =
            [ class "header__right" ]

        children : List (Html Msg)
        children =
            []
                |> Build.add (viewInfoButton showInfoPanel)
                |> Build.add viewShareButton
                |> Build.add (viewSettingsButton showSettingsPanel)
    in
    div attributes children


viewInfoButton : Bool -> Html Msg
viewInfoButton showInfoPanel =
    let
        attributes : List (Html.Attribute Msg)
        attributes =
            [ class "header__button", onClick (CrosswordUpdated ToggleInfo) ]
                |> Build.addIf showInfoPanel (class "header__button--active")

        children : List (Html Msg)
        children =
            [ i [ class "fas fa-circle-info" ] [] ]
    in
    button attributes children


viewShareButton : Html Msg
viewShareButton =
    let
        attributes : List (Html.Attribute Msg)
        attributes =
            [ class "header__button", onClick (CrosswordUpdated ShareLink) ]

        children : List (Html Msg)
        children =
            [ i [ class "fas fa-share-nodes" ] [] ]
    in
    button attributes children


viewSettingsButton : Bool -> Html Msg
viewSettingsButton showSettingsPanel =
    let
        attributes : List (Html.Attribute Msg)
        attributes =
            [ class "header__button", onClick (CrosswordUpdated ToggleSettings) ]
                |> Build.addIf showSettingsPanel (class "header__button--active")

        children : List (Html Msg)
        children =
            [ i [ class "fas fa-gear" ] [] ]
    in
    button attributes children


viewModal :
    { title : String
    , onClose : Msg
    , isHidden : Bool
    , fontSizeStyle : String
    , body : List (Html Msg)
    }
    -> Html Msg
viewModal config =
    let
        backdropAttributes : List (Html.Attribute Msg)
        backdropAttributes =
            [ class "modal-backdrop" ]
                |> Build.addIf config.isHidden (class "modal-backdrop--hidden")
                |> Build.add (onClick config.onClose)

        modalAttributes : List (Html.Attribute Msg)
        modalAttributes =
            [ class "modal modal--fit-content"
            , style "font-size" config.fontSizeStyle
            , custom "click" (JD.succeed { message = NoOp, stopPropagation = True, preventDefault = False })
            ]
                |> Build.addIf config.isHidden (class "modal--hidden")
    in
    div backdropAttributes
        [ div modalAttributes
            [ div [ class "modal__content" ]
                [ div [ class "modal__header" ]
                    [ h2 [ class "modal__title" ] [ text config.title ]
                    , button
                        [ class "modal__close"
                        , onClick config.onClose
                        ]
                        [ i [ class "fas fa-times" ] [] ]
                    ]
                , div [ class "modal__body" ] config.body
                ]
            ]
        ]


viewModalSection : String -> Html Msg -> Html Msg
viewModalSection label content =
    div
        [ class "modal-section"
        , class (if label == "" then "modal-section--action" else "")
        ]
        [ div [ class "modal-section__label" ] [ text label ]
        , div [ class "modal-section__content" ] [ content ]
        ]


viewModalSectionHeading : String -> Html Msg
viewModalSectionHeading heading =
    div [ class "modal-section-heading" ] [ text heading ]


viewInfoModal : LoadedModel -> Html Msg
viewInfoModal loadedModel =
    viewModal
        { title = "Crossword Information"
        , onClose = CrosswordUpdated ToggleInfo
        , isHidden = not loadedModel.showInfoPanel
        , fontSizeStyle = String.fromFloat (fontSizeToMultiplier loadedModel.fontSize) ++ "rem"
        , body = viewInfoSections loadedModel.crossword
        }


viewInfoSections : Crossword -> List (Html Msg)
viewInfoSections crossword =
    let
        rows : List (Html Msg)
        rows =
            [ viewModalSection "Series" (span [ class "modal-section__value" ] [ text (Util.String.capitalizeFirstLetter crossword.series) ])
            , viewModalSection "Number" (span [ class "modal-section__value" ] [ text crossword.seriesNo ])
            , viewModalSection "Date" (span [ class "modal-section__value" ] [ text crossword.date ])
            ]
                |> Build.addIf (crossword.setter /= "")
                    (viewModalSection "Setter" (span [ class "modal-section__value" ] [ text crossword.setter ]))

        guardianLink : Html Msg
        guardianLink =
            a
                [ class "modal-section__link"
                , href ("https://www.theguardian.com/crosswords/" ++ crossword.series ++ "/" ++ crossword.seriesNo)
                ]
                [ text "View on The Guardian"
                , i [ class "fas fa-external-link-alt modal-section__link-icon" ] []
                ]
    in
    rows ++ [ viewModalSection "" guardianLink ]


viewSettingsModal : LoadedModel -> Html Msg
viewSettingsModal loadedModel =
    viewModal
        { title = "Settings"
        , onClose = CrosswordUpdated ToggleSettings
        , isHidden = not loadedModel.showSettingsPanel
        , fontSizeStyle = String.fromFloat (fontSizeToMultiplier loadedModel.fontSize) ++ "rem"
        , body = viewSettingsSections loadedModel
        }


viewSettingsSections : LoadedModel -> List (Html Msg)
viewSettingsSections loadedModel =
    [ viewModalSection "Solving with team" (viewTeamIdControl loadedModel)
    , viewModalSection "Your name" (viewUsernameControl loadedModel)
    , viewModalSectionHeading "DISPLAY"
    , viewModalSection "Font size" (viewFontSizeButtons loadedModel)
    , viewModalSection "Scrollable clues" (viewScrollableCluesButtons loadedModel)
    ]


viewTeamIdControl : LoadedModel -> Html Msg
viewTeamIdControl loadedModel =
    div [ class "modal-section__stack" ]
        [ input
            [ class "modal-section__input"
            , value loadedModel.teamIdInput
            , placeholder "Team name"
            , onInput (\s -> CrosswordUpdated (SetTeamIdInput s))
            , onBlur (CrosswordUpdated ApplyTeamId)
            , custom "keydown"
                (JD.field "key" JD.string
                    |> JD.andThen
                        (\key ->
                            if key == "Enter" then
                                JD.succeed { message = CrosswordUpdated ApplyTeamId, stopPropagation = True, preventDefault = True }

                            else
                                JD.fail "not Enter"
                        )
                )
            ]
            []
        , div [ class "modal-section__hint modal-section__hint--warning" ]
            [ i [ class "fas fa-exclamation-triangle modal-section__hint-icon" ] []
            , text "Changing this setting will reload the page to join a new team."
            ]
        ]


viewUsernameControl : LoadedModel -> Html Msg
viewUsernameControl loadedModel =
    div [ class "modal-section__row" ]
        [ input
            [ class "modal-section__input"
            , value loadedModel.username
            , placeholder "Your display name"
            , onInput (\s -> CrosswordUpdated (SetUsername s))
            , onBlur (CrosswordUpdated SaveNameChanges)
            ]
            []
        , if loadedModel.nameJustSaved then
            span [ class "modal-section__saved" ] [ text "Saved" ]

          else
            text ""
        ]


viewFontSizeButtons : LoadedModel -> Html Msg
viewFontSizeButtons loadedModel =
    let
        fontSizeButton : FontSize -> String -> Html Msg
        fontSizeButton fontSize label =
            let
                isActive : Bool
                isActive =
                    loadedModel.fontSize == fontSize

                buttonClass : String
                buttonClass =
                    "modal-section__button"
                        ++ (if isActive then
                                " modal-section__button--active"

                            else
                                ""
                           )
            in
            button
                [ class buttonClass
                , onClick (CrosswordUpdated (SetFontSize fontSize))
                ]
                [ text label ]
    in
    div [ class "modal-section__buttons" ]
        [ fontSizeButton Normal "Normal"
        , fontSizeButton Large "Large"
        , fontSizeButton ExtraLarge "Extra Large"
        ]


viewScrollableCluesButtons : LoadedModel -> Html Msg
viewScrollableCluesButtons loadedModel =
    let
        scrollableButton : Bool -> String -> Html Msg
        scrollableButton value label =
            let
                isActive : Bool
                isActive =
                    loadedModel.scrollableClues == value

                buttonClass : String
                buttonClass =
                    "modal-section__button"
                        ++ (if isActive then
                                " modal-section__button--active"

                            else
                                ""
                           )
            in
            button
                [ class buttonClass
                , onClick (CrosswordUpdated (SetScrollableClues value))
                ]
                [ text label ]
    in
    div [ class "modal-section__buttons" ]
        [ scrollableButton True "On"
        , scrollableButton False "Off"
        ]


viewCurrentClue : Clue -> Html Msg
viewCurrentClue clue =
    let
        attributes : List (Html.Attribute Msg)
        attributes =
            [ class "current-clue" ]

        children : List (Html Msg)
        children =
            []
                |> Build.add (viewClueText clue)
    in
    div attributes children


viewCurrentClueDuplicate : Clue -> Html Msg
viewCurrentClueDuplicate clue =
    let
        attributes : List (Html.Attribute Msg)
        attributes =
            [ class "current-clue-duplicate", class "current-clue" ]

        children : List (Html Msg)
        children =
            []
                |> Build.add (viewClueText clue)
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
            "calc(min(99vw, 50rem) * " ++ coordinate ++ ".5 / " ++ numberOfRowsString
    in
    input
        [ class "crossword-input"
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
                    "cell--white"

                 else
                    "cell--black"
                )
            ]
                |> Build.addIf (coordinate == loadedModel.selectedCoordinate) (class "cell--selected")
                |> Build.addIf (not (List.isEmpty usersAtCoordinate)) (style "position" "relative")
                |> Build.addIf isWhite (onClick (CrosswordUpdated (CellSelected coordinate)))
                |> Build.addIf isHighlighted (class "cell--highlighted")

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
            [ class "cell__number" ]

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


viewClues : Bool -> Crossword -> FilledLetters -> Maybe Clue -> List Clue -> Html Msg
viewClues scrollableClues crossword filledLetters maybeHighlightedClue clues =
    let
        acrossClues : List Clue
        acrossClues =
            Clue.getDirectionClues Across clues

        downClues : List Clue
        downClues =
            Clue.getDirectionClues Down clues

        attributes : List (Html.Attribute Msg)
        attributes =
            [ class "clues" ]
                |> Build.addIf (not scrollableClues) (class "clues--no-inner-scroll")

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
            [ class "clues__list" ]

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
        [ class "clues__title" ]
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
                |> Build.addIf (maybeHighlightedClue == Just clue) (class "clue--selected")
                |> Build.addIf isClueFilled (class "clue--filled")
                |> Build.add (onClick (CrosswordUpdated (ClueSelected clue)))

        children : List (Html Msg)
        children =
            []
                |> Build.add (viewClueNumber (Clue.getNumberString clue))
                |> Build.add (viewClueText clue)
    in
    div attributes children


viewClueText : Clue -> Html Msg
viewClueText clue =
    let
        clueText : String
        clueText =
            Clue.getText clue
    in
    div [ class "clue__text" ]
        (case Html.Parser.run clueText of
            Ok nodes ->
                Html.Parser.Util.toVirtualDom nodes

            Err _ ->
                [ text clueText ]
        )


viewClueNumber : String -> Html Msg
viewClueNumber clueNumber =
    div
        [ class "clue__number" ]
        [ text clueNumber ]
