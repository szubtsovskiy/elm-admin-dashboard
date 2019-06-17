module Helpers.Json.Encode exposing (uuid)

import Json.Encode exposing (..)
import Uuid exposing (Uuid)


uuid : Uuid -> Value
uuid =
    string << Uuid.toString
