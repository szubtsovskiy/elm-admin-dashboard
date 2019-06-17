module GamesPage.Types.Form exposing (Field, FieldID(..), FieldWithState, GameForm, ImageField, ImageFieldID(..), PreviewState(..), empty, getGameAndAreaAndPrize, getIconAndImage, new, updateField, updateImage, updateState, validate)

import MaskedInput.Number as NumberInput
import Types.Area as Area exposing (Area)
import Types.Game exposing (Game)
import Types.Image as Image
import Types.Item as Item exposing (Item)
import Uuid exposing (Uuid)


type alias Field =
    { label : String
    , value : String
    , hint : Maybe String
    , error : Maybe String
    }


type alias FieldWithState =
    { label : String
    , value : String
    , hint : Maybe String
    , error : Maybe String
    , state : NumberInput.State
    }


type alias ImageField =
    { label : String
    , value : String
    , hint : Maybe String
    , error : Maybe String
    , preview : PreviewState
    }


type alias GameForm =
    { gameID : Uuid
    , areaID : Uuid
    , prizeID : Uuid
    , brand : Field
    , category : Field
    , name : Field
    , description : Field
    , startTime : FieldWithState
    , endTime : FieldWithState
    , icon : ImageField
    , image : ImageField
    , maxClaimDistance : Field
    , claimCoolOff : Field
    , areaName : Field
    , areaGeo : Area.Geo
    , prizeName : Field
    , prizeLocation : Item.Location
    , saveInProgress : Bool
    }


type FieldID
    = Brand
    | Category
    | Name
    | Description
    | StartTime
    | EndTime
    | MaxClaimDistance
    | ClaimCoolOff
    | AreaName
    | PrizeName


type ImageFieldID
    = Icon
    | Image


type PreviewState
    = NoPreview
    | Loading Image.Metadata
    | Loaded String Image.Metadata



{- PUBLIC API -}


empty : Uuid -> Uuid -> Uuid -> GameForm
empty gameID areaID prizeID =
    { gameID = gameID
    , areaID = areaID
    , prizeID = prizeID
    , brand = { label = "Brand Display", value = "", hint = Nothing, error = Nothing }
    , category = { label = "Category", value = "", hint = Nothing, error = Nothing }
    , name = { label = "Name", value = "", hint = Nothing, error = Nothing }
    , startTime = { label = "Start Time", value = "", hint = Just "UTC date and time. Format: yyyy-MM-dd HH:mm:ss", error = Nothing, state = NumberInput.initialState }
    , endTime = { label = "End Time", value = "", hint = Just "UTC date and time. Format: yyyy-MM-dd HH:mm:ss", error = Nothing, state = NumberInput.initialState }
    , maxClaimDistance = { label = "Max Claim Distance", value = "", hint = Nothing, error = Nothing }
    , claimCoolOff = { label = "Claim Cool Off", value = "", hint = Nothing, error = Nothing }
    , description = { label = "Description", value = "", hint = Nothing, error = Nothing }
    , icon = { label = "Icon", value = "", hint = Just "JPEG, PNG, SVG or GIF image. Max 4 MB.", error = Nothing, preview = NoPreview }
    , image = { label = "Image", value = "", hint = Just "JPEG, PNG, SVG or GIF image. Max 4 MB.", error = Nothing, preview = NoPreview }
    , areaName = { label = "Name", value = "", hint = Nothing, error = Nothing }
    , areaGeo = Area.defaultGeo
    , prizeName = { label = "Name", value = "", hint = Nothing, error = Nothing }
    , prizeLocation = Item.defaultLocation
    , saveInProgress = False
    }


new : Game -> Area -> Item -> GameForm
new game area prize =
    let
        format dateTime =
            let
                -- 2006-01-02T15:04:05Z07:00
                date =
                    [ String.slice 0 4 dateTime, String.slice 5 7 dateTime, String.slice 8 10 dateTime ]

                time =
                    [ String.slice 11 13 dateTime, String.slice 14 16 dateTime, String.slice 17 19 dateTime ]
            in
            String.join "" (date ++ time)
    in
    { gameID = game.id
    , areaID = area.id
    , prizeID = prize.id
    , brand = { label = "Brand Display", value = game.brand, hint = Nothing, error = Nothing }
    , category = { label = "Category", value = game.category, hint = Nothing, error = Nothing }
    , name = { label = "Name", value = game.name, hint = Nothing, error = Nothing }
    , startTime = { label = "Start Time", value = format game.startTime, hint = Just "UTC date and time. Format: yyyy-MM-dd HH:mm:ss", error = Nothing, state = NumberInput.initialState }
    , endTime = { label = "End Time", value = format game.endTime, hint = Just "UTC date and time. Format: yyyy-MM-dd HH:mm:ss", error = Nothing, state = NumberInput.initialState }
    , maxClaimDistance = { label = "Max Claim Distance", value = String.fromInt game.maxClaimDistance, hint = Nothing, error = Nothing }
    , claimCoolOff = { label = "Claim Cool Off", value = String.fromInt game.claimCoolOff, hint = Nothing, error = Nothing }
    , description = { label = "Description", value = game.description, hint = Nothing, error = Nothing }
    , icon = { label = "Icon", value = game.iconUrl, hint = Just "JPEG, PNG, SVG or GIF image. Max 4 MB.", error = Nothing, preview = NoPreview }
    , image = { label = "Image", value = game.imageUrl, hint = Just "JPEG, PNG, SVG or GIF image. Max 4 MB.", error = Nothing, preview = NoPreview }
    , areaName = { label = "Name", value = area.name, hint = Nothing, error = Nothing }
    , areaGeo = area.geo
    , prizeName = { label = "Name", value = prize.name, hint = Nothing, error = Nothing }
    , prizeLocation = prize.location
    , saveInProgress = False
    }


getGameAndAreaAndPrize : GameForm -> ( Game, Area, Item )
getGameAndAreaAndPrize form =
    let
        format dateTime =
            let
                date =
                    [ String.slice 0 4 dateTime, String.slice 4 6 dateTime, String.slice 6 8 dateTime ]

                time =
                    [ String.slice 8 10 dateTime, String.slice 10 12 dateTime, String.slice 12 14 dateTime ]
            in
            String.join "-" date ++ "T" ++ String.join ":" time ++ "Z"

        game =
            { id = form.gameID
            , areaID = form.areaID
            , brand = form.brand.value
            , category = form.category.value
            , name = form.name.value
            , description = form.description.value
            , startTime = format form.startTime.value
            , endTime = format form.endTime.value
            , iconUrl = form.icon.value
            , imageUrl = form.image.value
            , maxClaimDistance = Maybe.withDefault 0 (String.toInt form.maxClaimDistance.value)
            , claimCoolOff = Maybe.withDefault 0 (String.toInt form.claimCoolOff.value)
            }

        area =
            { id = form.areaID
            , name = form.areaName.value
            , geo = form.areaGeo
            }

        prize =
            { id = form.prizeID
            , gameID = form.gameID
            , type_ = "Prize"
            , name = form.prizeName.value
            , location = form.prizeLocation
            }
    in
    ( game, area, prize )


getIconAndImage : GameForm -> ( Maybe Image.Metadata, Maybe Image.Metadata )
getIconAndImage form =
    let
        toMetadata imageField =
            case imageField.preview of
                NoPreview ->
                    Nothing

                Loading _ ->
                    Nothing

                Loaded _ metadata ->
                    Just metadata
    in
    ( toMetadata form.icon, toMetadata form.image )


updateField : GameForm -> FieldID -> String -> GameForm
updateField form fieldID value =
    let
        ok field newValue =
            { field | value = newValue, error = Nothing }

        error field badValue err =
            { field | value = badValue, error = Just err }
    in
    case fieldID of
        Name ->
            { form | name = ok form.name value }

        Category ->
            { form | category = ok form.category value }

        Brand ->
            { form | brand = ok form.brand value }

        StartTime ->
            { form | startTime = ok form.startTime value }

        EndTime ->
            { form | endTime = ok form.endTime value }

        MaxClaimDistance ->
            if String.isEmpty (String.trim value) then
                { form | maxClaimDistance = ok form.maxClaimDistance "" }

            else
                case String.toInt value of
                    Just _ ->
                        { form | maxClaimDistance = ok form.maxClaimDistance value }

                    Nothing ->
                        { form | maxClaimDistance = error form.maxClaimDistance value "Not a number" }

        ClaimCoolOff ->
            if String.isEmpty (String.trim value) then
                { form | claimCoolOff = ok form.claimCoolOff "" }

            else
                case String.toInt value of
                    Just _ ->
                        { form | claimCoolOff = ok form.claimCoolOff value }

                    Nothing ->
                        { form | claimCoolOff = error form.claimCoolOff value "Not a number" }

        Description ->
            { form | description = ok form.description value }

        AreaName ->
            { form | areaName = ok form.areaName value }

        PrizeName ->
            { form | prizeName = ok form.prizeName value }


updateState : GameForm -> FieldID -> NumberInput.State -> GameForm
updateState form id state =
    case id of
        StartTime ->
            let
                field =
                    form.startTime
            in
            { form | startTime = { field | state = state } }

        EndTime ->
            let
                field =
                    form.endTime
            in
            { form | endTime = { field | state = state } }

        _ ->
            form


updateImage : GameForm -> ImageFieldID -> Image.RawMetadata -> ( GameForm, Maybe Image.Metadata )
updateImage form id rawMetadata =
    if isValidSize rawMetadata.size then
        case Image.toMetadata rawMetadata of
            Ok metadata ->
                let
                    setPreview field metadata_ =
                        { field | preview = Loading metadata_, error = Nothing }
                in
                case id of
                    Icon ->
                        ( { form | icon = setPreview form.icon metadata }, Just metadata )

                    Image ->
                        ( { form | image = setPreview form.image metadata }, Just metadata )

            Err err ->
                let
                    error field  =
                        { field | error = Just err }
                in
                case id of
                    Icon ->
                        ( { form | icon = error form.icon }, Nothing )

                    Image ->
                        ( { form | image = error form.image }, Nothing )

    else
        let
            error field err =
                { field | error = Just err }
        in
        case id of
            Icon ->
                ( { form | icon = error form.icon "File is too big!" }, Nothing )

            Image ->
                ( { form | image = error form.image "File is too big" }, Nothing )


validate : GameForm -> ( GameForm, Bool )
validate form =
    let
        validateRequired field =
            if String.isEmpty (String.trim field.value) then
                { field | error = Just "A value is required" }

            else
                { field | error = Nothing }

        validateImageField field =
            if field.error /= Nothing then
                field

            else if String.isEmpty (String.trim field.value) then
                case field.preview of
                    NoPreview ->
                        { field | error = Just "A value is required" }

                    Loading _ ->
                        { field | error = Just "A value is required" }

                    Loaded _ _ ->
                        { field | error = Nothing }

            else
                { field | error = Nothing }

        validateDateTime field =
            if String.length (String.trim field.value) == 0 then
                { field | error = Just "A value is required" }

            else if String.length (String.trim field.value) /= 14 then
                { field | error = Just "Invalid date and time" }

            else
                { field | error = Nothing }

        validatedForm =
            { form
                | brand = validateRequired form.brand
                , category = validateRequired form.category
                , name = validateRequired form.name
                , startTime = validateDateTime form.startTime
                , endTime = validateDateTime form.endTime
                , maxClaimDistance = validateRequired form.maxClaimDistance
                , claimCoolOff = validateRequired form.claimCoolOff
                , description = validateRequired form.description
                , icon = validateImageField form.icon
                , image = validateImageField form.image
                , areaName = validateRequired form.areaName
                , prizeName = validateRequired form.prizeName
            }

        isValid field =
            field.error == Nothing

        isValidForm =
            isValid validatedForm.brand
                && isValid validatedForm.category
                && isValid validatedForm.name
                && isValid validatedForm.startTime
                && isValid validatedForm.endTime
                && isValid validatedForm.maxClaimDistance
                && isValid validatedForm.claimCoolOff
                && isValid validatedForm.description
                && isValid validatedForm.icon
                && isValid validatedForm.image
                && isValid validatedForm.areaName
                && isValid validatedForm.prizeName
    in
    ( validatedForm, isValidForm )


isValidSize : Int -> Bool
isValidSize size =
    size <= 4 * 1024 * 1024

