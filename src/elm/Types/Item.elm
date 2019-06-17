module Types.Item exposing (Item, Location, decoder, defaultLocation, json, locationDecoder, locationJson)

import Helpers.Json.Decode exposing (uuid)
import Helpers.Json.Encode as Encode
import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode exposing (Value)
import Uuid exposing (Uuid)


type alias LngLat =
    ( Float, Float )


type alias Location =
    { type_ : String
    , coordinates : LngLat
    }


type alias Item =
    { id : Uuid
    , gameID : Uuid
    , type_ : String
    , name : String
    , location : Location
    }



{- PUBLIC API -}


defaultLocation : Location
defaultLocation =
    { type_ = "Point"
    , coordinates = ( 18.0686, 59.3293 )
    }


decoder : Decoder Item
decoder =
    succeed Item
        |> required "itemID" uuid
        |> required "gameID" uuid
        |> required "type" string
        |> required "name" string
        |> required "location" locationDecoder


json : Item -> Encode.Value
json item =
    Encode.object
        [ ( "itemID", Encode.uuid item.id )
        , ( "gameID", Encode.uuid item.gameID )
        , ( "type", Encode.string item.type_ )
        , ( "name", Encode.string item.name )
        , ( "location", locationJson item.location )
        ]


locationDecoder : Decoder Location
locationDecoder =
    let
        lngLatDecoder =
            map2 (\a b -> ( a, b )) (index 0 float) (index 1 float)
    in
    succeed Location
        |> required "type" string
        |> required "coordinates" lngLatDecoder


locationJson : Location -> Encode.Value
locationJson location =
    let
        encodeLngLat ( lng, lat ) =
            Encode.list Encode.float [ lng, lat ]
    in
    Encode.object
        [ ( "type", Encode.string location.type_ )
        , ( "coordinates", encodeLngLat location.coordinates )
        ]
