module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, on)
import Random exposing (Generator)
import Random.Extra exposing (sample)
import Maybe.Extra exposing (isNothing)
import Mouse exposing (Position)
import Json.Decode as Decode
import Time exposing (millisecond)
import Delay

type alias YCoord = Int

type alias Model =
    { result : Maybe Omikuji
    , mouse : Position
    , drag : Maybe YCoord
    , box : YCoord
    , showUp : Bool
    , rotated : Bool
    }

type Msg
    = OnResult Omikuji
    | ShowResult
    | MouseMove Position
    | StartDrag Position
    | EndDrag Position
    | Reset

init : ( Model, Cmd Msg )
init =
    let
        initModel =
            { result = Nothing
            , mouse = Position 0 0
            , drag = Nothing
            , box = boxMin
            , showUp = False
            , rotated = False
            }
    in
        ( initModel, Cmd.none )

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model = case msg of
    OnResult kuji ->
        { model | result = Just kuji } !
            [ Delay.after 300 millisecond ShowResult ]
    ShowResult -> ( { model | showUp = True }, Cmd.none )
    MouseMove pos ->
        if tmpBox model == boxMax && isNothing model.result
            then ( model, Random.generate OnResult omikuji )
            else ( { model | mouse = pos }, Cmd.none )
    StartDrag pos ->
        ( { model | drag = Just pos.y, rotated = True }, Cmd.none )
    EndDrag _ ->
        let newBox = tmpBox model
        in  ( { model | drag = Nothing, box = newBox }, Cmd.none )
    Reset -> init

tmpBox : Model -> YCoord
tmpBox model =
    let newY = case model.drag of
            Nothing -> model.box
            Just dr -> model.box + model.mouse.y - dr
    in  clip boxMin boxMax newY

boxMin : Int
boxMin = 0

boxMax : Int
boxMax = 200

clip : Int -> Int -> Int -> Int
clip lo hi y =
    if       y < lo then lo
    else if hi < y  then hi
    else                 y

onMouseDown : Attribute Msg
onMouseDown =
    on "mousedown" (Decode.map StartDrag Mouse.position)

subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Mouse.moves MouseMove
        , Mouse.ups EndDrag
        ]

main : Program Never Model Msg
main = program
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }

view : Model -> Html Msg
view model = case model.result of
    Nothing -> viewBox model
    Just kuji->
        if model.showUp
            then viewOmikuji kuji
            else viewBox model

type alias Omikuji =
    { fortune : Fortune
    , upper   : DetailUpper
    , lower   : DetailLower
    }

type Level
    = DaiKichi
    | ChuKichi
    | Kichi

lvToString : Level -> String
lvToString lv = case lv of
    DaiKichi -> "吉 大"
    ChuKichi -> "吉 中"
    Kichi -> "吉"

type alias Fortune =
    { level  : Level
    , flavor : String
    }

type alias DetailUpper =
    { wish    : String
    , wait    : String
    , study   : String
    , moving  : String
    , romance : String
    }

type alias DetailLower =
    { lost     : String
    , business : String
    , dispute  : String
    , travel   : String
    }

omikuji : Generator Omikuji
omikuji =
    let upper = Random.map5 DetailUpper wish wait study moving romance
        lower = Random.map4 DetailLower lost business dispute travel
    in  Random.map3 Omikuji fortune upper lower

level : Generator Level
level =
    sample [ DaiKichi, ChuKichi, Kichi ]
    |> Random.map (Maybe.withDefault Kichi)

flavor : Generator String
flavor =
    sample
        [ "自分も他人も慈しみ世の為に尽くせば周囲ともどもやがて幸多し"
        , "海原に舟漕ぎ出す心細さあれどやがて金波銀波の輝き渡る"
        , "運気盛んにして事を成すに良き頃なり脇目振らず一心を通すべし"
        ]
        |> Random.map (Maybe.withDefault "")

fortune : Generator Fortune
fortune = Random.map2 Fortune level flavor

wish : Generator String
wish =
    sample
        [ "自ずと叶う"
        , "油断すれば叶わず"
        , "達観して待つべし"
        ]
        |> Random.map (Maybe.withDefault "")

wait : Generator String
wait =
    sample
        [ "近くきたる"
        , "来ず辛抱せよ"
        , "気づけば傍にあり"
        ]
        |> Random.map (Maybe.withDefault "")

study : Generator String
study =
    sample
        [ "安心して励むべし"
        , "難なれど実り多し"
        , "修練のときなり"
        ]
        |> Random.map (Maybe.withDefault "")

moving : Generator String
moving =
    sample
        [ "さわりなし"
        , "西の方に幸あり"
        , "折あわず見直せ"
        ]
        |> Random.map (Maybe.withDefault "")

romance : Generator String
romance =
    sample
        [ "秘するが吉"
        , "順風満帆たる"
        , "荒天の予感あり"
        ]
        |> Random.map (Maybe.withDefault "")

lost : Generator String
lost =
    sample
        [ "高き所尋ねよ"
        , "やがて出る"
        , "水辺にて見つかる"
        ]
        |> Random.map (Maybe.withDefault "")

business : Generator String
business =
    sample
        [ "売りに幸運あり"
        , "焦らず待つべし"
        , "おおいに躍進あり"
        ]
        |> Random.map (Maybe.withDefault "")

dispute : Generator String
dispute =
    sample
        [ "理あれども勝てず"
        , "万難なく凪なり"
        , "大物に挑むなかれ"
        ]
        |> Random.map (Maybe.withDefault "")

travel : Generator String
travel =
    sample
        [ "身体に気を付けよ"
        , "遠方に吉あり"
        , "思わぬ出会いあり"
        ]
        |> Random.map (Maybe.withDefault "")

viewBox : Model -> Html Msg
viewBox model =
    div
        [ id "box-container"
        , onMouseDown
        , style
            (if model.rotated
                then
                    [ ("top", px (tmpBox model))
                    , ("transform", "rotate(-180deg)")
                    ]
                else [("top", px (tmpBox model))]
            )
        ]
        [ div
            [ id "box-bar"
            , style
                (if isNothing model.result
                    then [("top", "10px")]
                    else [("top", "-80px")]
                )
            ] []
        , div [ id "box-body"] []
        , div
            [ id "box-body-hilight"
            , class "vertical-writing centering"
            ]
            [ text "御 神 籤" ]
        , div [ id "box-hoop-top" ] []
        , div [ id "box-hoop-top-hilight" ] []
        , div [ id "box-hoop-bottom" ] []
        , div [ id "box-hoop-bottom-hilight"] []
        ]

px : Int -> String
px n = toString n ++ "px"

viewOmikuji : Omikuji -> Html Msg
viewOmikuji kuji =
    div
        [ id "omikuji-container"
        ]
        [ div
            [ id "omikuji-title"
            , class "vertical-writing centering"
            ]
            [ text "おみくじ" ]
        , div
            [ id "omikuji-frame" ]
            [ div
                [ id "omikuji-flavor"
                , class "vertical-writing"
                ]
                [ text kuji.fortune.flavor
                ]
            , div
                [ id "omikuji-fortune"
                , class "centering"
                ]
                [ text (lvToString kuji.fortune.level) ]
            , div
                [ id "omikuji-legend"
                , class "centering"
                ]
                [ text "勢 運" ]
            , div
                [ id "omikuji-detail-upper"
                , class "vertical-writing"
                ]
                [ text ("願望 " ++ kuji.upper.wish)
                , br [] []
                , text ("待人 " ++ kuji.upper.wait)
                , br [] []
                , text ("学問 " ++ kuji.upper.study)
                , br [] []
                , text ("転居 " ++ kuji.upper.moving)
                , br [] []
                , text ("恋愛 " ++ kuji.upper.romance)
                ]
            , div
                [ id "omikuji-detail-lower"
                , class "vertical-writing"
                ]
                [ text ("失物 " ++ kuji.lower.lost)
                , br [] []
                , text ("商売 " ++ kuji.lower.business)
                , br [] []
                , text ("争事 " ++ kuji.lower.dispute)
                , br [] []
                , text ("旅行 " ++ kuji.lower.travel)
                ]
            ]
        , button
            [ id "omikuji-button"
            , onClick Reset
            ]
            [ text "もう一回引く" ]
        ]
