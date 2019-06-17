module GamesPage.Views.List exposing (view)

import GamesPage.Types.Main exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Types.Game as Game exposing (Game)
import Uuid


view : List Game -> List (Html Msg)
view games =
    let
        gameRow game =
            tr []
                [ td []
                    [ a [ href ("#/games/" ++ Uuid.toString game.id ++ "/edit") ]
                        [ text game.brand
                        ]
                    ]
                , td [] [ text game.category ]
                , td [] [ text game.name ]
                , td [] [ text game.startTime ]
                , td [] [ text game.endTime ]
                , td [] [ text "" ]
                , td [] [ text "" ]
                ]
    in
    [ div [ class "bottom-30px" ]
        [ a [ href "#/games/new", class "btn btn-primary" ]
            [ i [ class "fa fa-plus-square" ]
                []
            , text " Create game "
            ]
        ]
    , table [ class "table table-striped table-hover" ]
        [ thead []
            [ tr []
                [ th []
                    [ text "Brand Display" ]
                , th []
                    [ text "Category" ]
                , th []
                    [ text "Name" ]
                , th []
                    [ text "Start Time" ]
                , th []
                    [ text "End Time" ]
                , th []
                    [ text "Customer ID" ]
                , th []
                    [ text "Active" ]
                ]
            ]
        , tbody [] (List.map gameRow games)
        ]
    ]
