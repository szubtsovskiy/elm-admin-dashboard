module GamesPage.Helpers.Api exposing (Error(..), getGameForm, getGames, saveGameForm)

import GamesPage.Types.Form as GameForm exposing (GameForm)
import Http
import Json.Decode as Json exposing (Decoder, field, list, string)
import Json.Encode as Encode
import Task exposing (Task, andThen, attempt, fail, map, mapError, succeed)
import Types.Area as Area exposing (Area)
import Types.Game as Game exposing (Game)
import Types.Image as Image exposing (Type(..))
import Types.Item as Item exposing (Item)
import Uuid exposing (Uuid)


type alias WithID a =
    { a | id : Uuid }


type Error
    = InternalError
    | Timeout
    | NetworkError
    | ApplicationError Int String String



{- PUBLIC API -}


getGames : (Result Error (List Game) -> msg) -> Cmd msg
getGames resultTagger =
    let
        mapError result =
            Result.mapError toApiError result
    in
    Http.get "/api/v1/games/" (list Game.decoder)
        |> Http.send (mapError >> resultTagger)


getGameForm : (Result Error GameForm -> msg) -> Uuid -> Cmd msg
getGameForm resultTagger gameID =
    let
        isPrize item =
            item.type_ == "Prize"

        getGame =
            getObject "/api/v1/games/" gameID Game.decoder
                |> mapError toApiError

        getArea game =
            getObject "/api/v1/areas/" game.areaID Area.decoder
                |> map (\area -> ( game, area ))
                |> mapError toApiError

        getItems ( game, area ) =
            getObjects ("/api/v1/games/" ++ Uuid.toString game.id ++ "/items/") (list Item.decoder)
                |> map (\items -> ( game, area, items ))
                |> mapError toApiError

        findPrize ( game, area, items ) =
            case List.filter isPrize items of
                [] ->
                    let
                        errorPayload =
                            Encode.list Item.json items
                                |> Encode.encode 0
                    in
                    fail (ApplicationError 404 "Game does not have prize" errorPayload)

                prize :: _ ->
                    succeed ( game, area, prize )

        createForm ( game, area, prize ) =
            GameForm.new game area prize
    in
    getGame
        |> andThen getArea
        |> andThen getItems
        |> andThen findPrize
        |> map createForm
        |> attempt resultTagger


saveGameForm : (Result Error GameForm -> msg) -> GameForm -> Cmd msg
saveGameForm resultTagger form =
    let
        ( game, area, prize ) =
            GameForm.getGameAndAreaAndPrize form

        ( icon, image ) =
            GameForm.getIconAndImage form

        uploadIcon =
            upload icon
                |> map (\maybeIconUrl -> { game | iconUrl = Maybe.withDefault game.iconUrl maybeIconUrl })

        uploadImage game_ =
            upload image
                |> map (\maybeImageUrl -> { game_ | imageUrl = Maybe.withDefault game_.imageUrl maybeImageUrl })

        saveGame game_ =
            putObject "/api/v1/games/" game_ Game.json Game.decoder
                |> mapError toApiError

        saveArea game_ =
            putObject "/api/v1/areas/" area Area.json Area.decoder
                |> map (\area_ -> ( game_, area_ ))
                |> mapError toApiError

        savePrize ( game_, area_ ) =
            putObject "/api/v1/items/" prize Item.json Item.decoder
                |> map (\prize_ -> ( game_, area_, prize_ ))
                |> mapError toApiError

        createForm ( game_, area_, prize_ ) =
            GameForm.new game_ area_ prize_
    in
    uploadIcon
        |> andThen uploadImage
        |> andThen saveGame
        |> andThen saveArea
        |> andThen savePrize
        |> map createForm
        |> attempt resultTagger



{- PRIVATE API -}


put : String -> Http.Body -> Decoder a -> Http.Request a
put url body decoder =
    Http.request
        { method = "PUT"
        , headers = []
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }


getObject : String -> Uuid -> Decoder a -> Task Http.Error a
getObject collectionUrl id decoder =
    Http.get (collectionUrl ++ Uuid.toString id) decoder
        |> Http.toTask


getObjects : String -> Decoder a -> Task Http.Error a
getObjects collectionUrl decoder =
    Http.get collectionUrl decoder
        |> Http.toTask


putObject : String -> WithID a -> (WithID a -> Encode.Value) -> Decoder (WithID a) -> Task Http.Error (WithID a)
putObject collectionUrl obj encode responseDecoder =
    let
        objUrl =
            collectionUrl ++ Uuid.toString obj.id

        payload =
            encode obj
                |> Http.jsonBody
    in
    put objUrl payload responseDecoder
        |> Http.toTask


upload : Maybe Image.Metadata -> Task Error (Maybe String)
upload maybeMetadata =
    case maybeMetadata of
        Just metadata ->
            let
                createBody fileName  =
                    Http.multipartBody
                        [ Http.stringPart "name" fileName
                        , Image.filePart "file" metadata
                        ]

                doUpload body  =
                    Http.post "/api/v1/files/" body decoder
                        |> Http.toTask
                        |> mapError toApiError

                decoder =
                    field "url" string
                        |> Json.map Just
            in
            Image.hash metadata
                |> mapError (always InternalError)
                |> map (\hash -> genFileName metadata hash)
                |> map (\fileName -> createBody fileName )
                |> andThen (\body -> doUpload body )

        Nothing ->
            Task.succeed Nothing


genFileName : Image.Metadata -> String -> String
genFileName metadata hash =
    let
        extStart =
            String.indices "." metadata.name
                |> List.reverse
                |> List.head

        ext =
            case extStart of
                Just i ->
                    String.dropLeft i metadata.name

                Nothing ->
                    defaultExt metadata.type_

        fileName =
            hash ++ ext
    in
    fileName


defaultExt : Image.Type -> String
defaultExt type_ =
    case type_ of
        Jpeg ->
            ".jpg"

        Png ->
            ".png"

        Gif ->
            ".gif"

        Svg ->
            ".svg"


toApiError : Http.Error -> Error
toApiError httpError =
    case httpError of
        Http.BadUrl url ->
            let
                _ =
                    Debug.log "Internal error: bad URL" url
            in
            InternalError

        Http.Timeout ->
            Timeout

        Http.NetworkError ->
            NetworkError

        Http.BadStatus response ->
            let
                _ =
                    Debug.log "Application error" response
            in
            ApplicationError response.status.code response.status.message response.body

        Http.BadPayload description _ ->
            let
                _ =
                    Debug.log "Internal error: bad payload" description
            in
            InternalError
