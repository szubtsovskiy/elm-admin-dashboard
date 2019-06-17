module Types.Image exposing (Error, Metadata, RawMetadata, Type(..), displayError, filePart, hash, loadPreview, rawMetadataDecoder, toMetadata)

import Http
import Json.Decode exposing (Decoder, andThen, at, fail, field, int, map4, string, succeed, value)
import Task exposing (Task)


type alias FileRef =
    Json.Decode.Value


type alias Metadata =
    { name : String
    , type_ : Type
    , size : Int
    , ref : FileRef
    }


type alias RawMetadata =
    { name : String
    , type_ : String
    , size : Int
    , ref : FileRef
    }


type Error
    = ReadError
    | NoValidBlob


type Type
    = Jpeg
    | Png
    | Gif
    | Svg



-- PUBLIC API


{-| Decoder to extract raw metadata from DOM event. Required to validate image type after decoding
to bypass Elm issue with silent swallowing of decoding errors when parsing DOM events.
-}
rawMetadataDecoder : Decoder RawMetadata
rawMetadataDecoder =
    map4 RawMetadata
        (field "name" string)
        (field "type" string)
        (field "size" int)
        value


toMetadata : RawMetadata -> Result String Metadata
toMetadata rawMetadata =
    case rawMetadata.type_ of
        "image/jpeg" ->
            Ok (Metadata rawMetadata.name Jpeg rawMetadata.size rawMetadata.ref)

        "image/png" ->
            Ok (Metadata rawMetadata.name Png rawMetadata.size rawMetadata.ref)

        "image/gif" ->
            Ok (Metadata rawMetadata.name Gif rawMetadata.size rawMetadata.ref)

        "image/svg+xml" ->
            Ok (Metadata rawMetadata.name Svg rawMetadata.size rawMetadata.ref)

        _ ->
            Err ("Unsupported image type: " ++ rawMetadata.type_)


loadPreview : (Result Error String -> msg) -> Metadata -> Cmd msg
loadPreview resultTagger metadata =
--    Native.FileReader.readAsDataUrl metadata.ref
--        |> Task.attempt resultTagger
    Debug.todo "Image.loadPreview not implemented"


hash : Metadata -> Task Error String
hash metadata =
--    Native.FileReader.fileHash metadata.ref
    Debug.todo "Image.hash not implemented"


filePart : String -> Metadata -> Http.Part
filePart name metadata =
--    Native.FileReader.filePart name metadata.ref
    Debug.todo "Image.filePart not implemented"


displayError : Error -> String
displayError err =
    case err of
        ReadError ->
            "File could not be read"

        NoValidBlob ->
            "Not valid binary file"



