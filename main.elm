module Main exposing (main)

{-
   Rotating cube with colored sides.
-}

import Browser.Events as E
import Html exposing (Html)
import Html.Attributes exposing (height, style, width)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (Vec3, vec3)
import Browser
import WebGL exposing (Mesh, Shader)



type alias Model = Float
type Msg = NewDiff Float


update :  Msg -> Model -> (Model, Cmd Msg)
update msg timeElapsed =
    case msg of
        NewDiff dt ->
            ( timeElapsed + dt / 200, Cmd.none )


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( 0, Cmd.none )
        , view = view
        , subscriptions = \_ -> E.onAnimationFrameDelta NewDiff
        , update = update 
        }


view : Float -> Html msg
view time =
    WebGL.toHtml
        [ width 400
        , height 400
        , style "display" "block"
        ]
        [ WebGL.entity
            vertexShader
            fragmentShader
            cubeMesh
            (uniforms time)
        ]


type alias Uniforms =
    { perspective : Mat4
    , camera : Mat4
    , shade : Float
    , time : Float
    }


uniforms : Float -> Uniforms
uniforms time =
    { perspective = Mat4.makePerspective 45 1 0.01 100
    , camera = Mat4.makeLookAt (vec3 0 0 5) (vec3 0 0 0) (vec3 0 1 0)
    , shade = 0.8
    , time = time
    }



-- Mesh


type alias Vertex =

    {
    position : Vec3,
         color : Vec3
    }

-- love ashish

cubeMesh : Mesh Vertex
cubeMesh =
    let
        topLeft =
            vec3 1 -1 0
        topRight =
            vec3 1 1 0
        bottomLeft =
            vec3 -1 -1 0
        bottomRight =
            vec3 -1 1 0
        red =
            vec3 1 0 0
        green =
            vec3 0 1 0
        blue =
            vec3 0 0 1 
       in
            [
                (Vertex topLeft green, Vertex topRight green, Vertex bottomRight red),
                (Vertex bottomRight red, Vertex bottomLeft red, Vertex topLeft red)
            ] 
            |> WebGL.triangles



-- Shaders


vertexShader : Shader Vertex Uniforms { vcolor : Vec3, vposition : Vec3 }
vertexShader =
    [glsl|
        attribute vec3 position;
        attribute vec3 color;
        uniform mat4 perspective;
        uniform mat4 camera;
        varying vec3 vcolor;
        varying vec3 vposition;
        void main () {
            vec4 position = perspective * camera * vec4(position, 1.0);
            gl_Position = position; 
            vcolor = color;
            vposition = position.xyz;
        }
    |]


fragmentShader : Shader {} Uniforms { vcolor : Vec3, vposition : Vec3 }
fragmentShader =
    [glsl|
        precision mediump float;
        uniform float shade;
        uniform float time;
        varying vec3 vcolor;
        varying vec3 vposition;
        void main () {
            float opacity = fract(vposition.x - time);
            gl_FragColor = vec4(vcolor, 1.0);
        }
    |]
