module Main exposing (main)

import Base64
import Browser
import Bytes.Encode
import GitHubCorner
import Html exposing (..)
import Html.Attributes exposing (..)
import Image
import Image.Advanced
import Image.Internal.ImageData
import Image.Internal.Meta exposing (BitDepth1_2_4_8(..), BitDepth1_2_4_8_16(..), BitDepth8_16(..), BmpBitsPerPixel(..), BmpHeader, GifHeader, Header(..), PngColor(..), PngHeader)


main : Program () Model Msg
main =
    Browser.document
        { init = \_ -> ( initialModel, Cmd.none )
        , view = \m -> { title = "", body = [ view m ] }
        , update = update
        , subscriptions = \_ -> Sub.none
        }


type Msg
    = UpdateCVS String
    | BuildImage


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateCVS s ->
            ( model, Cmd.none )

        BuildImage ->
            ( model, Cmd.none )


type alias Model =
    { csv : String
    , width : Int
    }


initialModel =
    { csv = csv
    , width = 32
    }


view model =
    div
        []
        [ Html.node "style" [] [ text """
body {
  overscroll-behavior-y: none;
}
table {
    border-collapse: collapse;
    border-spacing: 0;
    border: 1px solid #ddd;
    float:left;
}
tr:nth-child(even) {
    /*background-color: #f2f2f2;*/
    background-color: #00FFFF
}
tr:nth-child(odd) {
    /*background-color: #ffffff;*/
    background-color: #FF00FF
}
th,td {
    text-align:center;
    vertical-align: bottom;
    padding: 5px;
}
pre {
    text-align:left;
}
        """ ]
        , table []
            [ tr []
                [ th [] [ text "Source" ]
                , th [] [ text "Info" ]
                , th [] [ text "toBMP24" ]
                , th [] [ text "toBMP32" ]
                , th [] [ text "toPNG32" ]
                , th [] [ text "toGIF" ]
                ]

            --, rowPng "PNG32 SubFilter" png_rgba0
            --, rowPng "PNG32 True Color" png_rgba
            --, rowPng "PNG32 Indexed" png_indexed
            --, rowPng "PNG32 Indexed+" png_indexed2
            --, rowPng "png_grayscale" png_grayscale
            --, rowBmp "BMP32" bmp32
            --, rowBmp "BMP24" bmp24
            --, rowBmp "BMP8 indexed" bmp8_indexed
            --, rowBmp "bmp_grayscale" bmp_grayscale
            --, rowGif "GIF" gif
            --, rowGif "GIF Animated" gif_animated
            --, rowGif "GIF Transparent 0" gif_transparent0
            --, rowGif "GIF Transparent 1" gif_transparent1
            , rowGif "GIF Transparent 2" gif_transparent2

            --, rowCsv "CSV" model.width model.csv
            --, rowJpg "jpg" jpg
            ]
        , GitHubCorner.topRight "https://github.com/justgook/elm-image"
        ]


rowBmp =
    row "bmp"


rowPng =
    row "png"


rowGif =
    row "gif"


rowJpg =
    row "jpg"


rowCsv title width data =
    let
        image =
            data
                |> String.split ","
                |> List.map (String.trim >> String.toInt >> Maybe.withDefault 0)
                |> Image.fromList width
                |> Just
    in
    row_ title
        (span []
            [ input [ type_ "text", value data ] []
            , br [] []
            , input [ type_ "text", value (String.fromInt width) ] []
            ]
        )
        image


row what title input =
    let
        image =
            decodedImage input
                |> Maybe.map Image.Advanced.eval

        first =
            img [ style "image-rendering" "pixelated", width 32, src <| "data:image/" ++ what ++ ";base64," ++ input ] []
    in
    row_ title first image


row_ title first image =
    tr []
        [ td []
            [ p [] [ text title ]
            , first
            ]
        , td [] [ pre [] [ image |> maybeInfoToString |> text ] ]
        , td [] [ img [ style "image-rendering" "pixelated", width 32, src <| "data:image/bmp;base64," ++ bmp24MaybeEncode image ] [] ]
        , td [] [ img [ style "image-rendering" "pixelated", width 32, src <| "data:image/bmp;base64," ++ bmp32MaybeEncode image ] [] ]
        , td [] [ img [ style "image-rendering" "pixelated", width 32, src <| "data:image/png;base64," ++ png32MaybeEncode image ] [] ]
        , td [] [ img [ style "image-rendering" "pixelated", width 32, src <| "data:image/gif;base64," ++ gifMaybeEncode image ] [] ]
        ]


maybeInfoToString image =
    Maybe.map Image.Internal.ImageData.getInfo image
        |> Maybe.map
            (\meta ->
                case meta of
                    Png info ->
                        pngInfo info

                    Bmp info ->
                        bmpInfo info

                    Gif info ->
                        gifInfo info

                    FromData info ->
                        "FromData"
            )
        |> Maybe.withDefault "UNKNOWN"


bmp24MaybeEncode =
    Maybe.andThen (Image.Advanced.toBmp24 >> Base64.fromBytes)
        >> Maybe.withDefault ""


bmp32MaybeEncode =
    Maybe.andThen (Image.Advanced.toBmp32 >> Base64.fromBytes)
        >> Maybe.withDefault ""


png32MaybeEncode =
    Maybe.andThen (Image.Advanced.toPng32 >> Base64.fromBytes)
        >> Maybe.withDefault ""


gifMaybeEncode =
    Maybe.andThen (Image.Advanced.toGif >> Base64.fromBytes)
        >> Maybe.withDefault ""


png_rgba0 =
    "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAABN0lEQVR4nNXVsQ3CMBSEYWcDNqGkYARKOjrEEnSIjiUQHR0lI1BQsgkbBJ+lixzHz7GdxBF/4xSI+5RESqV0p8+61kd25+Wr2j/fWf9R7Q7H+n69VHMhDECfai5EA0BzIFoAVBrRAaCSCC8AlUKIAASEPgYXQgQBCIjvQwV/I7XYKnMXQ3eiF4ByEBzXlyYJEQVAKQh3nPkQ0QAUg5DGmYtIAqAQom+c2YhkAPIhYscZEVkAZCNSxxkQ2QAEhD4Gfc7/F4BxPEN9qW6bVdlHYI+zVATG8Q4lA3zjLBbBcX2Z9ghC46wPYY+jaEDMOJMQ7jiKAqSMMxfhG0e9gJxxRoQ0joKAIeMMCGkciYAxxlkI4QWMOc4kRAcwxTjzIVqAKceZi2gAJcaZjTCAkuOMCPM5LT3OgPgBM+xsVK/GvgAAAAAASUVORK5CYII="


png_rgba =
    "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAU1JREFUWIXF1jEOgyAUgOH3SA/QmzA6eISO3dyMl3AzbF7CdHPr6BEcHL1Jb0AnGkvhAQ+rTNWk/l8goAgA0K2lhoyh5Iz1tLCeIaqm1UrOmAPo1lI/bgXrGQIA4EyEMD/OQojtxRkIYd84GvEDOBqBVdN6t8849FkIM6gteqH+WDWtHoceX09g7fHrHbBbS61k4T0nnEtgI653SJ4JEweglyMI4CC2cTN8iChACsIVpxDRgBgEFfchkgAUIibuQiQDXIiUuI0gz4HQMOdEzuucNQN7DjZgHHqsp0XX08I+tpWckQUwcXPNQSg54+sJOhlgxzkIEwdIXAJfPAWxjScBQvEYhB2PBsTGKYQrHgVIjbsQvjhA4HuAG/9GFOT3hHcGcuNbBPUCcwL2iscgfgB7x0OIL8C/4hTiA/h33IcQR8ZdCDQ3jopvx+NW4Bv/Yxx+YWcxGQAAAABJRU5ErkJggg=="


png_indexed =
    "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAAAAXNSR0IArs4c6QAAAA9QTFRFAAAAWmN4f9E78K0AYbXJVRkoWwAAAAV0Uk5TAP////8c0CZSAAAAl0lEQVQ4jZXQWRLEIAgA0TbO/c8cCUHBhdTw268SBK5p+IWhfAjKh2ggFwJS8YBMKEjECwrLTKBQw2Df6CAK+l8G8IKxhwND4Db1wAT+LQGoILw2AhHxJEyg3WO+2J9Atsp+oS/3vbJ0L2TntQ8hr2bTTehVdl2F3pVtF2F33/cmagBL74JTN8Gxv4JzV0HSH0HWRZD2Jm7D/AlwYEde7wAAAABJRU5ErkJggg=="


png_indexed2 =
    "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAAAAXNSR0IArs4c6QAAABJQTFRFAAAAWmN4f9E78K0AYbXJWmN417t0cAAAAAZ0Uk5TAP////95fqLG6wAAAJhJREFUOI2V0FkShDAIANEuM7n/lQ0iCWTBGn77lRLgmoZfGOqHoH6IBnIhIBUPyISCRLygsswEKiUM9o0OoqD/ZQAvGHs4MARuUw9M4N8SgArCayMQEU/CBNo95ov9CWSr7Bf6ct8LS/dCdl77EPJqNt2EXmXXVehd2XYRdvd9b6IEsPQuOHUTHPsrOHcVJP0RZF0EaW/iBqkUDTClg67mAAAAAElFTkSuQmCC"


png_grayscale =
    "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAQAAADZc7J/AAAAAXNSR0IArs4c6QAAAP5JREFUSIml1MsRhSAMBdAkYwNWkqWlWQOluaQSS8hb+IFAEn3IRhy5Z8JARIAsEA7GLVhBqzDGQJYlWEEA3wgC+EbQ8Rgn6JqMElSmY8RUvzwTAEtzqLg2Z5xwD059xiz6XlC7ZJXZrWLGLO1GOsAnjjiAJgzAJkpcEybQEzpeEw6giT5eCBcohB2/iMn+VBNRu2cJKng3wgoSbgLA7hYAGIMK0nnjNveCM+7+FlJ1YW2CcRf3FFLTMj3BZ8+YQBvvCb5bzgCsuCa46tgO8OKFYNXwDRDFL0L/LxTwFD8I3WYV8CbeEzfwNt4S9H9cEzQSrwkaixcCAcbix1jwB/b9l5TmMcLoAAAAAElFTkSuQmCC"


bmp32 =
    "Qk16EAAAAAAAAHoAAABsAAAAIAAAACAAAAABACAAAwAAAAAQAAATCwAAEwsAAAAAAAAAAAAAAAAA/wAA/wAA/wAA/wAAAFdpbiAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVhAAAAAHl4Y1oAAAAA/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1YQAAAAD/AK3weXhjWnl4Y1oAAAAA/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWEAAAAA/wCt8P8ArfB5eGNaeXhjWnl4Y1oAAAAA/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVhAAAAAP8ArfD/AK3w/wCt8Hl4Y1p5eGNaeXhjWnl4Y1oAAAAA/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1YQAAAAD/AK3w/wCt8P8ArfD/AK3weXhjWnl4Y1p5eGNaeXhjWnl4Y1oAAAAA/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWEAAAAA/wCt8P8ArfD/AK3w/wCt8P8ArfB5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1oAAAAA/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVhAAAAAP8ArfD/AK3w/wCt8P8ArfD/AK3w/wCt8Hl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1oAAAAA/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1YQAAAAD/AK3w/wCt8P8ArfD/AK3w/wCt8P8ArfD/AK3weXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1oAAAAA/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWEAAAAA/zvRfwAAAAD/AK3w/wCt8P8ArfD/AK3w/wCt8P8ArfB5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1oAAAAA/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVhAAAAAP870X//O9F//zvRfwAAAAD/AK3w/wCt8P8ArfD/AK3w/wCt8Hl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1oAAAAA/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1YQAAAAD/O9F//zvRf/870X//O9F//zvRfwAAAAD/AK3w/wCt8P8ArfD/AK3weXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1oAAAAA/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWEAAAAA/zvRf/870X//O9F//zvRf/870X//O9F//zvRfwAAAAD/AK3w/wCt8P8ArfB5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1oAAAAA/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVhAAAAAP870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRfwAAAAD/AK3w/wCt8Hl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1oAAAAA/8m1Yf/JtWH/ybVh/8m1YQAAAAD/O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRfwAAAAD/AK3weXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1oAAAAA/8m1Yf/JtWEAAAAA/zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRfwAAAAB5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1oAAAAAAAAAAP870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf3l4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWgAAAAAAAAAA/zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F/eXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1oAAAAA/wCt8P8ArfAAAAAA/zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRfwAAAAB5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaAAAAAP8ArfD/AK3w/wCt8P8ArfAAAAAA/zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X8AAAAA/8m1YXl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWgAAAAD/AK3w/wCt8P8ArfD/AK3w/wCt8P8ArfAAAAAA/zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F/AAAAAP/JtWH/ybVheXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1oAAAAA/wCt8P8ArfD/AK3w/wCt8P8ArfD/AK3w/wCt8P8ArfAAAAAA/zvRf/870X//O9F//zvRf/870X//O9F//zvRfwAAAAD/ybVh/8m1Yf/JtWF5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaAAAAAP8ArfD/AK3w/wCt8P8ArfD/AK3w/wCt8P8ArfD/AK3w/wCt8P8ArfAAAAAA/zvRf/870X//O9F//zvRf/870X8AAAAA/8m1Yf/JtWH/ybVh/8m1YXl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWgAAAAD/AK3w/wCt8P8ArfD/AK3w/wCt8P8ArfD/AK3w/wCt8P8ArfD/AK3w/wCt8P8ArfAAAAAA/zvRf/870X//O9F/AAAAAP/JtWH/ybVh/8m1Yf/JtWH/ybVheXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1oAAAAA/wCt8P8ArfD/AK3w/wCt8P8ArfD/AK3w/wCt8P8ArfD/AK3w/wCt8P8ArfD/AK3w/wCt8P8ArfAAAAAA/zvRfwAAAAD/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWF5eGNaeXhjWnl4Y1p5eGNaeXhjWnl4Y1p5eGNaAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1YXl4Y1p5eGNaeXhjWnl4Y1p5eGNaeXhjWgAAAAD/O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F/AAAAAP/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVheXhjWnl4Y1p5eGNaeXhjWnl4Y1oAAAAA/zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRfwAAAAD/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWF5eGNaeXhjWnl4Y1p5eGNaAAAAAP870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X8AAAAA/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1YXl4Y1p5eGNaeXhjWgAAAAD/O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F/AAAAAP/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVheXhjWnl4Y1oAAAAA/zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRfwAAAAD/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWF5eGNaAAAAAP870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X8AAAAA/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1YQAAAAD/O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F//zvRf/870X//O9F/AAAAAP/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh/8m1Yf/JtWH/ybVh"


bmp24 =
    "Qk02DAAAAAAAADYAAAAoAAAAIAAAACAAAAABABgAAAAAAAAMAAASCwAAEgsAAAAAAAAAAAAAAAAAybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhAAAAeGNaAAAAybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhAAAAAK3weGNaeGNaAAAAybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhAAAAAK3wAK3weGNaeGNaeGNaAAAAybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhAAAAAK3wAK3wAK3weGNaeGNaeGNaeGNaAAAAybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhAAAAAK3wAK3wAK3wAK3weGNaeGNaeGNaeGNaeGNaAAAAybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhAAAAAK3wAK3wAK3wAK3wAK3weGNaeGNaeGNaeGNaeGNaeGNaAAAAybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhAAAAAK3wAK3wAK3wAK3wAK3wAK3weGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhAAAAAK3wAK3wAK3wAK3wAK3wAK3wAK3weGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhAAAAO9F/AAAAAK3wAK3wAK3wAK3wAK3wAK3weGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhAAAAO9F/O9F/O9F/AAAAAK3wAK3wAK3wAK3wAK3weGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhAAAAO9F/O9F/O9F/O9F/O9F/AAAAAK3wAK3wAK3wAK3weGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAybVhybVhybVhybVhybVhybVhybVhybVhAAAAO9F/O9F/O9F/O9F/O9F/O9F/O9F/AAAAAK3wAK3wAK3weGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAybVhybVhybVhybVhybVhybVhAAAAO9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/AAAAAK3wAK3weGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAybVhybVhybVhybVhAAAAO9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/AAAAAK3weGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAybVhybVhAAAAO9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/AAAAeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAAAAAO9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/eGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAAAAAO9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/eGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAAK3wAK3wAAAAO9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/AAAAeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAAK3wAK3wAK3wAK3wAAAAO9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/AAAAybVheGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAAK3wAK3wAK3wAK3wAK3wAK3wAAAAO9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/AAAAybVhybVheGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAAK3wAK3wAK3wAK3wAK3wAK3wAK3wAK3wAAAAO9F/O9F/O9F/O9F/O9F/O9F/O9F/AAAAybVhybVhybVheGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAAK3wAK3wAK3wAK3wAK3wAK3wAK3wAK3wAK3wAK3wAAAAO9F/O9F/O9F/O9F/O9F/AAAAybVhybVhybVhybVheGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAAK3wAK3wAK3wAK3wAK3wAK3wAK3wAK3wAK3wAK3wAK3wAK3wAAAAO9F/O9F/O9F/AAAAybVhybVhybVhybVhybVheGNaeGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAAK3wAK3wAK3wAK3wAK3wAK3wAK3wAK3wAK3wAK3wAK3wAK3wAK3wAK3wAAAAO9F/AAAAybVhybVhybVhybVhybVhybVheGNaeGNaeGNaeGNaeGNaeGNaeGNaAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAybVhybVhybVhybVhybVhybVhybVheGNaeGNaeGNaeGNaeGNaeGNaAAAAO9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/AAAAybVhybVhybVhybVhybVhybVhybVhybVheGNaeGNaeGNaeGNaeGNaAAAAO9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/AAAAybVhybVhybVhybVhybVhybVhybVhybVhybVheGNaeGNaeGNaeGNaAAAAO9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/AAAAybVhybVhybVhybVhybVhybVhybVhybVhybVhybVheGNaeGNaeGNaAAAAO9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/AAAAybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVheGNaeGNaAAAAO9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/AAAAybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVheGNaAAAAO9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/AAAAybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhAAAAO9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/O9F/AAAAybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVhybVh"


bmp8_indexed =
    "Qk02CAAAAAAAADYEAAAoAAAAIAAAACAAAAABAAgAAAAAAAAEAAASCwAAEgsAAAABAAAAAQAAAAAAAHhjWgA70X8AAK3wAMm1YQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQAAQAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEAAMBAQAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAADAwEBAQAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQAAwMDAQEBAQAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEAAMDAwMBAQEBAQAEBAQEBAQEBAQEBAQEBAQEBAQEBAADAwMDAwEBAQEBAQAEBAQEBAQEBAQEBAQEBAQEBAQAAwMDAwMDAQEBAQEBAQAEBAQEBAQEBAQEBAQEBAQEAAMDAwMDAwMBAQEBAQEBAQAEBAQEBAQEBAQEBAQEBAACAAMDAwMDAwEBAQEBAQEBAQAEBAQEBAQEBAQEBAQAAgICAAMDAwMDAQEBAQEBAQEBAQAEBAQEBAQEBAQEAAICAgICAAMDAwMBAQEBAQEBAQEBAQAEBAQEBAQEBAACAgICAgICAAMDAwEBAQEBAQEBAQEBAQAEBAQEBAQAAgICAgICAgICAAMDAQEBAQEBAQEBAQEBAQAEBAQEAAICAgICAgICAgICAAMBAQEBAQEBAQEBAQEBAQAEBAACAgICAgICAgICAgICAAEBAQEBAQEBAQEBAQEBAQAAAgICAgICAgICAgICAgICAQEBAQEBAQEBAQEBAQEBAAACAgICAgICAgICAgICAgIBAQEBAQEBAQEBAQEBAQADAwACAgICAgICAgICAgICAAEBAQEBAQEBAQEBAQEAAwMDAwACAgICAgICAgICAgAEAQEBAQEBAQEBAQEBAAMDAwMDAwACAgICAgICAgIABAQBAQEBAQEBAQEBAQADAwMDAwMDAwACAgICAgICAAQEBAEBAQEBAQEBAQEAAwMDAwMDAwMDAwACAgICAgAEBAQEAQEBAQEBAQEBAAMDAwMDAwMDAwMDAwACAgIABAQEBAQBAQEBAQEBAQADAwMDAwMDAwMDAwMDAwACAAQEBAQEBAEBAQEBAQEAAAAAAAAAAAAAAAAAAAAAAAAEBAQEBAQEAQEBAQEBAAICAgICAgICAgICAgICAgIABAQEBAQEBAQBAQEBAQACAgICAgICAgICAgICAgICAAQEBAQEBAQEBAEBAQEAAgICAgICAgICAgICAgICAgAEBAQEBAQEBAQEAQEBAAICAgICAgICAgICAgICAgIABAQEBAQEBAQEBAQBAQACAgICAgICAgICAgICAgICAAQEBAQEBAQEBAQEBAEAAgICAgICAgICAgICAgICAgAEBAQEBAQEBAQEBAQEAAICAgICAgICAgICAgICAgIABAQEBAQEBAQEBAQEBAQ="


bmp_grayscale =
    "Qk02CAAAAAAAADYEAAAoAAAAIAAAACAAAAABAAgAAAAAAAAEAAASCwAAEgsAAAABAAAAAQAAAAAAAAEBAQACAgIAAwMDAAQEBAAFBQUABgYGAAcHBwAICAgACQkJAAoKCgALCwsADAwMAA0NDQAODg4ADw8PABAQEAAREREAEhISABMTEwAUFBQAFRUVABYWFgAXFxcAGBgYABkZGQAaGhoAGxsbABwcHAAdHR0AHh4eAB8fHwAgICAAISEhACIiIgAjIyMAJCQkACUlJQAmJiYAJycnACgoKAApKSkAKioqACsrKwAsLCwALS0tAC4uLgAvLy8AMDAwADExMQAyMjIAMzMzADQ0NAA1NTUANjY2ADc3NwA4ODgAOTk5ADo6OgA7OzsAPDw8AD09PQA+Pj4APz8/AEBAQABBQUEAQkJCAENDQwBEREQARUVFAEZGRgBHR0cASEhIAElJSQBKSkoAS0tLAExMTABNTU0ATk5OAE9PTwBQUFAAUVFRAFJSUgBTU1MAVFRUAFVVVQBWVlYAV1dXAFhYWABZWVkAWlpaAFtbWwBcXFwAXV1dAF5eXgBfX18AYGBgAGFhYQBiYmIAY2NjAGRkZABlZWUAZmZmAGdnZwBoaGgAaWlpAGpqagBra2sAbGxsAG1tbQBubm4Ab29vAHBwcABxcXEAcnJyAHNzcwB0dHQAdXV1AHZ2dgB3d3cAeHh4AHl5eQB6enoAe3t7AHx8fAB9fX0Afn5+AH9/fwCAgIAAgYGBAIKCggCDg4MAhISEAIWFhQCGhoYAh4eHAIiIiACJiYkAioqKAIuLiwCMjIwAjY2NAI6OjgCPj48AkJCQAJGRkQCSkpIAk5OTAJSUlACVlZUAlpaWAJeXlwCYmJgAmZmZAJqamgCbm5sAnJycAJ2dnQCenp4An5+fAKCgoAChoaEAoqKiAKOjowCkpKQApaWlAKampgCnp6cAqKioAKmpqQCqqqoAq6urAKysrACtra0Arq6uAK+vrwCwsLAAsbGxALKysgCzs7MAtLS0ALW1tQC2trYAt7e3ALi4uAC5ubkAurq6ALu7uwC8vLwAvb29AL6+vgC/v78AwMDAAMHBwQDCwsIAw8PDAMTExADFxcUAxsbGAMfHxwDIyMgAycnJAMrKygDLy8sAzMzMAM3NzQDOzs4Az8/PANDQ0ADR0dEA0tLSANPT0wDU1NQA1dXVANbW1gDX19cA2NjYANnZ2QDa2toA29vbANzc3ADd3d0A3t7eAN/f3wDg4OAA4eHhAOLi4gDj4+MA5OTkAOXl5QDm5uYA5+fnAOjo6ADp6ekA6urqAOvr6wDs7OwA7e3tAO7u7gDv7+8A8PDwAPHx8QDy8vIA8/PzAPT09AD19fUA9vb2APf39wD4+PgA+fn5APr6+gD7+/sA/Pz8AP39/QD+/v4A////AADJycnJycnJycnJycnJycnJycnJycnJycnJycnJyckAdwDJycnJycnJycnJycnJycnJycnJycnJycnJycnJAO93dwDJycnJycnJycnJycnJycnJycnJycnJycnJyQDv73d3dwDJycnJycnJycnJycnJycnJycnJycnJyckA7+/vd3d3dwDJycnJycnJycnJycnJycnJycnJycnJAO/v7+93d3d3dwDJycnJycnJycnJycnJycnJycnJyQDv7+/v73d3d3d3dwDJycnJycnJycnJycnJycnJyckA7+/v7+/vd3d3d3d3dwDJycnJycnJycnJycnJycnJAO/v7+/v7+93d3d3d3d3dwDJycnJycnJycnJycnJyQDRAO/v7+/v73d3d3d3d3d3dwDJycnJycnJycnJyckA0dHRAO/v7+/vd3d3d3d3d3d3dwDJycnJycnJycnJANHR0dHRAO/v7+93d3d3d3d3d3d3dwDJycnJycnJyQDR0dHR0dHRAO/v73d3d3d3d3d3d3d3dwDJycnJyckA0dHR0dHR0dHRAO/vd3d3d3d3d3d3d3d3dwDJycnJANHR0dHR0dHR0dHRAO93d3d3d3d3d3d3d3d3dwDJyQDR0dHR0dHR0dHR0dHRAHd3d3d3d3d3d3d3d3d3dwAA0dHR0dHR0dHR0dHR0dHRd3d3d3d3d3d3d3d3d3d3AADR0dHR0dHR0dHR0dHR0dF3d3d3d3d3d3d3d3d3dwDv7wDR0dHR0dHR0dHR0dHRAHd3d3d3d3d3d3d3d3cA7+/v7wDR0dHR0dHR0dHR0QDJd3d3d3d3d3d3d3d3AO/v7+/v7wDR0dHR0dHR0dEAycl3d3d3d3d3d3d3dwDv7+/v7+/v7wDR0dHR0dHRAMnJyXd3d3d3d3d3d3cA7+/v7+/v7+/v7wDR0dHR0QDJycnJd3d3d3d3d3d3AO/v7+/v7+/v7+/v7wDR0dEAycnJycl3d3d3d3d3dwDv7+/v7+/v7+/v7+/v7wDRAMnJycnJyXd3d3d3d3cAAAAAAAAAAAAAAAAAAAAAAADJycnJycnJd3d3d3d3ANHR0dHR0dHR0dHR0dHR0dEAycnJycnJycl3d3d3dwDR0dHR0dHR0dHR0dHR0dHRAMnJycnJycnJyXd3d3cA0dHR0dHR0dHR0dHR0dHR0QDJycnJycnJycnJd3d3ANHR0dHR0dHR0dHR0dHR0dEAycnJycnJycnJycl3dwDR0dHR0dHR0dHR0dHR0dHRAMnJycnJycnJycnJyXcA0dHR0dHR0dHR0dHR0dHR0QDJycnJycnJycnJycnJANHR0dHR0dHR0dHR0dHR0dEAycnJycnJycnJycnJyck="


gif =
    "R0lGODdhIAAgAKIAAAAAAFpjeH/RO/CtAGG1yQAAAAAAAAAAACH5BAkKAAAALAAAAAAgACAAAAOgCLLcLoDISWlQL69YOwmXpnHeBIbiQ5YnmjZr17rvVn4zVtveDALAoHAY7Pkug6RyuVTEcEcAczrQxY4nKTWp40mw2W2XQQKHmWPY1/xrviLsczoDiGfnGvsPn9Fz+DB2K4AQA3FPfFpsTxJzWoZgjBNjj5BRN5NkTFiSHU5Tl5gVlUo+nTeklj+iqJtZrJiVr7CxpRe0rIqnuJNVvLQACQA7"


jpg =
    "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"


csv =
    "0,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1516468479,0,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1516468479,1516468479,0,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1516468479,1516468479,1516468479,0,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1516468479,1516468479,1516468479,1516468479,0,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1516468479,1516468479,1516468479,1516468479,1516468479,0,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,0,2144418815,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,0,2144418815,2144418815,2144418815,0,1639303679,1639303679,1639303679,1639303679,1639303679,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,0,2144418815,2144418815,2144418815,2144418815,2144418815,0,1639303679,1639303679,1639303679,1639303679,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,0,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,0,1639303679,1639303679,1639303679,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,0,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,0,1639303679,1639303679,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,4037869823,4037869823,4037869823,4037869823,0,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,0,1639303679,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,4037869823,4037869823,0,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,0,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,0,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,0,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,1639303679,1639303679,0,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,0,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,1639303679,1639303679,1639303679,1639303679,0,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,0,4037869823,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,0,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,0,4037869823,4037869823,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,0,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,2144418815,0,4037869823,4037869823,4037869823,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,0,2144418815,2144418815,2144418815,2144418815,2144418815,0,4037869823,4037869823,4037869823,4037869823,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,0,2144418815,2144418815,2144418815,0,4037869823,4037869823,4037869823,4037869823,4037869823,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,0,2144418815,0,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,0,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,1516468479,1516468479,1516468479,1516468479,1516468479,1516468479,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,0,4037869823,4037869823,4037869823,4037869823,4037869823,4037869823,1516468479,1516468479,1516468479,1516468479,1516468479,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,0,4037869823,4037869823,4037869823,4037869823,4037869823,1516468479,1516468479,1516468479,1516468479,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,0,4037869823,4037869823,4037869823,4037869823,1516468479,1516468479,1516468479,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,0,4037869823,4037869823,4037869823,1516468479,1516468479,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,0,4037869823,4037869823,1516468479,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,0,4037869823,0,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,1639303679,0"


gif_animated =
    "R0lGODlhCwAdAKIAAP8AAAD/AP//AI6OjgAAAP///wAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQEZAAAACwAAAAACwAdAAADMHi63N4jvkghretipSXTk/eM5CeaG9ehF5seoPOWNBPcz603em/3uAUwKPQ5drVkAgAh+QQEMgAAACwCAAsABwAQAAADGXgnrMsNyknhswq7zff4ziceYmmeoxmCRwIAIfkEBGQAAAAsAgACAAcAEAAAAxl4B6zLDcpJ4bMKu833+M4nHmJpnqMZgkcCADs="


gif_transparent0 =
    "R0lGODlhCgAKAJEAAP////8AAAAA/wAAACH5BAEAAAAALAAAAAAKAAoAAAIWjC2Zhyoc3DOgAnXslfqo3mCMBJFMAQA7"


gif_transparent1 =
    "R0lGODlhCgAKAJEAAP////8AAAAA/wAAACH5BAEAAAEALAAAAAAKAAoAAAIWjC2Zhyoc3DOgAnXslfqo3mCMBJFMAQA7"


gif_transparent2 =
    "R0lGODlhCgAKAJEAAP////8AAAAA/wAAACH5BAEAAAIALAAAAAAKAAoAAAIWjC2Zhyoc3DOgAnXslfqo3mCMBJFMAQA7"


decodedImage image =
    Base64.toBytes image
        |> Maybe.withDefault (Bytes.Encode.sequence [] |> Bytes.Encode.encode)
        |> Image.decode


pngInfo : PngHeader -> String
pngInfo { width, height, color, adam7 } =
    "Png\nwidth: "
        ++ String.fromInt width
        ++ ("\nheight: " ++ String.fromInt height)
        ++ ("\ncolor: " ++ pngColor color)
        ++ ("\nAdam7: " ++ boolToString adam7)


gifInfo : GifHeader -> String
gifInfo { width, height } =
    "Gif\nwidth: "
        ++ String.fromInt width
        ++ ("\nheight: " ++ String.fromInt height)


boolToString a =
    if a then
        "True"

    else
        "False"


pngColor c =
    case c of
        Greyscale a ->
            "Greyscale " ++ bitDepth1_2_4_8_16ToString a ++ "bit"

        TrueColour a ->
            "Truecolour " ++ bitDepth8_16ToString a ++ "bit"

        IndexedColour a ->
            "IndexedColour " ++ bitDepth1_2_4_8ToString a ++ "bit"

        GreyscaleAlpha a ->
            "GreyscaleAlpha " ++ bitDepth8_16ToString a ++ "bit"

        TrueColourAlpha a ->
            "TruecolourAlpha " ++ bitDepth8_16ToString a ++ "bit"


bmpInfo : BmpHeader -> String
bmpInfo { width, height, fileSize, pixelStart, dibHeader, color_planes, bitsPerPixel, compression, dataSize } =
    "BMP\nwidth: "
        ++ String.fromInt width
        ++ ("\nheight: " ++ String.fromInt height)
        ++ ("\nfileSize: " ++ String.fromInt fileSize)
        ++ ("\npixelStart: " ++ String.fromInt pixelStart)
        ++ ("\ndibHeader: " ++ String.fromInt dibHeader)
        ++ ("\ncolor_planes: " ++ String.fromInt color_planes)
        ++ ("\nbitsPerPixel: " ++ bitsPerPixelToString bitsPerPixel)
        ++ ("\ncompression: " ++ String.fromInt compression)
        ++ ("\ndataSize: " ++ String.fromInt dataSize)


bitsPerPixelToString a =
    case a of
        BmpBitsPerPixel32 ->
            "32bit"

        BmpBitsPerPixel24 ->
            "24bit"

        BmpBitsPerPixel16 ->
            "16bit"

        BmpBitsPerPixel8 ->
            "8bit"


bitDepth1_2_4_8_16ToString i =
    case i of
        BitDepth1_2_4_8_16__1 ->
            "1"

        BitDepth1_2_4_8_16__2 ->
            "2"

        BitDepth1_2_4_8_16__4 ->
            "4"

        BitDepth1_2_4_8_16__8 ->
            "8"

        BitDepth1_2_4_8_16__16 ->
            "16"


bitDepth1_2_4_8ToString i =
    case i of
        BitDepth1_2_4_8__1 ->
            "1"

        BitDepth1_2_4_8__2 ->
            "2"

        BitDepth1_2_4_8__4 ->
            "4"

        BitDepth1_2_4_8__8 ->
            "8"


bitDepth8_16ToString i =
    case i of
        BitDepth8_16__8 ->
            "8"

        BitDepth8_16__16 ->
            "16"
