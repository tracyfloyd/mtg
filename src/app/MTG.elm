module MTG where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json

import Signal exposing (Address)
import Effects exposing (Effects)
import StartApp exposing (App)


-- TYPE DEFINITIONS --


type alias Id = Int

type alias Player =
  { id: Id
  , name: String
  , color: String
  , life: Int
  , edit: Bool
  , nameEdit: String
  }

type alias Players = List Player


-- MODEL DEFINITION --


type alias Model = 
  { players: Players 
  , activePlayers: Int
  }


-- ACTIONS LIST --


type Action 
  = NoOp
  | ResetGame
  | IncreasePlayers
  | DecreasePlayers
  | CyclePlayerColor Id
  | UpdateLife Id Int
  | EnableNameInput Id
  | UpdateNameInput Id String
  | SaveNameInput Id


-- HELPER FUNCTIONS --


onInput : Address a -> (String -> a) -> Attribute
onInput address f =
  on "input" targetValue (\v -> Signal.message address (f v))


onEnter : Address a -> a -> Attribute
onEnter address value =
  on "keydown"
    (Json.customDecoder keyCode is13)
    (\_ -> Signal.message address value)


is13 : Int -> Result String ()
is13 code =
  if code == 13 then Ok () else Err "not the right key code"


getNextColor : String -> String
getNextColor currentColor =
  let
    colorList = [ "red", "green", "black", "blue", "white" ]
    findNext list color =
      case list of
        []         -> Nothing
        head::[]   -> List.head colorList
        head::tail -> if head == color then List.head tail else findNext tail color
  in
    case (findNext colorList currentColor) of
      Just newColor -> newColor
      Nothing       -> currentColor



-- INITIAL MODEL --


newPlayer : Id -> String -> String -> Player
newPlayer id name color =
  { id = id
  , name = name
  , color = color
  , life = 20
  , edit = False
  , nameEdit = name
  }


initialModel : Model
initialModel =
  { players = 
      [ newPlayer 1 "Player 1" "red"
      , newPlayer 2 "Player 2" "green"
      , newPlayer 3 "Player 3" "black"
      , newPlayer 4 "Player 4" "blue"
      , newPlayer 5 "Player 5" "white"
      ]
  , activePlayers = 2
  }


-- UPDATE --


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NoOp ->
      ( model, Effects.none )

    ResetGame ->
      ( { model | players = List.map (\player -> { player | life = 20 }) model.players }
      , Effects.none
      )

    IncreasePlayers ->
      if model.activePlayers < 5 then
        ( { model | activePlayers = model.activePlayers + 1 }
        , Effects.none
        )
      else
        ( model
        , Effects.none 
        )

    DecreasePlayers ->
      if model.activePlayers > 2 then
        ( { model | activePlayers = model.activePlayers - 1 }
        , Effects.none
        )
      else
        ( model
        , Effects.none
        )

    CyclePlayerColor id ->
      let
        changeColor player =
          if player.id == id then
            { player | color = getNextColor player.color }
          else
            player
      in
        ( { model | players = List.map changeColor model.players }
        , Effects.none
        )

    UpdateLife id life ->
      let
        setLife player =
          if player.id == id then
            { player | life = player.life + life }
          else
            player
      in
        ( { model | players = List.map setLife model.players }
        , Effects.none
        )

    UpdateNameInput id val ->
      let
        setNameEdit player =
          if player.id == id then
            { player | nameEdit = val }
          else
            player
      in
        ( { model | players = List.map setNameEdit model.players }
        , Effects.none
        )

    EnableNameInput id ->
      let
        editPlayer player =
          if player.id == id then
            { player | edit = True }
          else
            player
      in
        ( { model | players = List.map editPlayer model.players }
        , Effects.none
        )

    SaveNameInput id ->
      let
        setName player =
          if player.id == id && player.nameEdit /= "" then
            { player | name = player.nameEdit, edit = False }
          else
            player
      in
        ( { model | players = List.map setName model.players }
        , Effects.none
        )


-- VIEWS --


nameContainer : Address Action -> Player -> Html
nameContainer address player =
  if player.edit then
    div 
      [ class "name-container" ] 
      [ div
          [ class "form" ]
          [ input 
            [ type' "text"
            , placeholder player.name
            , value player.nameEdit
            , name "player_name"
            , autofocus True
            , onInput address (UpdateNameInput player.id)
            , onEnter address (SaveNameInput player.id)
            ]
            []
          , button 
              [ class "submit", onClick address (SaveNameInput player.id) ] 
              [ text "Save" ]
          ]
      ]
  else
    div 
      [ class "name-container" ] 
      [ div 
          [ class "name", onClick address (EnableNameInput player.id) ] 
          [ (text player.name) ] 
      ]


playerBox : Address Action -> Player -> Html
playerBox address player =
  div
    [ classList 
        [ ("player " ++ player.color,  True ) 
        , ("deceased", player.life <= 0)
        ]
    ]
    [ nameContainer address player
    , div 
        [ class "life-container", onClick address (CyclePlayerColor player.id) ] 
        [ div [ class "life" ] [ text (toString player.life) ] ]
    , div 
        [ class "options-container" ] 
        [ div 
            [ class "options-row" ] 
            [ div 
                [ class "option", onClick address (UpdateLife player.id 1) ] 
                [ button [] [ (text "+1") ] ]
            , div 
                [ class "option", onClick address (UpdateLife player.id 5) ] 
                [ button [] [ (text "+5") ] ]
            ]
        , div 
            [ class "options-row" ] 
            [ div 
                [ class "option", onClick address (UpdateLife player.id -1) ] 
                [ button [] [ (text "-1") ] ]
            , div 
                [ class "option", onClick address (UpdateLife player.id -5) ] 
                [ button [] [ (text "-5") ] ]
            ]
        ]
    ]


playersContainer : Address Action -> Players -> Html
playersContainer address players =
  let
    playersList = (List.map (playerBox address) players)
    playersCount = (List.length players)
  in
    div
      [ class "overflow-container" ]
      [ div 
          [ class ("players-container players-" ++ (toString playersCount)) ]
          playersList
      ]


gameOptionsContainer : Address Action -> Model -> Html
gameOptionsContainer address model =
  div 
    [ class "game-options-container" ]
    [ div
        [ class "game-option" ]
        [ button 
            [ class "option-reset", onClick address ResetGame ] 
            [ (text "Reset Game") ] 
        ]
    , div
        [ class "game-option option-group" ]
        [ button 
            [ class "option" 
            , disabled (model.activePlayers == 2)
            , onClick address DecreasePlayers 
            ] 
            [ (text "Remove Player") ]
        , button 
            [ class "option"
            , disabled (model.activePlayers == 5)
            , onClick address IncreasePlayers 
            ] 
            [ (text "Add Player") ] 
        ]
    ]


-- MAIN VIEW --


view : Address Action -> Model -> Html
view address model =
  div 
    [ class "board" ]
    [ gameOptionsContainer address model
    , playersContainer address (List.take model.activePlayers model.players)
    ]


-- INIT --


loadModel : Model
loadModel = 
  Maybe.withDefault initialModel getStorage


init : (Model, Effects Action)
init =
  (loadModel, Effects.none)


-- APP CONFIG --


app =
  StartApp.start
    { view = view
    , update = update
    , init = init
    , inputs = []
    }


-- PORTS --


-- Input port (from JS)
port getStorage : Maybe Model


-- Output port (send to JS)
port setStorage : Signal Model
port setStorage = app.model


-- APP INITIALIZATION -- 


main : Signal Html
main =
  app.html