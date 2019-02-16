module Main exposing (main)

{-
   Rotating cube with colored sides.
-}

import AnimationFrame
import Color exposing (Color)
import Html exposing (Html)
import Html.Attributes exposing (width, height, style)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (vec3, Vec3)
import Time exposing (Time)
import WebGL exposing (Mesh, Shader)


main : Program Never Float Time
main =
    Html.program
        { init = ( 0, Cmd.none )
        , view = view
        , subscriptions = (\_ -> AnimationFrame.diffs Basics.identity)
        , update = (\dt time -> ( time + dt / 200, Cmd.none ))
        }


view : Float -> Html Time
view time =
    WebGL.toHtml
        [ width 400
        , height 400
        , style [ ( "display", "block" ) ]
        ]
        [ WebGL.entity
            vertexShader
            fragmentShader
            cubeMesh
            (uniforms time)
        ]


type alias Uniforms =
    { 
     perspective : Mat4
    , camera : Mat4
    , shade : Float
    , time: Float
    }


uniforms : Float -> Uniforms
uniforms time =
    {  perspective = Mat4.makePerspective 45 1 0.01 100
    , camera = Mat4.makeLookAt (vec3 0 0 5) (vec3 0 0 0) (vec3 0 1 0)
    , shade = 0.8
    , time = time
    }



-- Mesh


type alias Vertex =
    { color : Vec3
    , position : Vec3
    }


cubeMesh : Mesh Vertex
cubeMesh =
    let
        tl  =
            vec3 1 -1 0
        tr =
            vec3 1 1 0
        bl =
            vec3 -1 -1 0
        br =
            vec3 -1 1 0
    in
        [ face Color.green tl tr br bl

        ]
            |> List.concat
            |> WebGL.triangles


face : Color -> Vec3 -> Vec3 -> Vec3 -> Vec3 -> List ( Vertex, Vertex, Vertex )
face rawColor a b c d =
    let
        color =
            let
                c =
                    Color.toRgb rawColor
            in
                vec3
                    (toFloat c.red / 255)
                    (toFloat c.green / 255)
                    (toFloat c.blue / 255)

        vertex position =
            Vertex color position
    in
        [ ( vertex a, vertex b, vertex c )
        , ( vertex c, vertex d, vertex a )
        ]



-- Shaders


vertexShader : Shader Vertex Uniforms { vcolor : Vec3, vposition: Vec3 }
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


fragmentShader : Shader {} Uniforms { vcolor : Vec3, vposition: Vec3 }
fragmentShader =
    [glsl|
        precision mediump float;
        uniform float shade;
        uniform float time;
        varying vec3 vcolor;
        varying vec3 vposition;
        void main () {
            float opacity = sin(vposition.x - time);
            gl_FragColor = opacity * shade * vec4(vcolor, 1.0);
        }
    |]