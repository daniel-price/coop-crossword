module Pages.Home_ exposing (LoadedModel, Model, Msg, page)

import Data.CrosswordInfo as CrosswordInfo exposing (CrosswordInfo)
import Effect exposing (Effect)
import Html exposing (Html, a, div, h1, h2, h3, p, section, text)
import Html.Attributes exposing (class, href, id)
import Page exposing (Page)
import RemoteData exposing (RemoteData(..), WebData)
import Route exposing (Route)
import Shared
import Util.String
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page sharedModel _ =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view sharedModel
        }



-- INIT


type alias LoadedModel =
    { crosswordInfos : List CrosswordInfo
    }


type alias Model =
    WebData LoadedModel


init : () -> ( Model, Effect Msg )
init () =
    ( Loading
    , CrosswordInfo.fetch { onResponse = \result -> CrosswordInfoFetched result }
    )



-- UPDATE


type Msg
    = CrosswordInfoFetched (WebData (List CrosswordInfo))


update : Msg -> Model -> ( Model, Effect Msg )
update msg _ =
    case msg of
        CrosswordInfoFetched response ->
            response
                |> RemoteData.map (\crosswordInfos -> { crosswordInfos = crosswordInfos })
                |> (\newModel -> ( newModel, Effect.none ))



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view sharedModel model =
    { title = "All Clued In"
    , body =
        [ div [ class "home-container" ]
            ([ div [ class "home-header" ]
                [ h1 [ class "home-title" ] [ text "All Clued In" ]
                , p [ class "home-subtitle" ] [ text "Solve crosswords together with friends in real-time" ]
                , div [ class "home-description" ]
                    [ p [ class "description-text" ]
                        [ text "Welcome to All Clued In! This is a collaborative crossword platform where you can solve puzzles together with friends. Share a link, and everyone can work on the same crossword simultaneously, seeing each other's progress in real-time." ]
                    ]
                ]
            , section [ class "home-features" ]
                [ h2 [ class "features-title" ] [ text "How it works" ]
                , div [ class "features-grid" ]
                    [ div [ class "feature-card" ]
                        [ h3 [ class "feature-heading" ] [ text "Choose a Crossword" ]
                        , p [ class "feature-text" ] [ text "Browse our collection of crosswords organized by series. Pick one that interests you and your friends." ]
                        ]
                    , div [ class "feature-card" ]
                        [ h3 [ class "feature-heading" ] [ text "Share the Link" ]
                        , p [ class "feature-text" ] [ text "Copy the link and share it with your friends. Each link creates a unique collaborative session." ]
                        ]
                    , div [ class "feature-card" ]
                        [ h3 [ class "feature-heading" ] [ text "Solve Together" ]
                        , p [ class "feature-text" ] [ text "Work on the same crossword simultaneously. See each other's letters appear in real-time as you solve together." ]
                        ]
                    ]
                ]
            ]
                ++ (case model of
                        NotAsked ->
                            [ viewSkeletonLoading ]

                        Loading ->
                            [ viewSkeletonLoading ]

                        Failure _ ->
                            [ div [ class "error-state" ] [ text "Failed to load crosswords. Please try again later." ] ]

                        Success { crosswordInfos } ->
                            [ section [ class "crosswords-section" ]
                                [ h2 [ class "crosswords-title" ] [ text "Available Crosswords" ]
                                , div [ id "crosswords" ]
                                    (crosswordInfos
                                        |> splitBySeries
                                        |> List.map (viewSeries sharedModel.teamId)
                                    )
                                ]
                            ]
                   )
            )
        ]
    }


viewSeries : String -> ( String, List CrosswordInfo ) -> Html Msg
viewSeries teamId ( series, items ) =
    div [ class "series" ]
        [ div [ class "header" ] [ h2 [] [ text (Util.String.capitalizeFirstLetter series) ] ]
        , div [ class "links" ] (viewLinks teamId items)
        ]


viewLinks : String -> List CrosswordInfo -> List (Html.Html Msg)
viewLinks teamId items =
    items
        |> List.map (viewLink teamId)


viewLink : String -> CrosswordInfo -> Html.Html Msg
viewLink teamId item =
    div [ class "link" ] [ a [ href ("/crossword/" ++ item.series ++ "/" ++ String.fromInt item.seriesNo ++ "/" ++ teamId) ] [ text (String.fromInt item.seriesNo ++ " - " ++ item.humanDate) ] ]


splitBySeries : List CrosswordInfo -> List ( String, List CrosswordInfo )
splitBySeries crosswordInfos =
    crosswordInfos
        |> List.foldl
            (\crosswordInfo acc ->
                let
                    series : String
                    series =
                        crosswordInfo.series
                in
                case List.head acc of
                    Just ( currentSeries, currentCrosswordInfos ) ->
                        if series == currentSeries then
                            ( series, crosswordInfo :: currentCrosswordInfos ) :: Maybe.withDefault [] (List.tail acc)

                        else
                            ( series, [ crosswordInfo ] ) :: acc

                    Nothing ->
                        [ ( series, [ crosswordInfo ] ) ]
            )
            []
        |> List.map (\( series, items ) -> ( series, items |> List.sortBy (\i -> i.date) |> List.reverse ))



-- SKELETON LOADING VIEWS


viewSkeletonLoading : Html Msg
viewSkeletonLoading =
    div [ id "crosswords" ]
        [ viewSkeletonSeries
        , viewSkeletonSeries
        , viewSkeletonSeries
        , viewSkeletonSeries
        , viewSkeletonSeries
        , viewSkeletonSeries
        ]


viewSkeletonSeries : Html Msg
viewSkeletonSeries =
    div [ class "skeleton-card" ]
        [ div [ class "header" ]
            [ div [ class "skeleton skeleton-series-header" ] [] ]
        , div [ class "links" ]
            [ viewSkeletonLink
            , viewSkeletonLink
            , viewSkeletonLink
            , viewSkeletonLink
            , viewSkeletonLink
            ]
        ]


viewSkeletonLink : Html Msg
viewSkeletonLink =
    div [ class "link" ]
        [ div [ class "skeleton skeleton-link" ] [] ]
