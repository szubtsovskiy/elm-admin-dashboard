module Types.Area exposing (Area, Geo, decoder, defaultGeo, geoDecoder, geoJson, json)

import Helpers.Json.Decode exposing (uuid)
import Helpers.Json.Encode as Encode
import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode exposing (Value)
import Uuid exposing (Uuid)


type alias LngLat =
    ( Float, Float )


type alias Geo =
    { type_ : String
    , coordinates : List (List LngLat)
    }


type alias Area =
    { id : Uuid
    , name : String
    , geo : Geo
    }



{- PUBLIC API -}


defaultGeo : Geo
defaultGeo =
    { type_ = "Polygon"
    , coordinates =
        [ [ ( 17.99358, 59.38991 )
          , ( 18.15965, 59.38991 )
          , ( 18.15965, 59.30267 )
          , ( 17.99358, 59.30267 )
          , ( 17.99358, 59.38991 )
          ]
        ]
    }


decoder : Decoder Area
decoder =
    succeed Area
        |> required "areaID" uuid
        |> required "name" string
        |> required "geo" geoDecoder


json : Area -> Encode.Value
json area =
    Encode.object
        [ ("areaID", Encode.uuid area.id)
        , ("name", Encode.string area.name)
        , ("geo", geoJson area.geo)
        ]


geoDecoder : Decoder Geo
geoDecoder =
    let
        lngLatDecoder =
            map2 (\a b -> ( a, b )) (index 0 float) (index 1 float)
    in
    succeed Geo
        |> required "type" string
        |> required "coordinates" (list (list lngLatDecoder))


geoJson : Geo -> Encode.Value
geoJson geo =
    let
        encodeLngLat ( lng, lat ) =
            Encode.list Encode.float [ lng, lat ]

        encodeRing ring =
            Encode.list encodeLngLat ring
    in
    Encode.object
        [ ("type", Encode.string geo.type_)
        , ("coordinates", Encode.list encodeRing geo.coordinates)
        ]
