module Main exposing (main)

import Browser exposing (Document, UrlRequest(..))
import Browser.Events exposing (onResize)
import Browser.Navigation as Navigation
import GamesPage.Main as GamesPage
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Random
import Routing exposing (Page(..), Route(..))
import Url exposing (Url)


type Msg
    = NoOp
    | Navigate UrlRequest
    | ChangeUrl Url
    | SetWindowSize Int Int
    | ToggleLeftSideBar
    | OnGamesPage GamesPage.Msg


type alias Model =
    { seed : Random.Seed
    , windowSize : Maybe ( Int, Int )
    , leftSideBarVisible : Bool
    , currentPage : Page
    , navigationKey : Navigation.Key
    }


type alias Flags =
    { initialSeed : Int
    , windowSize :
        { width : Int
        , height : Int
        }
    }


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlRequest = Navigate
        , onUrlChange = ChangeUrl
        }


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url navigationKey =
    let
        model =
            { seed = Random.initialSeed flags.initialSeed
            , windowSize = Just ( flags.windowSize.width, flags.windowSize.height )
            , leftSideBarVisible = True
            , currentPage = Index
            , navigationKey = navigationKey
            }
    in
    ( model
    , Cmd.batch [ Navigation.pushUrl navigationKey url.path ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model
            , Cmd.none
            )

        Navigate urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Navigation.pushUrl model.navigationKey (Url.toString url)
                    )

                External url ->
                    ( model
                    , Navigation.load url
                    )

        ChangeUrl url ->
            case Debug.log "route" (Routing.route url) of
                Just route ->
                    case route of
                        IndexPage ->
                            ( { model | currentPage = Index }
                            , Cmd.none
                            )

                        GamesPage targetView ->
                            case model.currentPage of
                                Games gamesPageModel ->
                                    let
                                        ( newGamesPageModel, gamesPageCmd ) =
                                            GamesPage.navigate targetView gamesPageModel
                                    in
                                    ( { model | currentPage = Games newGamesPageModel }
                                    , Cmd.map OnGamesPage gamesPageCmd
                                    )

                                _ ->
                                    let
                                        pageInit =
                                            Random.map (GamesPage.init targetView model.navigationKey) Random.independentSeed

                                        ( ( gamesPageModel, gamesPageCmd ), nextSeed ) =
                                            Random.step pageInit model.seed
                                    in
                                    ( { model | currentPage = Games gamesPageModel, seed = nextSeed }
                                    , Cmd.map OnGamesPage gamesPageCmd
                                    )

                        GameAreasPage ->
                            ( { model | currentPage = GameAreas }
                            , Cmd.none
                            )

                        CustomersPage ->
                            ( { model | currentPage = Customers }
                            , Cmd.none
                            )

                        PlayersPage ->
                            ( { model | currentPage = Players }
                            , Cmd.none
                            )

                        LiveMonitorPage ->
                            ( { model | currentPage = LiveMonitor }
                            , Cmd.none
                            )

                Nothing ->
                    ( model
                    , Navigation.replaceUrl model.navigationKey "/"
                    )

        SetWindowSize width height ->
            ( { model | windowSize = Just ( width, height ) }
            , Cmd.none
            )

        ToggleLeftSideBar ->
            ( { model | leftSideBarVisible = not model.leftSideBarVisible }
            , Cmd.none
            )

        OnGamesPage gamesPageMsg ->
            case model.currentPage of
                Games gamesPageModel ->
                    let
                        ( newGamesPageModel, gamesPageCmd ) =
                            GamesPage.update gamesPageMsg gamesPageModel
                    in
                    ( { model | currentPage = Games newGamesPageModel }
                    , Cmd.map OnGamesPage gamesPageCmd
                    )

                _ ->
                    ( model
                    , Cmd.none
                    )


view : Model -> Document Msg
view model =
    let
        contentWrapperClasses =
            case model.windowSize of
                Just ( width, _ ) ->
                    [ ( "content-wrapper", True )
                    , ( "expanded", width >= 992 && not model.leftSideBarVisible )
                    ]

                Nothing ->
                    [ ( "content-wrapper", True )
                    ]

        contentWrapperStyle =
            case model.windowSize of
                Just ( _, height ) ->
                    style "min-height" (String.fromInt (height * 3) ++ "px")

                Nothing ->
                    class ""

        pageContent =
            case model.currentPage of
                Games gamesPageModel ->
                    List.map (Html.map OnGamesPage) (GamesPage.view gamesPageModel)

                _ ->
                    []
    in
    { title = "Admin dashboard"
    , body =
        [ div [ id "wrapper", class "wrapper" ]
            [ navBar model
            , leftSideBar model
            , div [ classList contentWrapperClasses, contentWrapperStyle ]
                pageContent
            ]
        ]
    }


navBar : Model -> Html Msg
navBar _ =
    div [ class "top-bar navbar-fixed-top" ]
        [ div [ class "container" ]
            [ div [ class "clearfix" ]
                [ a [ class "pull-left toggle-sidebar-collapse", onClick ToggleLeftSideBar ]
                    [ i [ class "fa fa-bars" ]
                        []
                    ]
                , div [ class "pull-left left logo" ]
                    [ a [ href "#" ]
                        [ text ""
                        ]
                    , h1 [ class "sr-only" ]
                        [ text "Admin Dashboard" ]
                    ]
                , div [ class "pull-right right" ]
                    [ div [ class "searchbox" ]
                        [ div [ class "input-group" ]
                            [ input [ class "form-control", placeholder "enter keyword here...", type_ "search" ]
                                []
                            , span [ class "input-group-btn" ]
                                [ button [ class "btn btn-default", type_ "button" ]
                                    [ i [ class "fa fa-search" ]
                                        []
                                    ]
                                ]
                            ]
                        ]
                    , div [ class "top-bar-right" ]
                        [ div [ class "logged-user" ]
                            [ div [ class "btn-group" ]
                                [ a [ href "#", class "btn btn-link dropdown-toggle", (\( a, b ) -> style a b) ( "pointer-events", "none" ) ]
                                    [ img [ alt "User Avatar", src "/images/icon-user.png", class "avatar" ]
                                        []
                                    , span [ class "name" ]
                                        [ text "Admin" ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]


leftSideBar : Model -> Html Msg
leftSideBar model =
    let
        sideBarClasses =
            case model.windowSize of
                Just ( width, _ ) ->
                    [ ( "left-sidebar", True )
                    , ( "sidebar-float-active", width < 992 && model.leftSideBarVisible )
                    , ( "minified", width >= 992 && not model.leftSideBarVisible )
                    ]

                Nothing ->
                    [ ( "left-sidebar", True )
                    ]
    in
    div [ id "left-sidebar", classList sideBarClasses ]
        [ div [ class "sidebar-minified" ]
            [ i [ class "fa fa-exchange", onClick ToggleLeftSideBar ]
                []
            ]
        , div [ class "sidebar-scroll" ]
            [ nav [ class "main-nav" ]
                [ ul [ class "main-menu" ]
                    [ li [ classList [ ( "active", isCurrentPage "/games" model ) ] ]
                        [ a [ href "/games" ]
                            [ i [ class "fa fa-gamepad" ]
                                []
                            , span [ class "text" ]
                                [ text "Games "
                                ]
                            ]
                        ]
                    , li [ classList [ ( "active", isCurrentPage "/areas" model ) ] ]
                        [ a [ href "/areas" ]
                            [ i [ class "fa fa-map" ]
                                []
                            , span [ class "text" ]
                                [ text "Area Templates " ]
                            ]
                        ]
                    , li [ classList [ ( "active", isCurrentPage "/customers" model ) ] ]
                        [ a [ href "/customers" ]
                            [ i [ class "fa fa-briefcase" ]
                                []
                            , span [ class "text" ]
                                [ text "Customers " ]
                            ]
                        ]
                    , li [ classList [ ( "active", isCurrentPage "/players" model ) ] ]
                        [ a [ href "/players" ]
                            [ i [ class "fa fa-users" ]
                                []
                            , span [ class "text" ]
                                [ text "Players " ]
                            ]
                        ]
                    , li [ classList [ ( "active", isCurrentPage "/live-monitor" model ) ] ]
                        [ a [ href "/live-monitor" ]
                            [ i [ class "fa fa-thermometer-full" ]
                                []
                            , span [ class "text" ]
                                [ text "Live Monitor " ]
                            ]
                        ]
                    ]
                ]
            ]
        ]


isCurrentPage : String -> Model -> Bool
isCurrentPage segment model =
    case model.currentPage of
        Index ->
            segment == ""

        Games _ ->
            segment == "/games"

        GameAreas ->
            segment == "/areas"

        Customers ->
            segment == "/customers"

        Players ->
            segment == "/players"

        LiveMonitor ->
            segment == "/live-monitor"


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        pageSub =
            case model.currentPage of
                Games gamesPageModel ->
                    Sub.map OnGamesPage (GamesPage.subscriptions gamesPageModel)

                _ ->
                    Sub.none
    in
    Sub.batch [ onResize SetWindowSize, pageSub ]
