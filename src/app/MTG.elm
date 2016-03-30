module MTG (..) where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Time
import Signal exposing (Address)
import Effects exposing (Effects)
import StartApp exposing (App)


-- TYPE DEFINITIONS --


type alias Id =
  Int


type alias Player =
  { id : Id
  , name : String
  , color : String
  , life : Int
  , edit : Bool
  , nameEdit : String
  , wins : Int
  }


type alias Players =
  List Player


-- MODEL DEFINITION --


type alias Model =
  { players : Players
  , activePlayers : Int
  , currentTime : Int
  , timeIsRunning : Bool
  }


-- ACTIONS LIST --


type Action
  = NoOp
  | IncrementTimer
  | StartStopTimer
  | ResetGame
  | ResetWins
  | IncreasePlayers
  | DecreasePlayers
  | CyclePlayerColor Id
  | UpdateLife Id Int
  | EnableNameInput Id
  | UpdateNameInput Id String
  | SaveNameInput Id
  | IncreaseWins Id
  | DecreaseWins Id


-- HELPER FUNCTIONS --


onInput : Address a -> (String -> a) -> Attribute
onInput address f =
  on "input" targetValue (\v -> Signal.message address (f v))


onEnter : Address a -> a -> Attribute
onEnter address value =
  on
    "keydown"
    (Json.customDecoder keyCode is13)
    (\_ -> Signal.message address value)


is13 : Int -> Result String ()
is13 code =
  if code == 13 then
    Ok ()
  else
    Err "not the right key code"


getNextColor : String -> String
getNextColor currentColor =
  let
    colorList =
      [ "red", "green", "black", "blue", "white" ]

    findNext list color =
      case list of
        [] ->
          Nothing

        head :: [] ->
          List.head colorList

        head :: tail ->
          if head == color then
            List.head tail
          else
            findNext tail color
  in
    case (findNext colorList currentColor) of
      Just newColor ->
        newColor

      Nothing ->
        currentColor


secondsToTimeStr : Int -> String
secondsToTimeStr seconds =
  let
    secs = toFloat(seconds)
    h = floor(secs / 3600)
    m = floor((secs - toFloat(h * 3600)) / 60)
    s = floor(secs - toFloat(h * 3600) - toFloat(m * 60))
    
    timeToStr t =
      if t < 10 then
        "0" ++ toString(t)
      else
        toString(t)
  in
    timeToStr(h) ++ ":" ++ timeToStr(m) ++ ":" ++ timeToStr(s)


getAlivePlayers : Int -> Players -> Players
getAlivePlayers activePlayersCount playersList =
  let
    activePlayersList = List.take activePlayersCount playersList
  in
    activePlayersList
    |> List.filter (\p -> p.life > 0)


countAlivePlayers : Int -> Players -> Int
countAlivePlayers activePlayersCount playersList =
  List.length (getAlivePlayers activePlayersCount playersList)


-- INITIAL MODEL --


newPlayer : Id -> String -> String -> Player
newPlayer id name color =
  { id = id
  , name = name
  , color = color
  , life = 20
  , edit = False
  , nameEdit = name
  , wins = 0
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
  , currentTime = 0
  , timeIsRunning = False
  }


-- UPDATE --


update : Action -> Model -> ( Model, Effects Action )
update action model =
  case action of
    NoOp ->
      ( model, Effects.none )

    IncrementTimer ->
      if model.timeIsRunning == True then
        ( { model | currentTime = model.currentTime + 1 }
        , Effects.none
        )
      else
        ( model, Effects.none )

    StartStopTimer ->
      ( { model | timeIsRunning = not model.timeIsRunning }
      , Effects.none
      )

    ResetGame ->
      ( { model 
            | players = List.map (\player -> { player | life = 20 }) model.players
            , currentTime = 0
            , timeIsRunning = False
        }
      , Effects.none
      )

    ResetWins ->
      ( { model | players = List.map (\player -> { player | wins = 0 }) model.players }
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

        playersList = List.map setLife model.players
        playersAliveCount = countAlivePlayers model.activePlayers playersList
      in
        ( { model 
              | players = playersList
              , timeIsRunning = playersAliveCount > 1
          }
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

    IncreaseWins id ->
      let
        addWin player =
          if player.id == id then
            { player | wins = player.wins + 1 }
          else
            player
      in
        ( { model | players = List.map addWin model.players }
        , Effects.none
        )

    DecreaseWins id ->
      let
        removeWin player =
          if player.id == id && player.wins > 0 then
            { player | wins = player.wins - 1 }
          else
            player
      in
        ( { model | players = List.map removeWin model.players }
        , Effects.none
        )


-- VIEWS --


timerContainer : Address Action -> Model -> Html
timerContainer address model =
  let
    startStopBtnTxt =
      if model.timeIsRunning == True then
        "Stop"
      else
        "Start"
  in
    div
      [ classList 
          [ ("timer-container", True)
          , ("running", model.timeIsRunning) 
          ]
      ]
      [ div
          [ class "timer" ]
          [ text (secondsToTimeStr model.currentTime) ]
      , button
          [ class "btn-sm", onClick address StartStopTimer ]
          [ (text startStopBtnTxt) ]
      ]


gameOptionsContainer : Address Action -> Model -> Html
gameOptionsContainer address model =
  div
    [ class "game-options-container" ]
    [ div
        [ class "game-option option-group" ]
        [ button
            [ class "option-reset-game", onClick address ResetGame ]
            [ (text "Reset Game") ]
        , button
            [ class "option-reset-wins", onClick address ResetWins ]
            [ (text "Reset Wins") ]
        ]
    , div
        [ class "game-option" ]
        [ timerContainer address model ]
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
        [ ( "player " ++ player.color, True )
        , ( "deceased", player.life <= 0 )
        ]
    ]
    [ nameContainer address player
    , div
        [ class "life-container", onClick address (CyclePlayerColor player.id) ]
        [ div [ class "life" ] [ text (toString player.life) ] ]
    , div
        [ class "wins-container" ]
        [ button
            [ class "minus-win"
            , onClick address (DecreaseWins player.id)
            , disabled (player.wins < 1)
            ]
            [ (text "-") ]
        , div [ class "wins" ] [ text (toString player.wins) ]
        , button [ class "plus-win", onClick address (IncreaseWins player.id) ] [ (text "+") ]
        ]
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
    playersList =
      (List.map (playerBox address) players)

    playersCount =
      (List.length players)
  in
    div
      [ class "overflow-container" ]
      [ div
          [ class ("players-container players-" ++ (toString playersCount)) ]
          playersList
      ]


victoryMessageContainer : Address Action -> Player -> Html
victoryMessageContainer address player =
  div
    [ class "victory-message-container" ]
    [ h1 
        [] 
        [ (text player.name)
        , (text " WINS!") 
        ]
    , div
        [ class "game-option" ]
        [ button
            [ class "option"
            , onClick address ResetGame
            ]
            [ (text "New Game") ] ]
    ]


gameOverView : Address Action -> Model -> Player -> Html
gameOverView address model player =
  div 
    [ class "main" ]
    [ div
      [ class "board shake" ]
      [ gameOptionsContainer address model
      , playersContainer address (List.take model.activePlayers model.players)
      ]
    , victoryMessageContainer address player
    ]


defaultView : Address Action -> Model -> Html
defaultView address model =
  div 
    [class "main" ]
    [ div
      [ class "board" ]
      [ gameOptionsContainer address model
      , playersContainer address (List.take model.activePlayers model.players)
      ]
    ]


-- MAIN VIEW --


view : Address Action -> Model -> Html
view address model =
  let
    alivePlayers = getAlivePlayers model.activePlayers model.players
  in
    if List.length alivePlayers == 1 then
      case List.head alivePlayers of
        Just player ->
          gameOverView address model player

        Nothing ->
          defaultView address model
    else
      defaultView address model

-- INIT --


loadModel : Model
loadModel =
  Maybe.withDefault initialModel getStorage


init : ( Model, Effects Action )
init =
  ( loadModel, Effects.none )


-- APP CONFIG --


app =
  StartApp.start
    { view = view
    , update = update
    , init = init
    , inputs = [ Signal.map (\_ -> IncrementTimer) (Time.every Time.second) ]
    }


-- PORTS --


{- Input port (from JS) -}
port getStorage : Maybe Model


{- Output port (send to JS) -}
port setStorage : Signal Model
port setStorage =
  app.model


-- APP INITIALIZATION --


main : Signal Html
main =
  app.html
