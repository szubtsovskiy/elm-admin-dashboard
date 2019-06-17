module Types.Game exposing (Game, decoder, json)

import Helpers.Json.Decode exposing (uuid)
import Helpers.Json.Encode as Encode
import Json.Decode exposing (Decoder, int, string, succeed)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode exposing (Value)
import Uuid exposing (Uuid)


type alias Game =
    { id : Uuid
    , areaID : Uuid
    , brand : String
    , category : String
    , name : String
    , description : String
    , startTime : String
    , endTime : String
    , iconUrl : String
    , imageUrl : String
    , maxClaimDistance : Int
    , claimCoolOff : Int
    }



{- PUBLIC API -}


decoder : Decoder Game
decoder =
    succeed Game
        |> required "gameID" uuid
        |> required "areaID" uuid
        |> required "brand" string
        |> required "category" string
        |> required "name" string
        |> required "description" string
        |> required "startTime" string
        |> required "endTime" string
        |> required "iconUrl" string
        |> required "imageUrl" string
        |> required "claimMaxDist" int
        |> required "claimCoolOff" int


json : Game -> Value
json game =
    Encode.object
        [ ("gameID", Encode.uuid game.id)
        , ("areaID", Encode.uuid game.areaID)
        , ("brand", Encode.string game.brand)
        , ("category", Encode.string game.category)
        , ("name", Encode.string game.name)
        , ("description", Encode.string game.description)
        , ("startTime", Encode.string game.startTime)
        , ("endTime", Encode.string game.endTime)
        , ("iconUrl", Encode.string game.iconUrl)
        , ("imageUrl", Encode.string game.imageUrl)
        , ("claimMaxDist", Encode.int game.maxClaimDistance)
        , ("claimCoolOff", Encode.int game.claimCoolOff)
        ]
