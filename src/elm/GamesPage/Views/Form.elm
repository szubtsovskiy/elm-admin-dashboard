port module GamesPage.Views.Form exposing (view)

import GamesPage.Types.Form exposing (Field, FieldID(..), FieldWithState, GameForm, ImageField, ImageFieldID(..), PreviewState(..))
import GamesPage.Types.Main exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, onInput, targetValue)
import Json.Decode as Json
import Json.Encode as Encode
import MaskedInput.Number as NumberInput
import Types.Area as Area
import Types.Image as Image
import Types.Item as Item
import Uuid



{- PUBLIC API -}


view : GameForm -> List (Html Msg)
view form =
    [ div [ class "row" ]
        [ div [ class "col-md-6" ]
            [ div [ class "widget" ]
                [ div [ class "widget-header" ]
                    [ h3 []
                        [ i [ class "fa fa-gamepad" ]
                            []
                        , text "Game Information"
                        ]
                    ]
                , div [ class "widget-content" ]
                    [ Html.form [ class "form-horizontal", attribute "role" "form" ]
                        [ input [ type_ "hidden", value (Uuid.toString form.gameID) ] []
                        , input [ type_ "hidden", value (Uuid.toString form.areaID) ] []
                        , formField Brand form
                        , formField Name form
                        , formField Description form
                        , formField Category form
                        , formField StartTime form
                        , formField EndTime form
                        , imageSelector Icon form.icon
                        , imageSelector Image form.image
                        ]
                    ]
                ]
            ]
        , div [ class "col-md-6" ]
            [ div [ class "row" ]
                [ div [ class "col-md-12" ]
                    [ div [ class "widget" ]
                        [ div [ class "widget-header" ]
                            [ h3 []
                                [ i [ class "fa fa-map" ]
                                    []
                                , text "Area"
                                ]
                            ]
                        , div [ class "widget-content" ]
                            [ Html.form [ class "form-horizontal", attribute "role" "form" ]
                                [ formField AreaName form
                                , areaEditor form
                                ]
                            ]
                        ]
                    ]
                ]
            , div [ class "row" ]
                [ div [ class "col-md-12" ]
                    [ div [ class "widget" ]
                        [ div [ class "widget-header" ]
                            [ h3 []
                                [ i [ class "fa fa-trophy" ]
                                    []
                                , text "Prize"
                                ]
                            ]
                        , div [ class "widget-content" ]
                            [ Html.form [ class "form-horizontal", attribute "role" "form" ]
                                [ formField PrizeName form
                                , formField MaxClaimDistance form
                                , formField ClaimCoolOff form
                                ]
                            ]
                        ]
                    ]
                ]
            , buttons form
            ]
        ]
    ]


formField : FieldID -> GameForm -> Html Msg
formField fieldID form =
    case fieldID of
        Brand ->
            textField fieldID form.brand

        Category ->
            customField fieldID form.category <|
                select [ id (Debug.toString fieldID), class "form-control", onChange (ChangeField fieldID) targetValue ]
                    [ option [ value "", selected (form.category.value == "") ]
                        [ text "" ]
                    , option [ value "Clothing", selected (form.category.value == "Clothing") ]
                        [ text "Clothing" ]
                    , option [ value "Finance & Banking!", selected (form.category.value == "Finance & Banking") ]
                        [ text "Finance & Banking" ]
                    , option [ value "Health & Fitness", selected (form.category.value == "Health & Fitness") ]
                        [ text "Health & Fitness" ]
                    , option [ value "Lifestyle", selected (form.category.value == "Lifestyle") ]
                        [ text "Lifestyle" ]
                    ]

        Name ->
            textField fieldID form.name

        Description ->
            customField fieldID form.description <|
                textarea [ id (Debug.toString fieldID), class "form-control", value form.description.value, onInput (ChangeField fieldID) ] []

        StartTime ->
            dateTimeField fieldID form.startTime

        EndTime ->
            dateTimeField fieldID form.endTime

        MaxClaimDistance ->
            textField fieldID form.maxClaimDistance

        ClaimCoolOff ->
            textField fieldID form.claimCoolOff

        AreaName ->
            textField fieldID form.areaName

        PrizeName ->
            textField fieldID form.prizeName


buttons : GameForm -> Html Msg
buttons form =
    div [ class "row" ]
        [ div [ class "col-sm-3 col-sm-offset-6" ]
            [ button [ class "btn btn-primary btn-block", type_ "button", onClick SaveGame, disabled form.saveInProgress ]
                [ i [ classList [ ( "fa", True ), ( "fa-save", not form.saveInProgress ), ( "fa-spinner fa-spin", form.saveInProgress ) ] ] []
                , text "Save"
                ]
            ]
        , div [ class "col-sm-3" ]
            [ a [ href "#/games", class "btn btn-default btn-block" ]
                [ text "Back"
                ]
            ]
        ]


textField : FieldID -> Field -> Html Msg
textField fieldID field =
    div [ classList [ ( "form-group", True ), ( "has-error has-feedback", field.error /= Nothing ) ] ]
        [ label [ class "col-sm-3 control-label", for (Debug.toString fieldID) ]
            [ text field.label ]
        , div [ class "col-sm-9" ]
            [ input [ id (Debug.toString fieldID), class "form-control", type_ "text", value field.value, onInput (ChangeField fieldID) ] []
            , span [ class "fa fa-close form-control-feedback", style "display" (feedbackDisplay field) ]
                []
            , p [ class "help-block" ]
                [ text (helpBlockText field)
                ]
            ]
        ]


dateTimeField : FieldID -> FieldWithState -> Html Msg
dateTimeField fieldID field =
    let
        mapMaybeInt maybeInt =
            case maybeInt of
                Just int ->
                    String.fromInt int

                Nothing ->
                    ""

        inputOptions =
            { pattern = "####-##-## ##:##:##"
            , inputCharacter = '#'
            , onInput = mapMaybeInt >> ChangeField fieldID
            , toMsg = ChangeFieldState fieldID
            , hasFocus = Nothing
            }

        fieldValue =
            String.toInt field.value
    in
    div [ classList [ ( "form-group", True ), ( "has-error has-feedback", field.error /= Nothing ) ] ]
        [ label [ class "col-sm-3 control-label", for (Debug.toString fieldID) ]
            [ text field.label ]
        , div [ class "col-sm-9" ]
            [ NumberInput.input inputOptions [ class "form-control" ] field.state fieldValue
            , span [ class "fa fa-close form-control-feedback", style "display" (feedbackDisplay field) ]
                []
            , p [ class "help-block" ]
                [ text (helpBlockText field)
                ]
            ]
        ]


customField : FieldID -> Field -> Html Msg -> Html Msg
customField id field inputGroup =
    div [ classList [ ( "form-group", True ), ( "has-error has-feedback", field.error /= Nothing ) ] ]
        [ label [ class "col-sm-3 control-label", for (Debug.toString id) ]
            [ text field.label ]
        , div [ class "col-sm-9" ]
            [ inputGroup
            , span [ class "fa fa-close form-control-feedback", style "display" (feedbackDisplay field) ]
                []
            , p [ class "help-block" ]
                [ text (helpBlockText field)
                ]
            ]
        ]


imageSelector : ImageFieldID -> ImageField -> Html Msg
imageSelector fieldID field =
    let
        targetImage =
            Json.at [ "target", "files" ] <|
                Json.at [ "0" ] Image.rawMetadataDecoder

        preview =
            case field.preview of
                NoPreview ->
                    case field.value of
                        "" ->
                            i [ class "fa fa-camera fa-3x" ] []

                        url ->
                            img [ src url ] []

                Loading _ ->
                    i [ class "fa fa-spinner fa-spin fa-3x" ] []

                Loaded url _ ->
                    img [ src url ] []
    in
    div [ classList [ ( "form-group", True ), ( "has-error has-feedback", field.error /= Nothing ) ] ]
        [ label [ class "col-sm-3 control-label", for (Debug.toString id) ]
            [ text field.label ]
        , div [ class "col-sm-9 image-field" ]
            [ div [ class "preview" ]
                [ preview
                ]
            , div [ class "input-group" ]
                [ input [ type_ "file", accept "image/*", onChange (ChangeImage fieldID) targetImage ]
                    []
                , p [ class "help-block" ]
                    [ text (helpBlockText field)
                    ]
                ]
            ]
        ]


areaEditor : GameForm -> Html Msg
areaEditor form =
    let
        onAreaChange =
            on "area-change" (Json.map ChangeAreaGeo (Json.field "detail" Area.geoDecoder))

        onPrizeChange =
            on "prize-change" (Json.map ChangePrizeLocation (Json.field "detail" Item.locationDecoder))

        area =
            attribute "data-area" (Encode.encode 0 (Area.geoJson form.areaGeo))

        prize =
            attribute "data-prize" (Encode.encode 0 (Item.locationJson form.prizeLocation))
    in
    node "area-editor" [ area, prize, onAreaChange, onPrizeChange ] []


feedbackDisplay : { a | error : Maybe String } -> String
feedbackDisplay field =
    Maybe.map (always "block") field.error
        |> Maybe.withDefault "none"


helpBlockText : { a | error : Maybe String, hint : Maybe String } -> String
helpBlockText field =
    Maybe.withDefault (Maybe.withDefault "" field.hint) field.error


onChange : (a -> msg) -> Json.Decoder a -> Attribute msg
onChange tagger decoder =
    on "change" (Json.map tagger decoder)
