module Helpers.Json.Decode exposing (uuid)

import Json.Decode exposing (..)
import Uuid exposing (Uuid)


uuid : Decoder Uuid
uuid =
    let
        uuidParser s =
            case Uuid.fromString s of
                Just uuid_ ->
                    succeed uuid_

                Nothing ->
                    fail ("Invalid UUID: " ++ s)
    in
    string
        |> andThen uuidParser
