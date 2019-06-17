module GamesPage.Main exposing (Model, Msg, View(..), init, navigate, subscriptions, update, view)

import Browser.Navigation as Navigation
import GamesPage.Helpers.Api as Api
import GamesPage.Types.Form as GameForm exposing (FieldID(..), GameForm, ImageFieldID(..), PreviewState(..))
import GamesPage.Types.Main exposing (..)
import GamesPage.Views.Form as GameForm
import GamesPage.Views.List as GameList
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Random
import Types.Image as Image
import Uuid exposing (Uuid)


type alias Model =
    GamesPage.Types.Main.Model


type alias Msg =
    GamesPage.Types.Main.Msg


type View
    = GameList
    | NewGame
    | EditGame Uuid


init : View -> Navigation.Key -> Random.Seed -> ( Model, Cmd Msg )
init initialView navigationKey seed =
    case initialView of
        GameList ->
            let
                model =
                    { view = ListView []
                    , alert = Nothing
                    , seed = seed
                    , navigationKey = navigationKey
                    }
            in
            ( model
            , Api.getGames InitGames
            )

        NewGame ->
            let
                ( uuid, nextSeed ) =
                    Random.step Uuid.uuidGenerator seed

                form =
                    GameForm.empty uuid uuid uuid

                model =
                    { view = FormView form
                    , alert = Nothing
                    , seed = nextSeed
                    , navigationKey = navigationKey
                    }
            in
            ( model
            , Cmd.none
            )

        EditGame id ->
            let
                model =
                    { view = ListView []
                    , alert = Nothing
                    , seed = seed
                    , navigationKey = navigationKey
                    }
            in
            ( model
            , Api.getGameForm ShowForm id
            )


navigate : View -> Model -> ( Model, Cmd Msg )
navigate targetView model =
    case targetView of
        GameList ->
            case model.view of
                ListView _ ->
                    ( model
                    , Cmd.none
                    )

                _ ->
                    ( { model | alert = Nothing }
                    , Api.getGames InitGames
                    )

        NewGame ->
            case model.view of
                FormView _ ->
                    ( model
                    , Cmd.none
                    )

                _ ->
                    init NewGame model.navigationKey model.seed

        EditGame id ->
            case model.view of
                FormView _ ->
                    ( model
                    , Cmd.none
                    )

                ListView _ ->
                    ( model
                    , Api.getGameForm ShowForm id
                    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InitGames result ->
            case result of
                Ok games ->
                    ( { model | view = ListView games }
                    , Cmd.none
                    )

                Err err ->
                    let
                        _ =
                            Debug.log "API call failed" err
                    in
                    ( model
                    , Cmd.none
                    )

        ShowForm result ->
            case result of
                Ok form ->
                    ( { model | view = FormView form, alert = Nothing }
                    , Cmd.none
                    )

                Err err ->
                    case err of
                        Api.ApplicationError code message _ ->
                            ( { model | alert = Just (Error message) }
                            , Navigation.replaceUrl model.navigationKey "#/games"
                            )

                        _ ->
                            ( { model | alert = Just (Error (Debug.toString err)) }
                            , Navigation.replaceUrl model.navigationKey "#/games"
                            )

        ChangeField id value ->
            case model.view of
                FormView form ->
                    ( { model | view = FormView (GameForm.updateField form id value) }
                    , Cmd.none
                    )

                _ ->
                    ( model
                    , Cmd.none
                    )

        ChangeFieldState id state ->
            case model.view of
                FormView form ->
                    ( { model | view = FormView (GameForm.updateState form id state) }
                    , Cmd.none
                    )

                _ ->
                    ( model
                    , Cmd.none
                    )

        ChangeImage id rawMetadata ->
            case model.view of
                FormView form ->
                    case GameForm.updateImage form id rawMetadata of
                        ( newForm, Just metadata ) ->
                            ( { model | view = FormView newForm }
                            , Image.loadPreview (OnLoadPreview id metadata) metadata
                            )

                        ( newForm, Nothing ) ->
                            ( { model | view = FormView newForm }
                            , Cmd.none
                            )

                _ ->
                    ( model
                    , Cmd.none
                    )

        ChangeAreaGeo geo ->
            case model.view of
                FormView form ->
                    let
                        newForm =
                            { form | areaGeo = geo }
                    in
                    ( { model | view = FormView newForm }
                    , Cmd.none
                    )

                _ ->
                    ( model
                    , Cmd.none
                    )

        ChangePrizeLocation location ->
            case model.view of
                FormView form ->
                    let
                        newForm =
                            { form | prizeLocation = location }
                    in
                    ( { model | view = FormView newForm }
                    , Cmd.none
                    )

                _ ->
                    ( model
                    , Cmd.none
                    )

        SaveGame ->
            case model.view of
                FormView form ->
                    case GameForm.validate form of
                        ( formWithErrors, False ) ->
                            ( { model | view = FormView formWithErrors, alert = Just (Error "Validation failed!") }
                            , Cmd.none
                            )

                        ( form_, True ) ->
                            ( { model | view = FormView { form_ | saveInProgress = True }, alert = Nothing }
                            , Api.saveGameForm OnSaveGame form_
                            )

                _ ->
                    ( model
                    , Cmd.none
                    )

        OnSaveGame result ->
            case model.view of
                FormView currentForm ->
                    let
                        ( newForm, alert_ ) =
                            case result of
                                Ok updatedForm ->
                                    ( { updatedForm | saveInProgress = False }, Just (Success "Game saved") )

                                Err err ->
                                    case err of
                                        Api.ApplicationError code status message ->
                                            ( { currentForm | saveInProgress = False }, Just (Error message) )

                                        _ ->
                                            ( { currentForm | saveInProgress = False }, Just (Error (Debug.toString err)) )

                        newModel =
                            { model | view = FormView newForm, alert = alert_ }
                    in
                    ( newModel
                    , Cmd.none
                    )

                _ ->
                    ( model
                    , Cmd.none
                    )

        OnLoadPreview id metadata result ->
            case model.view of
                FormView form ->
                    let
                        updateField field =
                            case result of
                                Ok url ->
                                    { field | preview = Loaded url metadata }

                                Err err ->
                                    { field | preview = NoPreview, error = Just (Image.displayError err) }

                        newForm =
                            case id of
                                Icon ->
                                    { form | icon = updateField form.icon }

                                Image ->
                                    { form | image = updateField form.image }
                    in
                    ( { model | view = FormView newForm }
                    , Cmd.none
                    )

                _ ->
                    ( model
                    , Cmd.none
                    )

        CloseAlert ->
            ( { model | alert = Nothing }
            , Cmd.none
            )


view : Model -> List (Html Msg)
view model =
    let
        subView =
            case model.view of
                ListView games ->
                    GameList.view games

                FormView form ->
                    GameForm.view form

        breadCrumbs =
            case model.view of
                ListView games ->
                    [ li [ class "active" ]
                        [ i [ class "fa fa-home" ]
                            []
                        , text "Games"
                        ]
                    ]

                FormView form ->
                    [ li []
                        [ i [ class "fa fa-home" ]
                            []
                        , a [ href "#/games" ]
                            [ text "Games"
                            ]
                        , text " | "
                        ]
                    , li [ class "active" ]
                        [ text form.name.value
                        ]
                    ]
    in
    [ div [ class "row" ]
        [ div [ class "col-md-12" ]
            [ ul [ class "breadcrumb" ]
                breadCrumbs
            ]
        ]
    , div [ class "row" ]
        [ alert model.alert
        ]
    , div [ class "content" ]
        [ div [ class "main-content" ]
            [ div [ class "row" ]
                [ div [ class "col-md-12" ]
                    subView
                ]
            ]
        ]
    ]


alert : Maybe Alert -> Html Msg
alert a =
    case a of
        Just (Success message) ->
            div [ class "alert alert-success alert-dismissible" ]
                [ button [ type_ "button", class "close", onClick CloseAlert ]
                    [ span [] [ text "×" ]
                    ]
                , h4 [] [ text "Ok" ]
                , p [] [ text message ]
                ]

        Just (Error message) ->
            div [ class "alert alert-danger alert-dismissible" ]
                [ button [ type_ "button", class "close", onClick CloseAlert ]
                    [ span [] [ text "×" ]
                    ]
                , h4 [] [ text "Error" ]
                , p [] [ text message ]
                ]

        Nothing ->
            div [] []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
