module Routing exposing (Page(..), Route(..), route)

import GamesPage.Main as GamesPage
import Url exposing (Url)
import Url.Parser exposing ((</>), Parser, custom, map, oneOf, s, top, parse)
import Uuid exposing (Uuid)


type Route
    = IndexPage
    | GamesPage GamesPage.View
    | GameAreasPage
    | CustomersPage
    | PlayersPage
    | LiveMonitorPage


type Page
    = Index
    | Games GamesPage.Model
    | GameAreas
    | Customers
    | Players
    | LiveMonitor



{- PUBLIC API -}


route : Url -> Maybe Route
route location =
    let
        parser =
            oneOf
                [ map IndexPage top
                , map GamesPage (oneOf [ gameList, newGame, editGame ])
                , map GameAreasPage (s "areas")
                , map CustomersPage (s "customers")
                , map PlayersPage (s "players")
                , map LiveMonitorPage (s "live-monitor")
                ]
    in
    parse parser location



{- PRIVATE API -}


uuid : Parser (Uuid -> a) a
uuid =
    custom "UUID" (\s -> Uuid.fromString s )


gameList : Parser (GamesPage.View -> a) a
gameList =
    map GamesPage.GameList (s "games")


newGame : Parser (GamesPage.View -> a) a
newGame =
    map GamesPage.NewGame (s "games" </> s "new")


editGame : Parser (GamesPage.View -> a) a
editGame =
    map GamesPage.EditGame (s "games" </> uuid </> s "edit")
