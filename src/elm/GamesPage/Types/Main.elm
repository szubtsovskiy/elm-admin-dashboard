module GamesPage.Types.Main exposing (Alert(..), Model, Msg(..), View(..))

import Browser.Navigation as Navigation
import GamesPage.Helpers.Api as Api
import GamesPage.Types.Form exposing (FieldID, GameForm, ImageFieldID)
import MaskedInput.Number as NumberInput
import Random as Random
import Types.Area as Area
import Types.Game as Game exposing (Game)
import Types.Image as Image
import Types.Item as Item


type alias Model =
    { view : View
    , alert : Maybe Alert
    , seed : Random.Seed
    , navigationKey : Navigation.Key
    }


type Msg
    = InitGames (Result Api.Error (List Game))
    | ShowForm (Result Api.Error GameForm)
    | ChangeField FieldID String
    | ChangeFieldState FieldID NumberInput.State
    | ChangeImage ImageFieldID Image.RawMetadata
    | ChangeAreaGeo Area.Geo
    | ChangePrizeLocation Item.Location
    | SaveGame
    | OnSaveGame (Result Api.Error GameForm)
    | OnLoadPreview ImageFieldID Image.Metadata (Result Image.Error String)
    | CloseAlert


type View
    = ListView (List Game)
    | FormView GameForm


type Alert
    = Success String
    | Error String
