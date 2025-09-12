module Data.Grid exposing (Coordinate, Grid, decoder, filterCoordinates, findCoordinate, get, getColumnCoordinates, getNumberOfRows, getRowCoordinates, test_new, view)

import Html exposing (Html, div)
import Html.Attributes exposing (style)
import Json.Decode as JD
import Json.Decode.Pipeline exposing (required)
import List.Extra


type Grid a
    = Grid { numberOfRows : Int, items : List a }


type alias Coordinate =
    ( Int, Int )


getIndexCoordinates : Grid a -> Int -> Coordinate
getIndexCoordinates (Grid { numberOfRows }) index =
    ( remainderBy numberOfRows index, index // numberOfRows )


getRowCoordinates : Coordinate -> Grid a -> List Coordinate
getRowCoordinates ( _, y ) (Grid { numberOfRows }) =
    let
        indexes : List Int
        indexes =
            List.range 0 (numberOfRows - 1)
    in
    List.map (\i -> ( i, y )) indexes


getColumnCoordinates : Coordinate -> Grid a -> List Coordinate
getColumnCoordinates ( x, _ ) (Grid { numberOfRows, items }) =
    let
        numberOfColumns : Int
        numberOfColumns =
            List.length items // numberOfRows

        indexes : List Int
        indexes =
            List.range 0 (numberOfColumns - 1)
    in
    List.map (\i -> ( x, i )) indexes


getNumberOfRows : Grid a -> Int
getNumberOfRows (Grid { numberOfRows }) =
    numberOfRows


findCoordinate : (a -> Bool) -> Grid a -> Maybe Coordinate
findCoordinate predicate grid =
    let
        (Grid { items }) =
            grid
    in
    List.Extra.findIndex predicate items |> Maybe.map (getIndexCoordinates grid)


get : Coordinate -> Grid a -> Maybe a
get ( x, y ) (Grid { numberOfRows, items }) =
    let
        index : Int
        index =
            y * numberOfRows + x
    in
    List.Extra.getAt index items


filterCoordinates : (a -> Bool) -> Grid a -> List Coordinate
filterCoordinates predicate grid =
    let
        (Grid { items }) =
            grid
    in
    items
        |> List.Extra.indexedFoldl
            (\index item acc ->
                if predicate item then
                    acc ++ [ getIndexCoordinates grid index ]

                else
                    acc
            )
            []



-- DECODERS


decoder : String -> JD.Decoder a -> JD.Decoder (Grid a)
decoder field itemDecoder =
    JD.succeed (\numberOfRows items -> Grid { numberOfRows = numberOfRows, items = items })
        |> required "numberOfRows" JD.int
        |> required field (JD.list itemDecoder)



-- VIEW


view : List (Html.Attribute msg) -> List (Html msg) -> (Coordinate -> a -> Html msg) -> Grid a -> Html msg
view additionalAttributes additionalChildren viewItem grid =
    let
        (Grid { numberOfRows, items }) =
            grid

        attributes : List (Html.Attribute msg)
        attributes =
            [ style "display" "grid"
            , style "grid-template-columns" ("repeat(" ++ String.fromInt numberOfRows ++ ", 1fr)")
            ]
                ++ additionalAttributes

        children : List (Html msg)
        children =
            additionalChildren
                ++ List.indexedMap
                    (\i ->
                        let
                            coordinate : Coordinate
                            coordinate =
                                getIndexCoordinates (Grid { numberOfRows = numberOfRows, items = items }) i
                        in
                        viewItem coordinate
                    )
                    items
    in
    div attributes children



-- TEST HELPERS


test_new : Int -> List a -> Grid a
test_new numberOfRows items =
    Grid { numberOfRows = numberOfRows, items = items }
