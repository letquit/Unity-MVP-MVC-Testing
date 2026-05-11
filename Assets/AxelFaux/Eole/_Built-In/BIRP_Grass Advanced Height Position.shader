// Made with Amplify Shader Editor v1.9.2.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Eole/Built-In/Grass Advanced Height Position"
{
	Properties
	{
		_SecondWindSmoothstep("Wind Smoothstep", Vector) = (0,1,0,0)
		_FlattenVertexNormal("Flatten Vertex Normal", Range( 0 , 1)) = 1
		[HideInInspector][Toggle(_DEBUGWIND_ON)] _DebugWind("Debug Wind", Float) = 1
		_ColorMapFadeContrast("Fade Hardness", Float) = 0
		_ColorMapBlendOffset("Fade Offset", Float) = 0
		[Toggle(_USECOLORMAP_ON)] _UseColormap("Use Colormap", Float) = 1
		_CrushBrightness("Crush Brightness", Range( 0 , 1)) = 0.5
		[Space(10)]_WindBrightness("Wind Brightness", Range( 0 , 2)) = 0.5
		[NoScaleOffset][SingleLineTexture]_BaseMap("Base Map", 2D) = "white" {}
		[Toggle(_USEAIRSHEENTINT_ON)] _UseAirSheenTint("UseAirSheenTint", Float) = 1
		[NoScaleOffset][SingleLineTexture]_NormalMap("Normal Map", 2D) = "bump" {}
		_NormalStrength("Normal Strength", Float) = 1
		_AlphaThreshold("Alpha Threshold", Range( 0 , 1)) = 0.5
		_VariantOffset("Variant Blend Offset", Float) = 0
		_VariantContrast("Variant Blend Hardness", Float) = 1
		[HDR]_MainBaseColor("Base Color", Color) = (0.1019608,0.3098039,0,0)
		[HDR]_VariantBaseColor("Variant Color", Color) = (0.7882353,0.8,0.4,0.2)
		_SimpleWindyYOffset("Windy Y Offset", Float) = -0.5
		_SimpleWindDisplacement("Displacement", Float) = 1
		[Header(Idle Bezier Points)][Space(5)]_BezierAlpha("Alpha", Range( 0 , 1)) = 1
		[Header(Windy Bezier Points)][Space(5)]_BezierOffsetAlpha("Alpha", Range( 0 , 1)) = 1
		_BezierP1("P1", Vector) = (0,0.1,0,0)
		_BezierP2("P2", Vector) = (-0.1,0.5,0,0)
		_BezierOffsetP1("Offset P1", Vector) = (0.3,-0.5,0,0)
		_BezierOffsetP2("Offset P2", Vector) = (0.5,-0.75,0,0)
		_UseTreeBend("UseTreeBend", Float) = -1
		[HideInInspector][Toggle(_DEBUGDISABLEWINDDPO_ON)] _DebugDisableWindDPO("DebugDisableWindDPO", Float) = 1
		[KeywordEnum(None,Simple,Advanced)] _Wind("Wind", Float) = 2
		_TurbulenceDisplacement("Displacement", Float) = 0.03
		_TurbulenceSmoothstepMax("Smoothstep", Range( 0 , 1)) = 1
		_TurbulenceSpeed("Speed", Float) = 0.2
		_TurbulenceFrequency("Frequency", Range( 0.01 , 10)) = 0.1
		[Toggle(_USECRUSH_ON)] _UseCrush("UseCrush", Float) = 0
		[Group(Crush)]_CrushAngle("Crush Angle", Range( 0 , 120)) = 60
		[Toggle]_CrushFlattenScale("Flatten", Range( 0 , 1)) = 0
		_CrushHeightOffset("Height Offset", Range( -2 , 0)) = -0.9
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

		//_TransmissionShadow( "Transmission Shadow", Range( 0, 1 ) ) = 0.5
		//_TransStrength( "Trans Strength", Range( 0, 50 ) ) = 1
		//_TransNormal( "Trans Normal Distortion", Range( 0, 1 ) ) = 0.5
		//_TransScattering( "Trans Scattering", Range( 1, 50 ) ) = 2
		//_TransDirect( "Trans Direct", Range( 0, 1 ) ) = 0.9
		//_TransAmbient( "Trans Ambient", Range( 0, 1 ) ) = 0.1
		//_TransShadow( "Trans Shadow", Range( 0, 1 ) ) = 0.5
		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25
		//[ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
		//[ToggleOff] _GlossyReflections("Reflections", Float) = 1.0
	}

	SubShader
	{
		
		Tags { "RenderType"="Opaque" "Queue"="Geometry" "DisableBatching"="False" }
	LOD 0

		Cull Off
		AlphaToMask Off
		ZWrite On
		ZTest LEqual
		ColorMask RGBA
		
		Blend Off
		

		CGINCLUDE
		#pragma target 3.0

		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		ENDCG

		
		Pass
		{
			
			Name "ForwardBase"
			Tags { "LightMode"="ForwardBase" }

			Blend One Zero

			CGPROGRAM
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile_instancing
			#pragma multi_compile __ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#ifndef UNITY_PASS_FORWARDBASE
				#define UNITY_PASS_FORWARDBASE
			#endif
			#include "HLSLSupport.cginc"
			#ifndef UNITY_INSTANCED_LOD_FADE
				#define UNITY_INSTANCED_LOD_FADE
			#endif
			#ifndef UNITY_INSTANCED_SH
				#define UNITY_INSTANCED_SH
			#endif
			#ifndef UNITY_INSTANCED_LIGHTMAPSTS
				#define UNITY_INSTANCED_LIGHTMAPSTS
			#endif
			#include "UnityShaderVariables.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "AutoLight.cginc"

			#include "UnityStandardUtils.cginc"
			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_POSITION
			#define ASE_NEEDS_FRAG_COLOR
			#pragma multi_compile_local __ _DEBUGDISABLEWINDDPO_ON
			#pragma shader_feature_local _WIND_NONE _WIND_SIMPLE _WIND_ADVANCED
			#pragma shader_feature_local _USECRUSH_ON
			#pragma multi_compile_local_fragment __ _DEBUGWIND_ON
			#pragma shader_feature_local _USEAIRSHEENTINT_ON
			#pragma shader_feature_local _USECOLORMAP_ON

			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				#if UNITY_VERSION >= 201810
					UNITY_POSITION(pos);
				#else
					float4 pos : SV_POSITION;
				#endif
				#if defined(LIGHTMAP_ON) || (!defined(LIGHTMAP_ON) && SHADER_TARGET >= 30)
					float4 lmap : TEXCOORD0;
				#endif
				#if !defined(LIGHTMAP_ON) && UNITY_SHOULD_SAMPLE_SH
					half3 sh : TEXCOORD1;
				#endif
				#if defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS) && UNITY_VERSION >= 201810 && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_LIGHTING_COORDS(2,3)
				#elif defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if UNITY_VERSION >= 201710
						UNITY_SHADOW_COORDS(2)
					#else
						SHADOW_COORDS(2)
					#endif
				#endif
				#ifdef ASE_FOG
					UNITY_FOG_COORDS(4)
				#endif
				float4 tSpace0 : TEXCOORD5;
				float4 tSpace1 : TEXCOORD6;
				float4 tSpace2 : TEXCOORD7;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 screenPos : TEXCOORD8;
				#endif
				float4 ase_texcoord9 : TEXCOORD9;
				float4 ase_texcoord10 : TEXCOORD10;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			uniform half _UseTreeBend;
			uniform float3 WindDirection;
			uniform float WindOffsetSpeed;
			uniform float WindTillingSize;
			uniform float2 _SecondWindSmoothstep;
			uniform float2 WindSmoothstep;
			uniform sampler2D WindMap;
			uniform half WindAmplitude;
			uniform half DebugDisableWPO;
			uniform half2 _BezierP1;
			uniform half _BezierAlpha;
			uniform half2 _BezierOffsetP1;
			uniform half _BezierOffsetAlpha;
			uniform half2 _BezierP2;
			uniform half2 _BezierOffsetP2;
			uniform half _SimpleWindyYOffset;
			uniform half _SimpleWindDisplacement;
			uniform sampler2D CrushRenderTexture;
			uniform float2 CrushBufferOffset;
			uniform half CrushBufferSize;
			uniform half _CrushAngle;
			uniform half _CrushFlattenScale;
			uniform half _CrushHeightOffset;
			uniform half CrushDistanceView;
			uniform half CrushDistanceViewFalloff;
			uniform half _TurbulenceSmoothstepMax;
			uniform half _TurbulenceSpeed;
			uniform half _TurbulenceFrequency;
			uniform half _TurbulenceDisplacement;
			uniform float _FlattenVertexNormal;
			uniform half4 _MainBaseColor;
			uniform half4 _VariantBaseColor;
			uniform half _VariantOffset;
			uniform half _VariantContrast;
			uniform sampler2D _BaseMap;
			uniform sampler2D ColorMap;
			uniform float2 ColorMapOffset;
			uniform float2 ColorMapTillingSize;
			uniform half _ColorMapBlendOffset;
			uniform half _ColorMapFadeContrast;
			uniform half _WindBrightness;
			uniform half _CrushBrightness;
			uniform half2 AirSmoothstep;
			uniform sampler2D AirMap;
			uniform sampler2D AirRefractionMap;
			uniform half AirRefractionTillingSize;
			uniform half AirRefractionStrength;
			uniform half AirSpeedMultiplier;
			uniform float WindAngle;
			uniform half2 AirTillingSize;
			uniform half AirStrength;
			uniform int DebugWind;
			uniform int DebugWindTurbulence;
			uniform sampler2D _NormalMap;
			uniform half _NormalStrength;
			uniform half _AlphaThreshold;


			float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
			{
				original -= center;
				float C = cos( angle );
				float S = sin( angle );
				float t = 1 - C;
				float m00 = t * u.x * u.x + C;
				float m01 = t * u.x * u.y - S * u.z;
				float m02 = t * u.x * u.z + S * u.y;
				float m10 = t * u.x * u.y + S * u.z;
				float m11 = t * u.y * u.y + C;
				float m12 = t * u.y * u.z - S * u.x;
				float m20 = t * u.x * u.z - S * u.y;
				float m21 = t * u.y * u.z + S * u.x;
				float m22 = t * u.z * u.z + C;
				float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
				return mul( finalMatrix, original ) + center;
			}
			
			float3 TrigonometricBezierCurve( float3 p1, float3 p2, float t )
			{
				float3 p0 = float3(0, 0, 0);
				float u = 1 - t;
				float t2 = t * t;
				float u2 = u * u;
				float3 result =
					(u2)*p0 +
					(2 * u * t) * p1 +
					t2 * p2;
				return result;
			}
			
			float CheapContrast1_g3661( float In, float Value )
			{
				float A = 0 - Value;
				float B = 1 + Value;
				return clamp(0,1, lerp(A,B,In));
			}
			
			float CheapContrast1_g3663( float In, float Value )
			{
				float A = 0 - Value;
				float B = 1 + Value;
				return clamp(0,1, lerp(A,B,In));
			}
			
			float2 RotateUV67_g3667( float2 UV, float Angle )
			{
				// Rotation Matrix
				                float cosAngle = cos(Angle);
				                float sinAngle = sin(Angle);
				                float2x2 rot = float2x2(cosAngle, -sinAngle, sinAngle, cosAngle);
				 
				                // Rotation
				                return mul(rot, UV);
			}
			
			struct Gradient
			{
				int type;
				int colorsLength;
				int alphasLength;
				float4 colors[8];
				float2 alphas[8];
			};
			
			Gradient NewGradient(int type, int colorsLength, int alphasLength, 
			float4 colors0, float4 colors1, float4 colors2, float4 colors3, float4 colors4, float4 colors5, float4 colors6, float4 colors7,
			float2 alphas0, float2 alphas1, float2 alphas2, float2 alphas3, float2 alphas4, float2 alphas5, float2 alphas6, float2 alphas7)
			{
				Gradient g;
				g.type = type;
				g.colorsLength = colorsLength;
				g.alphasLength = alphasLength;
				g.colors[ 0 ] = colors0;
				g.colors[ 1 ] = colors1;
				g.colors[ 2 ] = colors2;
				g.colors[ 3 ] = colors3;
				g.colors[ 4 ] = colors4;
				g.colors[ 5 ] = colors5;
				g.colors[ 6 ] = colors6;
				g.colors[ 7 ] = colors7;
				g.alphas[ 0 ] = alphas0;
				g.alphas[ 1 ] = alphas1;
				g.alphas[ 2 ] = alphas2;
				g.alphas[ 3 ] = alphas3;
				g.alphas[ 4 ] = alphas4;
				g.alphas[ 5 ] = alphas5;
				g.alphas[ 6 ] = alphas6;
				g.alphas[ 7 ] = alphas7;
				return g;
			}
			
			float4 SampleGradient( Gradient gradient, float time )
			{
				float3 color = gradient.colors[0].rgb;
				UNITY_UNROLL
				for (int c = 1; c < 8; c++)
				{
				float colorPos = saturate((time - gradient.colors[c-1].w) / ( 0.00001 + (gradient.colors[c].w - gradient.colors[c-1].w)) * step(c, (float)gradient.colorsLength-1));
				color = lerp(color, gradient.colors[c].rgb, lerp(colorPos, step(0.01, colorPos), gradient.type));
				}
				#ifndef UNITY_COLORSPACE_GAMMA
				color = half3(GammaToLinearSpaceExact(color.r), GammaToLinearSpaceExact(color.g), GammaToLinearSpaceExact(color.b));
				#endif
				float alpha = gradient.alphas[0].x;
				UNITY_UNROLL
				for (int a = 1; a < 8; a++)
				{
				float alphaPos = saturate((time - gradient.alphas[a-1].y) / ( 0.00001 + (gradient.alphas[a].y - gradient.alphas[a-1].y)) * step(a, (float)gradient.alphasLength-1));
				alpha = lerp(alpha, gradient.alphas[a].x, lerp(alphaPos, step(0.01, alphaPos), gradient.type));
				}
				return float4(color, alpha);
			}
			

			v2f VertexFunction (appdata v  ) {
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 temp_output_331_0_g3680 = (half3(0,0,1)).xz;
				float3 worldToObjDir141_g3687 = normalize( mul( unity_WorldToObject, float4( WindDirection, 0 ) ).xyz );
				float3 wpo_wind_direction306_g3679 = worldToObjDir141_g3687;
				float3 temp_output_295_0_g3680 = wpo_wind_direction306_g3679;
				float dotResult330_g3680 = dot( temp_output_331_0_g3680 , (temp_output_295_0_g3680).xz );
				float3 break444_g3680 = temp_output_295_0_g3680;
				float2 appendResult355_g3680 = (float2(break444_g3680.z , break444_g3680.x));
				float dotResult356_g3680 = dot( temp_output_331_0_g3680 , appendResult355_g3680 );
				float3 objToWorld183_g3687 = mul( unity_ObjectToWorld, float4( v.vertex.xyz, 1 ) ).xyz;
				float3 break153_g3687 = -objToWorld183_g3687;
				float2 appendResult155_g3687 = (float2(break153_g3687.x , break153_g3687.z));
				float2 _wind_UVs106_g3687 = appendResult155_g3687;
				float mulTime137_g3687 = _Time.y * ( WindOffsetSpeed / 10.0 );
				float3 break187_g3687 = WindDirection;
				float2 appendResult188_g3687 = (float2(break187_g3687.x , break187_g3687.z));
				float2 _wind_direction110_g3687 = appendResult188_g3687;
				float4 tex2DNode144_g3687 = tex2Dlod( WindMap, float4( ( ( _wind_UVs106_g3687 / WindTillingSize ) + ( mulTime137_g3687 * _wind_direction110_g3687 ) ), 0, 0.0) );
				float smoothstepResult53_g3687 = smoothstep( WindSmoothstep.x , WindSmoothstep.y , tex2DNode144_g3687.r);
				float smoothstepResult170_g3687 = smoothstep( _SecondWindSmoothstep.x , _SecondWindSmoothstep.y , smoothstepResult53_g3687);
				float _wind_amplitude116_g3687 = WindAmplitude;
				float temp_output_2490_0 = ( smoothstepResult170_g3687 * _wind_amplitude116_g3687 );
				float wpo_wind_rawMask497_g3679 = temp_output_2490_0;
				float debug_disableWPO486_g3679 = DebugDisableWPO;
				#ifdef _DEBUGDISABLEWINDDPO_ON
				float staticSwitch479_g3679 = ( debug_disableWPO486_g3679 == 1.0 ? 0.0 : wpo_wind_rawMask497_g3679 );
				#else
				float staticSwitch479_g3679 = wpo_wind_rawMask497_g3679;
				#endif
				float wpo_wind_mask302_g3679 = staticSwitch479_g3679;
				float wind_mask423_g3680 = wpo_wind_mask302_g3679;
				float lerpResult192_g3680 = lerp( 0.0 , ( acos( dotResult330_g3680 ) * sign( dotResult356_g3680 ) ) , wind_mask423_g3680);
				float3 appendResult465_g3680 = (float3(0.0 , _BezierP1.y , _BezierP1.x));
				float3 temp_output_453_0_g3680 = ( appendResult465_g3680 * _BezierAlpha );
				float3 appendResult419_g3680 = (float3(0.0 , _BezierOffsetP1.y , _BezierOffsetP1.x));
				float3 rotatedValue187_g3680 = RotateAroundAxis( float3( 0,0,0 ), ( temp_output_453_0_g3680 + ( appendResult419_g3680 * wind_mask423_g3680 * _BezierOffsetAlpha ) ), float3( 0,1,0 ), lerpResult192_g3680 );
				float3 temp_output_15_0_g3681 = rotatedValue187_g3680;
				float3 p121_g3681 = temp_output_15_0_g3681;
				float3 appendResult463_g3680 = (float3(0.0 , _BezierP2.y , _BezierP2.x));
				float3 temp_output_454_0_g3680 = ( appendResult463_g3680 * _BezierAlpha );
				float3 appendResult420_g3680 = (float3(0.0 , _BezierOffsetP2.y , _BezierOffsetP2.x));
				float3 rotatedValue195_g3680 = RotateAroundAxis( float3( 0,0,0 ), ( temp_output_454_0_g3680 + ( appendResult420_g3680 * wind_mask423_g3680 * _BezierOffsetAlpha ) ), float3( 0,1,0 ), lerpResult192_g3680 );
				float3 temp_output_14_0_g3681 = rotatedValue195_g3680;
				float3 p221_g3681 = temp_output_14_0_g3681;
				float wpo_CoordMask184_g3679 = v.ase_color.r;
				float temp_output_6_0_g3681 = wpo_CoordMask184_g3679;
				float t21_g3681 = temp_output_6_0_g3681;
				float3 localTrigonometricBezierCurve21_g3681 = TrigonometricBezierCurve( p121_g3681 , p221_g3681 , t21_g3681 );
				float3 temp_output_500_0_g3679 = localTrigonometricBezierCurve21_g3681;
				half3 _RelativeUp = half3(0,1,0);
				float3 temp_output_26_0_g3682 = wpo_wind_direction306_g3679;
				float dotResult7_g3682 = dot( temp_output_26_0_g3682 , _RelativeUp );
				float lerpResult10_g3682 = lerp( -1.570796 , 1.570796 , ( ( dotResult7_g3682 * 0.5 ) + 0.5 ));
				float3 rotatedValue17_g3682 = RotateAroundAxis( float3( 0,0,0 ), temp_output_26_0_g3682, normalize( cross( _RelativeUp , temp_output_26_0_g3682 ) ), lerpResult10_g3682 );
				float temp_output_25_0_g3682 = wpo_wind_mask302_g3679;
				float lerpResult21_g3682 = lerp( 0.0 , _SimpleWindyYOffset , temp_output_25_0_g3682);
				float3 appendResult23_g3682 = (float3(0.0 , lerpResult21_g3682 , 0.0));
				float3 temp_output_499_0_g3679 = ( wpo_CoordMask184_g3679 * ( ( rotatedValue17_g3682 + appendResult23_g3682 ) * _SimpleWindDisplacement * temp_output_25_0_g3682 ) );
				#if defined(_WIND_NONE)
				float3 staticSwitch166_g3679 = float3( 0,0,0 );
				#elif defined(_WIND_SIMPLE)
				float3 staticSwitch166_g3679 = temp_output_499_0_g3679;
				#elif defined(_WIND_ADVANCED)
				float3 staticSwitch166_g3679 = temp_output_500_0_g3679;
				#else
				float3 staticSwitch166_g3679 = temp_output_500_0_g3679;
				#endif
				float3 out_wpo_windy423_g3679 = staticSwitch166_g3679;
				float3 temp_output_159_0_g3686 = out_wpo_windy423_g3679;
				float4 transform584_g3679 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float4 tex2DNode29_g3686 = tex2Dlod( CrushRenderTexture, float4( ( ( ( (transform584_g3679).xz + -CrushBufferOffset ) + ( CrushBufferSize / 2.0 ) ) / CrushBufferSize ), 0, 0.0) );
				float2 temp_output_96_0_g3686 = ( ( (tex2DNode29_g3686).rg - float2( 0.5,0.5 ) ) * float2( 2,2 ) );
				float2 break98_g3686 = temp_output_96_0_g3686;
				float3 appendResult102_g3686 = (float3(break98_g3686.x , 0.0 , break98_g3686.y));
				float3 worldToObjDir101_g3686 = mul( unity_WorldToObject, float4( appendResult102_g3686, 0 ) ).xyz;
				float3 crush_direction172_g3686 = worldToObjDir101_g3686;
				float vectorField_length134_g3686 = length( temp_output_96_0_g3686 );
				float3 temp_output_126_0_g3686 = float3( 0,0,0 );
				float3 ase_worldPos = mul(unity_ObjectToWorld, float4( (v.vertex).xyz, 1 )).xyz;
				float3 worldToObj14_g3686 = mul( unity_WorldToObject, float4( ase_worldPos, 1 ) ).xyz;
				float3 rotatedValue16_g3686 = RotateAroundAxis( temp_output_126_0_g3686, worldToObj14_g3686, crush_direction172_g3686, ( radians( _CrushAngle ) * vectorField_length134_g3686 ) );
				float3 appendResult195_g3686 = (float3(1.0 , ( 1.0 - _CrushFlattenScale ) , 1.0));
				float3 appendResult66_g3686 = (float3(0.0 , _CrushHeightOffset , 0.0));
				float crush_coordMasd87_g3686 = wpo_CoordMask184_g3679;
				float3 ase_parentObjectScale = ( 1.0 / float3( length( unity_WorldToObject[ 0 ].xyz ), length( unity_WorldToObject[ 1 ].xyz ), length( unity_WorldToObject[ 2 ].xyz ) ) );
				float RT_b236_g3686 = tex2DNode29_g3686.b;
				float4 transform223_g3686 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float temp_output_235_0_g3686 = ( RT_b236_g3686 == 0.0 ? ( ( vectorField_length134_g3686 * saturate( ( crush_coordMasd87_g3686 * 8.0 ) ) ) * saturate( ( ( CrushDistanceView - distance( float4( _WorldSpaceCameraPos , 0.0 ) , transform223_g3686 ) ) / CrushDistanceViewFalloff ) ) ) : 0.0 );
				float3 lerpResult160_g3686 = lerp( temp_output_159_0_g3686 , ( ( ( rotatedValue16_g3686 - worldToObj14_g3686 ) * appendResult195_g3686 ) + ( appendResult66_g3686 * crush_coordMasd87_g3686 * ase_parentObjectScale.y ) ) , temp_output_235_0_g3686);
				#ifdef _USECRUSH_ON
				float3 staticSwitch162_g3686 = lerpResult160_g3686;
				#else
				float3 staticSwitch162_g3686 = temp_output_159_0_g3686;
				#endif
				float3 out_wpo_crush432_g3679 = staticSwitch162_g3686;
				float smoothstepResult112_g3683 = smoothstep( 0.0 , _TurbulenceSmoothstepMax , wpo_wind_rawMask497_g3679);
				float temp_output_153_0_g3683 = saturate( smoothstepResult112_g3683 );
				float4 transform119_g3683 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float mulTime95_g3683 = _Time.y * _TurbulenceSpeed;
				float3 ase_objectScale = float3( length( unity_ObjectToWorld[ 0 ].xyz ), length( unity_ObjectToWorld[ 1 ].xyz ), length( unity_ObjectToWorld[ 2 ].xyz ) );
				float temp_output_99_0_g3683 = ( cos( ( ( ( ( ( transform119_g3683.x * 100.0 ) + ( transform119_g3683.z * 33.0 ) ) - mulTime95_g3683 ) + v.vertex.xyz.y ) / _TurbulenceFrequency ) ) * _TurbulenceDisplacement * ase_objectScale.y * v.ase_texcoord.y );
				float3 temp_output_88_0_g3683 = wpo_wind_direction306_g3679;
				float3 temp_output_544_0_g3679 = ( out_wpo_crush432_g3679 + ( temp_output_153_0_g3683 * temp_output_99_0_g3683 * temp_output_88_0_g3683 ) );
				#if defined(_WIND_NONE)
				float3 staticSwitch438_g3679 = float3( 0,0,0 );
				#elif defined(_WIND_SIMPLE)
				float3 staticSwitch438_g3679 = temp_output_544_0_g3679;
				#elif defined(_WIND_ADVANCED)
				float3 staticSwitch438_g3679 = temp_output_544_0_g3679;
				#else
				float3 staticSwitch438_g3679 = temp_output_544_0_g3679;
				#endif
				float3 wpo_out_turbulence508_g3679 = staticSwitch438_g3679;
				#ifdef _DEBUGDISABLEWINDDPO_ON
				float3 staticSwitch466_g3679 = ( debug_disableWPO486_g3679 == 1.0 ? out_wpo_crush432_g3679 : wpo_out_turbulence508_g3679 );
				#else
				float3 staticSwitch466_g3679 = wpo_out_turbulence508_g3679;
				#endif
				
				float3 lerpResult3_g2806 = lerp( v.normal , float3(0,1,0) , _FlattenVertexNormal);
				
				o.ase_texcoord9 = v.vertex;
				o.ase_texcoord10.xy = v.ase_texcoord.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord10.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = staticSwitch466_g3679;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.vertex.w = 1;
				v.normal = lerpResult3_g2806;
				v.tangent = v.tangent;

				o.pos = UnityObjectToClipPos(v.vertex);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
				o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				#ifdef DYNAMICLIGHTMAP_ON
				o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif
				#ifdef LIGHTMAP_ON
				o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				#ifndef LIGHTMAP_ON
					#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
						o.sh = 0;
						#ifdef VERTEXLIGHT_ON
						o.sh += Shade4PointLights (
							unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
							unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
							unity_4LightAtten0, worldPos, worldNormal);
						#endif
						o.sh = ShadeSHPerVertex (worldNormal, o.sh);
					#endif
				#endif

				#if UNITY_VERSION >= 201810 && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_TRANSFER_LIGHTING(o, v.texcoord1.xy);
				#elif defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if UNITY_VERSION >= 201710
						UNITY_TRANSFER_SHADOW(o, v.texcoord1.xy);
					#else
						TRANSFER_SHADOW(o);
					#endif
				#endif

				#ifdef ASE_FOG
					UNITY_TRANSFER_FOG(o,o.pos);
				#endif
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
					o.screenPos = ComputeScreenPos(o.pos);
				#endif
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			v2f vert ( appdata v )
			{
				return VertexFunction( v );
			}
			#endif

			fixed4 frag (v2f IN 
				#ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
				#endif
				) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				#ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
				#endif

				#if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
				#else
					SurfaceOutputStandard o = (SurfaceOutputStandard)0;
				#endif
				float3 WorldTangent = float3(IN.tSpace0.x,IN.tSpace1.x,IN.tSpace2.x);
				float3 WorldBiTangent = float3(IN.tSpace0.y,IN.tSpace1.y,IN.tSpace2.y);
				float3 WorldNormal = float3(IN.tSpace0.z,IN.tSpace1.z,IN.tSpace2.z);
				float3 worldPos = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
				#else
					half atten = 1;
				#endif
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 ScreenPos = IN.screenPos;
				#endif

				float3 temp_cast_0 = (IN.ase_texcoord9.xyz.y).xxx;
				float3 objToWorld541_g3660 = mul( unity_ObjectToWorld, float4( temp_cast_0, 1 ) ).xyz;
				float In1_g3661 = ( objToWorld541_g3660.y + _VariantOffset );
				float Value1_g3661 = _VariantContrast;
				float localCheapContrast1_g3661 = CheapContrast1_g3661( In1_g3661 , Value1_g3661 );
				float4 lerpResult350_g3660 = lerp( _MainBaseColor , _VariantBaseColor , saturate( localCheapContrast1_g3661 ));
				float4 appendResult442_g3660 = (float4((lerpResult350_g3660).rgb , 1.0));
				float2 uv_BaseMap53_g3660 = IN.ase_texcoord10.xy;
				float4 tex2DNode53_g3660 = tex2D( _BaseMap, uv_BaseMap53_g3660 );
				float4 _baseMap50_g3660 = tex2DNode53_g3660;
				float4 temp_output_428_0_g3660 = ( appendResult442_g3660 * _baseMap50_g3660 );
				float4 temp_output_124_0_g3662 = temp_output_428_0_g3660;
				float3 temp_output_125_0_g3662 = (temp_output_124_0_g3662).rgb;
				float _colormap_baseMap_Alpha146_g3662 = (temp_output_124_0_g3662).a;
				float4 appendResult132_g3662 = (float4(temp_output_125_0_g3662 , _colormap_baseMap_Alpha146_g3662));
				float coord_mask88_g3660 = IN.ase_color.r;
				float In1_g3663 = ( coord_mask88_g3660 - _ColorMapBlendOffset );
				float Value1_g3663 = _ColorMapFadeContrast;
				float localCheapContrast1_g3663 = CheapContrast1_g3663( In1_g3663 , Value1_g3663 );
				float3 lerpResult97_g3662 = lerp( (tex2D( ColorMap, ( ( (worldPos).xz + ColorMapOffset ) / ColorMapTillingSize ) )).rgb , temp_output_125_0_g3662 , saturate( ( (lerpResult350_g3660).a * localCheapContrast1_g3663 ) ));
				float3 break65_g3662 = lerpResult97_g3662;
				float4 appendResult64_g3662 = (float4(break65_g3662.x , break65_g3662.y , break65_g3662.z , _colormap_baseMap_Alpha146_g3662));
				#ifdef _USECOLORMAP_ON
				float4 staticSwitch128_g3662 = appendResult64_g3662;
				#else
				float4 staticSwitch128_g3662 = appendResult132_g3662;
				#endif
				float4 temp_output_23_0_g3665 = staticSwitch128_g3662;
				float3 objToWorld183_g3687 = mul( unity_ObjectToWorld, float4( IN.ase_texcoord9.xyz, 1 ) ).xyz;
				float3 break153_g3687 = -objToWorld183_g3687;
				float2 appendResult155_g3687 = (float2(break153_g3687.x , break153_g3687.z));
				float2 _wind_UVs106_g3687 = appendResult155_g3687;
				float mulTime137_g3687 = _Time.y * ( WindOffsetSpeed / 10.0 );
				float3 break187_g3687 = WindDirection;
				float2 appendResult188_g3687 = (float2(break187_g3687.x , break187_g3687.z));
				float2 _wind_direction110_g3687 = appendResult188_g3687;
				float4 tex2DNode144_g3687 = tex2D( WindMap, ( ( _wind_UVs106_g3687 / WindTillingSize ) + ( mulTime137_g3687 * _wind_direction110_g3687 ) ) );
				float smoothstepResult53_g3687 = smoothstep( WindSmoothstep.x , WindSmoothstep.y , tex2DNode144_g3687.r);
				float smoothstepResult170_g3687 = smoothstep( _SecondWindSmoothstep.x , _SecondWindSmoothstep.y , smoothstepResult53_g3687);
				float _wind_amplitude116_g3687 = WindAmplitude;
				float temp_output_2490_0 = ( smoothstepResult170_g3687 * _wind_amplitude116_g3687 );
				float windMask397_g3660 = temp_output_2490_0;
				float lerpResult71_g3665 = lerp( 1.0 , _WindBrightness , windMask397_g3660);
				float4 transform584_g3679 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float4 tex2DNode29_g3686 = tex2D( CrushRenderTexture, ( ( ( (transform584_g3679).xz + -CrushBufferOffset ) + ( CrushBufferSize / 2.0 ) ) / CrushBufferSize ) );
				float RT_b236_g3686 = tex2DNode29_g3686.b;
				float2 temp_output_96_0_g3686 = ( ( (tex2DNode29_g3686).rg - float2( 0.5,0.5 ) ) * float2( 2,2 ) );
				float vectorField_length134_g3686 = length( temp_output_96_0_g3686 );
				float wpo_CoordMask184_g3679 = IN.ase_color.r;
				float crush_coordMasd87_g3686 = wpo_CoordMask184_g3679;
				float4 transform223_g3686 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float temp_output_235_0_g3686 = ( RT_b236_g3686 == 0.0 ? ( ( vectorField_length134_g3686 * saturate( ( crush_coordMasd87_g3686 * 8.0 ) ) ) * saturate( ( ( CrushDistanceView - distance( float4( _WorldSpaceCameraPos , 0.0 ) , transform223_g3686 ) ) / CrushDistanceViewFalloff ) ) ) : 0.0 );
				#ifdef _USECRUSH_ON
				float staticSwitch163_g3686 = temp_output_235_0_g3686;
				#else
				float staticSwitch163_g3686 = 0.0;
				#endif
				float lerpResult78_g3665 = lerp( lerpResult71_g3665 , _CrushBrightness , staticSwitch163_g3686);
				float lerpResult83_g3665 = lerp( 1.0 , lerpResult78_g3665 , saturate( ( coord_mask88_g3660 * 2.0 ) ));
				float4 appendResult29_g3665 = (float4((saturate( ( temp_output_23_0_g3665 * lerpResult83_g3665 ) )).rgb , (temp_output_23_0_g3665).a));
				float4 temp_output_529_0_g3660 = appendResult29_g3665;
				float4 temp_output_72_0_g3667 = temp_output_529_0_g3660;
				float2 temp_output_5_0_g3667 = (worldPos).xz;
				float mulTime8_g3667 = _Time.y * -( WindOffsetSpeed * AirSpeedMultiplier );
				float2 UV67_g3667 = ( temp_output_5_0_g3667 + ( mulTime8_g3667 * (WindDirection).xz ) );
				float windAngle482_g3660 = WindAngle;
				float Angle67_g3667 = windAngle482_g3660;
				float2 localRotateUV67_g3667 = RotateUV67_g3667( UV67_g3667 , Angle67_g3667 );
				float smoothstepResult23_g3667 = smoothstep( AirSmoothstep.x , AirSmoothstep.y , tex2D( AirMap, ( (UnpackScaleNormal( tex2D( AirRefractionMap, ( temp_output_5_0_g3667 / AirRefractionTillingSize ) ), AirRefractionStrength )).xy + ( localRotateUV67_g3667 / AirTillingSize ) ) ).r);
				#ifdef _USEAIRSHEENTINT_ON
				float4 staticSwitch73_g3667 = saturate( ( temp_output_72_0_g3667 + ( smoothstepResult23_g3667 * AirStrength * saturate( ( IN.ase_color.r * 4.0 ) ) * windMask397_g3660 ) ) );
				#else
				float4 staticSwitch73_g3667 = temp_output_72_0_g3667;
				#endif
				float4 albedo109_g3669 = staticSwitch73_g3667;
				int isDebugWind98_g3669 = ( DebugWind + DebugWindTurbulence );
				int debugWindTurbulence103_g3669 = DebugWindTurbulence;
				int debugWind105_g3669 = DebugWind;
				half4 color126_g3669 = IsGammaSpace() ? half4(0,0,0,0) : half4(0,0,0,0);
				Gradient gradient82_g3669 = NewGradient( 0, 7, 2, float4( 0.5, 0.5, 0.5, 0 ), float4( 0, 0.716, 0, 0.06471352 ), float4( 1, 1, 0, 0.2205844 ), float4( 1, 0.5698085, 0, 0.5470665 ), float4( 1, 0.3047979, 0, 0.7499962 ), float4( 1, 0, 0, 0.9411765 ), float4( 0.5626073, 0, 1, 1 ), 0, float2( 1, 0 ), float2( 1, 1 ), 0, 0, 0, 0, 0, 0 );
				float4 temp_output_106_0_g3669 = ( (float)debugWind105_g3669 == 1.0 ? SampleGradient( gradient82_g3669, windMask397_g3660 ) : albedo109_g3669 );
				float4 ifLocalVar131_g3669 = 0;
				if( debugWindTurbulence103_g3669 <= debugWind105_g3669 )
				ifLocalVar131_g3669 = temp_output_106_0_g3669;
				else
				ifLocalVar131_g3669 = color126_g3669;
				half4 color64_g3669 = IsGammaSpace() ? half4(1,1,1,0) : half4(1,1,1,0);
				float4 transform119_g3683 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float mulTime95_g3683 = _Time.y * _TurbulenceSpeed;
				float3 ase_objectScale = float3( length( unity_ObjectToWorld[ 0 ].xyz ), length( unity_ObjectToWorld[ 1 ].xyz ), length( unity_ObjectToWorld[ 2 ].xyz ) );
				float temp_output_99_0_g3683 = ( cos( ( ( ( ( ( transform119_g3683.x * 100.0 ) + ( transform119_g3683.z * 33.0 ) ) - mulTime95_g3683 ) + IN.ase_texcoord9.xyz.y ) / _TurbulenceFrequency ) ) * _TurbulenceDisplacement * ase_objectScale.y * IN.ase_texcoord10.xy.y );
				float wpo_wind_rawMask497_g3679 = temp_output_2490_0;
				float smoothstepResult112_g3683 = smoothstep( 0.0 , _TurbulenceSmoothstepMax , wpo_wind_rawMask497_g3679);
				float temp_output_153_0_g3683 = saturate( smoothstepResult112_g3683 );
				float temp_output_544_85_g3679 = ( temp_output_99_0_g3683 * temp_output_153_0_g3683 );
				#if defined(_WIND_NONE)
				float staticSwitch441_g3679 = 0.0;
				#elif defined(_WIND_SIMPLE)
				float staticSwitch441_g3679 = temp_output_544_85_g3679;
				#elif defined(_WIND_ADVANCED)
				float staticSwitch441_g3679 = temp_output_544_85_g3679;
				#else
				float staticSwitch441_g3679 = temp_output_544_85_g3679;
				#endif
				float4 lerpResult62_g3669 = lerp( ifLocalVar131_g3669 , color64_g3669 , ( (float)debugWindTurbulence103_g3669 == 1.0 ? saturate( ( staticSwitch441_g3679 * 20.0 ) ) : 0.0 ));
				#ifdef _DEBUGWIND_ON
				float4 staticSwitch134_g3669 = ( (float)isDebugWind98_g3669 >= 1.0 ? lerpResult62_g3669 : albedo109_g3669 );
				#else
				float4 staticSwitch134_g3669 = albedo109_g3669;
				#endif
				
				float2 uv_NormalMap71_g3660 = IN.ase_texcoord10.xy;
				float3 lerpResult417_g3660 = lerp( half3(0,0,1) , UnpackScaleNormal( tex2D( _NormalMap, uv_NormalMap71_g3660 ), _NormalStrength ) , saturate( ( coord_mask88_g3660 * 3.0 ) ));
				
				o.Albedo = (staticSwitch134_g3669).xyz;
				o.Normal = lerpResult417_g3660;
				o.Emission = half3( 0, 0, 0 );
				#if defined(_SPECULAR_SETUP)
					o.Specular = fixed3( 0, 0, 0 );
				#else
					o.Metallic = 0;
				#endif
				o.Smoothness = 0.0;
				o.Occlusion = 1;
				o.Alpha = (temp_output_529_0_g3660).a;
				float AlphaClipThreshold = _AlphaThreshold;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;

				#ifdef _ALPHATEST_ON
					clip( o.Alpha - AlphaClipThreshold );
				#endif

				#ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
				#endif

				#ifndef USING_DIRECTIONAL_LIGHT
					fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				#else
					fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				#endif

				fixed4 c = 0;
				float3 worldN;
				worldN.x = dot(IN.tSpace0.xyz, o.Normal);
				worldN.y = dot(IN.tSpace1.xyz, o.Normal);
				worldN.z = dot(IN.tSpace2.xyz, o.Normal);
				worldN = normalize(worldN);
				o.Normal = worldN;

				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
				gi.light.color = _LightColor0.rgb;
				gi.light.dir = lightDir;

				UnityGIInput giInput;
				UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
				giInput.light = gi.light;
				giInput.worldPos = worldPos;
				giInput.worldViewDir = worldViewDir;
				giInput.atten = atten;
				#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
					giInput.lightmapUV = IN.lmap;
				#else
					giInput.lightmapUV = 0.0;
				#endif
				#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
					giInput.ambient = IN.sh;
				#else
					giInput.ambient.rgb = 0.0;
				#endif
				giInput.probeHDR[0] = unity_SpecCube0_HDR;
				giInput.probeHDR[1] = unity_SpecCube1_HDR;
				#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
					giInput.boxMin[0] = unity_SpecCube0_BoxMin;
				#endif
				#ifdef UNITY_SPECCUBE_BOX_PROJECTION
					giInput.boxMax[0] = unity_SpecCube0_BoxMax;
					giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
					giInput.boxMax[1] = unity_SpecCube1_BoxMax;
					giInput.boxMin[1] = unity_SpecCube1_BoxMin;
					giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
				#endif

				#if defined(_SPECULAR_SETUP)
					LightingStandardSpecular_GI(o, giInput, gi);
				#else
					LightingStandard_GI( o, giInput, gi );
				#endif

				#ifdef ASE_BAKEDGI
					gi.indirect.diffuse = BakedGI;
				#endif

				#if UNITY_SHOULD_SAMPLE_SH && !defined(LIGHTMAP_ON) && defined(ASE_NO_AMBIENT)
					gi.indirect.diffuse = 0;
				#endif

				#if defined(_SPECULAR_SETUP)
					c += LightingStandardSpecular (o, worldViewDir, gi);
				#else
					c += LightingStandard( o, worldViewDir, gi );
				#endif

				#ifdef ASE_TRANSMISSION
				{
					float shadow = _TransmissionShadow;
					#ifdef DIRECTIONAL
						float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
					#else
						float3 lightAtten = gi.light.color;
					#endif
					half3 transmission = max(0 , -dot(o.Normal, gi.light.dir)) * lightAtten * Transmission;
					c.rgb += o.Albedo * transmission;
				}
				#endif

				#ifdef ASE_TRANSLUCENCY
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					#ifdef DIRECTIONAL
						float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
					#else
						float3 lightAtten = gi.light.color;
					#endif
					half3 lightDir = gi.light.dir + o.Normal * normal;
					half transVdotL = pow( saturate( dot( worldViewDir, -lightDir ) ), scattering );
					half3 translucency = lightAtten * (transVdotL * direct + gi.indirect.diffuse * ambient) * Translucency;
					c.rgb += o.Albedo * translucency * strength;
				}
				#endif

				//#ifdef ASE_REFRACTION
				//	float4 projScreenPos = ScreenPos / ScreenPos.w;
				//	float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, WorldNormal ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
				//	projScreenPos.xy += refractionOffset.xy;
				//	float3 refraction = UNITY_SAMPLE_SCREENSPACE_TEXTURE( _GrabTexture, projScreenPos ) * RefractionColor;
				//	color.rgb = lerp( refraction, color.rgb, color.a );
				//	color.a = 1;
				//#endif

				c.rgb += o.Emission;

				#ifdef ASE_FOG
					UNITY_APPLY_FOG(IN.fogCoord, c);
				#endif
				return c;
			}
			ENDCG
		}

		
		Pass
		{
			
			Name "ForwardAdd"
			Tags { "LightMode"="ForwardAdd" }
			ZWrite Off
			Blend One One

			CGPROGRAM
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile_instancing
			#pragma multi_compile __ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1

			#pragma vertex vert
			#pragma fragment frag
			#pragma skip_variants INSTANCING_ON
			#pragma multi_compile_fwdadd_fullshadows
			#ifndef UNITY_PASS_FORWARDADD
				#define UNITY_PASS_FORWARDADD
			#endif
			#include "HLSLSupport.cginc"
			#if !defined( UNITY_INSTANCED_LOD_FADE )
				#define UNITY_INSTANCED_LOD_FADE
			#endif
			#if !defined( UNITY_INSTANCED_SH )
				#define UNITY_INSTANCED_SH
			#endif
			#if !defined( UNITY_INSTANCED_LIGHTMAPSTS )
				#define UNITY_INSTANCED_LIGHTMAPSTS
			#endif
			#include "UnityShaderVariables.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "AutoLight.cginc"

			#include "UnityStandardUtils.cginc"
			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_POSITION
			#define ASE_NEEDS_FRAG_COLOR
			#pragma multi_compile_local __ _DEBUGDISABLEWINDDPO_ON
			#pragma shader_feature_local _WIND_NONE _WIND_SIMPLE _WIND_ADVANCED
			#pragma shader_feature_local _USECRUSH_ON
			#pragma multi_compile_local_fragment __ _DEBUGWIND_ON
			#pragma shader_feature_local _USEAIRSHEENTINT_ON
			#pragma shader_feature_local _USECOLORMAP_ON

			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			struct v2f {
				#if UNITY_VERSION >= 201810
					UNITY_POSITION(pos);
				#else
					float4 pos : SV_POSITION;
				#endif
				#if UNITY_VERSION >= 201810 && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_LIGHTING_COORDS(1,2)
				#elif defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if UNITY_VERSION >= 201710
						UNITY_SHADOW_COORDS(1)
					#else
						SHADOW_COORDS(1)
					#endif
				#endif
				#ifdef ASE_FOG
					UNITY_FOG_COORDS(3)
				#endif
				float4 tSpace0 : TEXCOORD5;
				float4 tSpace1 : TEXCOORD6;
				float4 tSpace2 : TEXCOORD7;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 screenPos : TEXCOORD8;
				#endif
				float4 ase_texcoord9 : TEXCOORD9;
				float4 ase_texcoord10 : TEXCOORD10;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			uniform half _UseTreeBend;
			uniform float3 WindDirection;
			uniform float WindOffsetSpeed;
			uniform float WindTillingSize;
			uniform float2 _SecondWindSmoothstep;
			uniform float2 WindSmoothstep;
			uniform sampler2D WindMap;
			uniform half WindAmplitude;
			uniform half DebugDisableWPO;
			uniform half2 _BezierP1;
			uniform half _BezierAlpha;
			uniform half2 _BezierOffsetP1;
			uniform half _BezierOffsetAlpha;
			uniform half2 _BezierP2;
			uniform half2 _BezierOffsetP2;
			uniform half _SimpleWindyYOffset;
			uniform half _SimpleWindDisplacement;
			uniform sampler2D CrushRenderTexture;
			uniform float2 CrushBufferOffset;
			uniform half CrushBufferSize;
			uniform half _CrushAngle;
			uniform half _CrushFlattenScale;
			uniform half _CrushHeightOffset;
			uniform half CrushDistanceView;
			uniform half CrushDistanceViewFalloff;
			uniform half _TurbulenceSmoothstepMax;
			uniform half _TurbulenceSpeed;
			uniform half _TurbulenceFrequency;
			uniform half _TurbulenceDisplacement;
			uniform float _FlattenVertexNormal;
			uniform half4 _MainBaseColor;
			uniform half4 _VariantBaseColor;
			uniform half _VariantOffset;
			uniform half _VariantContrast;
			uniform sampler2D _BaseMap;
			uniform sampler2D ColorMap;
			uniform float2 ColorMapOffset;
			uniform float2 ColorMapTillingSize;
			uniform half _ColorMapBlendOffset;
			uniform half _ColorMapFadeContrast;
			uniform half _WindBrightness;
			uniform half _CrushBrightness;
			uniform half2 AirSmoothstep;
			uniform sampler2D AirMap;
			uniform sampler2D AirRefractionMap;
			uniform half AirRefractionTillingSize;
			uniform half AirRefractionStrength;
			uniform half AirSpeedMultiplier;
			uniform float WindAngle;
			uniform half2 AirTillingSize;
			uniform half AirStrength;
			uniform int DebugWind;
			uniform int DebugWindTurbulence;
			uniform sampler2D _NormalMap;
			uniform half _NormalStrength;
			uniform half _AlphaThreshold;


			float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
			{
				original -= center;
				float C = cos( angle );
				float S = sin( angle );
				float t = 1 - C;
				float m00 = t * u.x * u.x + C;
				float m01 = t * u.x * u.y - S * u.z;
				float m02 = t * u.x * u.z + S * u.y;
				float m10 = t * u.x * u.y + S * u.z;
				float m11 = t * u.y * u.y + C;
				float m12 = t * u.y * u.z - S * u.x;
				float m20 = t * u.x * u.z - S * u.y;
				float m21 = t * u.y * u.z + S * u.x;
				float m22 = t * u.z * u.z + C;
				float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
				return mul( finalMatrix, original ) + center;
			}
			
			float3 TrigonometricBezierCurve( float3 p1, float3 p2, float t )
			{
				float3 p0 = float3(0, 0, 0);
				float u = 1 - t;
				float t2 = t * t;
				float u2 = u * u;
				float3 result =
					(u2)*p0 +
					(2 * u * t) * p1 +
					t2 * p2;
				return result;
			}
			
			float CheapContrast1_g3661( float In, float Value )
			{
				float A = 0 - Value;
				float B = 1 + Value;
				return clamp(0,1, lerp(A,B,In));
			}
			
			float CheapContrast1_g3663( float In, float Value )
			{
				float A = 0 - Value;
				float B = 1 + Value;
				return clamp(0,1, lerp(A,B,In));
			}
			
			float2 RotateUV67_g3667( float2 UV, float Angle )
			{
				// Rotation Matrix
				                float cosAngle = cos(Angle);
				                float sinAngle = sin(Angle);
				                float2x2 rot = float2x2(cosAngle, -sinAngle, sinAngle, cosAngle);
				 
				                // Rotation
				                return mul(rot, UV);
			}
			
			struct Gradient
			{
				int type;
				int colorsLength;
				int alphasLength;
				float4 colors[8];
				float2 alphas[8];
			};
			
			Gradient NewGradient(int type, int colorsLength, int alphasLength, 
			float4 colors0, float4 colors1, float4 colors2, float4 colors3, float4 colors4, float4 colors5, float4 colors6, float4 colors7,
			float2 alphas0, float2 alphas1, float2 alphas2, float2 alphas3, float2 alphas4, float2 alphas5, float2 alphas6, float2 alphas7)
			{
				Gradient g;
				g.type = type;
				g.colorsLength = colorsLength;
				g.alphasLength = alphasLength;
				g.colors[ 0 ] = colors0;
				g.colors[ 1 ] = colors1;
				g.colors[ 2 ] = colors2;
				g.colors[ 3 ] = colors3;
				g.colors[ 4 ] = colors4;
				g.colors[ 5 ] = colors5;
				g.colors[ 6 ] = colors6;
				g.colors[ 7 ] = colors7;
				g.alphas[ 0 ] = alphas0;
				g.alphas[ 1 ] = alphas1;
				g.alphas[ 2 ] = alphas2;
				g.alphas[ 3 ] = alphas3;
				g.alphas[ 4 ] = alphas4;
				g.alphas[ 5 ] = alphas5;
				g.alphas[ 6 ] = alphas6;
				g.alphas[ 7 ] = alphas7;
				return g;
			}
			
			float4 SampleGradient( Gradient gradient, float time )
			{
				float3 color = gradient.colors[0].rgb;
				UNITY_UNROLL
				for (int c = 1; c < 8; c++)
				{
				float colorPos = saturate((time - gradient.colors[c-1].w) / ( 0.00001 + (gradient.colors[c].w - gradient.colors[c-1].w)) * step(c, (float)gradient.colorsLength-1));
				color = lerp(color, gradient.colors[c].rgb, lerp(colorPos, step(0.01, colorPos), gradient.type));
				}
				#ifndef UNITY_COLORSPACE_GAMMA
				color = half3(GammaToLinearSpaceExact(color.r), GammaToLinearSpaceExact(color.g), GammaToLinearSpaceExact(color.b));
				#endif
				float alpha = gradient.alphas[0].x;
				UNITY_UNROLL
				for (int a = 1; a < 8; a++)
				{
				float alphaPos = saturate((time - gradient.alphas[a-1].y) / ( 0.00001 + (gradient.alphas[a].y - gradient.alphas[a-1].y)) * step(a, (float)gradient.alphasLength-1));
				alpha = lerp(alpha, gradient.alphas[a].x, lerp(alphaPos, step(0.01, alphaPos), gradient.type));
				}
				return float4(color, alpha);
			}
			

			v2f VertexFunction (appdata v  ) {
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 temp_output_331_0_g3680 = (half3(0,0,1)).xz;
				float3 worldToObjDir141_g3687 = normalize( mul( unity_WorldToObject, float4( WindDirection, 0 ) ).xyz );
				float3 wpo_wind_direction306_g3679 = worldToObjDir141_g3687;
				float3 temp_output_295_0_g3680 = wpo_wind_direction306_g3679;
				float dotResult330_g3680 = dot( temp_output_331_0_g3680 , (temp_output_295_0_g3680).xz );
				float3 break444_g3680 = temp_output_295_0_g3680;
				float2 appendResult355_g3680 = (float2(break444_g3680.z , break444_g3680.x));
				float dotResult356_g3680 = dot( temp_output_331_0_g3680 , appendResult355_g3680 );
				float3 objToWorld183_g3687 = mul( unity_ObjectToWorld, float4( v.vertex.xyz, 1 ) ).xyz;
				float3 break153_g3687 = -objToWorld183_g3687;
				float2 appendResult155_g3687 = (float2(break153_g3687.x , break153_g3687.z));
				float2 _wind_UVs106_g3687 = appendResult155_g3687;
				float mulTime137_g3687 = _Time.y * ( WindOffsetSpeed / 10.0 );
				float3 break187_g3687 = WindDirection;
				float2 appendResult188_g3687 = (float2(break187_g3687.x , break187_g3687.z));
				float2 _wind_direction110_g3687 = appendResult188_g3687;
				float4 tex2DNode144_g3687 = tex2Dlod( WindMap, float4( ( ( _wind_UVs106_g3687 / WindTillingSize ) + ( mulTime137_g3687 * _wind_direction110_g3687 ) ), 0, 0.0) );
				float smoothstepResult53_g3687 = smoothstep( WindSmoothstep.x , WindSmoothstep.y , tex2DNode144_g3687.r);
				float smoothstepResult170_g3687 = smoothstep( _SecondWindSmoothstep.x , _SecondWindSmoothstep.y , smoothstepResult53_g3687);
				float _wind_amplitude116_g3687 = WindAmplitude;
				float temp_output_2490_0 = ( smoothstepResult170_g3687 * _wind_amplitude116_g3687 );
				float wpo_wind_rawMask497_g3679 = temp_output_2490_0;
				float debug_disableWPO486_g3679 = DebugDisableWPO;
				#ifdef _DEBUGDISABLEWINDDPO_ON
				float staticSwitch479_g3679 = ( debug_disableWPO486_g3679 == 1.0 ? 0.0 : wpo_wind_rawMask497_g3679 );
				#else
				float staticSwitch479_g3679 = wpo_wind_rawMask497_g3679;
				#endif
				float wpo_wind_mask302_g3679 = staticSwitch479_g3679;
				float wind_mask423_g3680 = wpo_wind_mask302_g3679;
				float lerpResult192_g3680 = lerp( 0.0 , ( acos( dotResult330_g3680 ) * sign( dotResult356_g3680 ) ) , wind_mask423_g3680);
				float3 appendResult465_g3680 = (float3(0.0 , _BezierP1.y , _BezierP1.x));
				float3 temp_output_453_0_g3680 = ( appendResult465_g3680 * _BezierAlpha );
				float3 appendResult419_g3680 = (float3(0.0 , _BezierOffsetP1.y , _BezierOffsetP1.x));
				float3 rotatedValue187_g3680 = RotateAroundAxis( float3( 0,0,0 ), ( temp_output_453_0_g3680 + ( appendResult419_g3680 * wind_mask423_g3680 * _BezierOffsetAlpha ) ), float3( 0,1,0 ), lerpResult192_g3680 );
				float3 temp_output_15_0_g3681 = rotatedValue187_g3680;
				float3 p121_g3681 = temp_output_15_0_g3681;
				float3 appendResult463_g3680 = (float3(0.0 , _BezierP2.y , _BezierP2.x));
				float3 temp_output_454_0_g3680 = ( appendResult463_g3680 * _BezierAlpha );
				float3 appendResult420_g3680 = (float3(0.0 , _BezierOffsetP2.y , _BezierOffsetP2.x));
				float3 rotatedValue195_g3680 = RotateAroundAxis( float3( 0,0,0 ), ( temp_output_454_0_g3680 + ( appendResult420_g3680 * wind_mask423_g3680 * _BezierOffsetAlpha ) ), float3( 0,1,0 ), lerpResult192_g3680 );
				float3 temp_output_14_0_g3681 = rotatedValue195_g3680;
				float3 p221_g3681 = temp_output_14_0_g3681;
				float wpo_CoordMask184_g3679 = v.ase_color.r;
				float temp_output_6_0_g3681 = wpo_CoordMask184_g3679;
				float t21_g3681 = temp_output_6_0_g3681;
				float3 localTrigonometricBezierCurve21_g3681 = TrigonometricBezierCurve( p121_g3681 , p221_g3681 , t21_g3681 );
				float3 temp_output_500_0_g3679 = localTrigonometricBezierCurve21_g3681;
				half3 _RelativeUp = half3(0,1,0);
				float3 temp_output_26_0_g3682 = wpo_wind_direction306_g3679;
				float dotResult7_g3682 = dot( temp_output_26_0_g3682 , _RelativeUp );
				float lerpResult10_g3682 = lerp( -1.570796 , 1.570796 , ( ( dotResult7_g3682 * 0.5 ) + 0.5 ));
				float3 rotatedValue17_g3682 = RotateAroundAxis( float3( 0,0,0 ), temp_output_26_0_g3682, normalize( cross( _RelativeUp , temp_output_26_0_g3682 ) ), lerpResult10_g3682 );
				float temp_output_25_0_g3682 = wpo_wind_mask302_g3679;
				float lerpResult21_g3682 = lerp( 0.0 , _SimpleWindyYOffset , temp_output_25_0_g3682);
				float3 appendResult23_g3682 = (float3(0.0 , lerpResult21_g3682 , 0.0));
				float3 temp_output_499_0_g3679 = ( wpo_CoordMask184_g3679 * ( ( rotatedValue17_g3682 + appendResult23_g3682 ) * _SimpleWindDisplacement * temp_output_25_0_g3682 ) );
				#if defined(_WIND_NONE)
				float3 staticSwitch166_g3679 = float3( 0,0,0 );
				#elif defined(_WIND_SIMPLE)
				float3 staticSwitch166_g3679 = temp_output_499_0_g3679;
				#elif defined(_WIND_ADVANCED)
				float3 staticSwitch166_g3679 = temp_output_500_0_g3679;
				#else
				float3 staticSwitch166_g3679 = temp_output_500_0_g3679;
				#endif
				float3 out_wpo_windy423_g3679 = staticSwitch166_g3679;
				float3 temp_output_159_0_g3686 = out_wpo_windy423_g3679;
				float4 transform584_g3679 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float4 tex2DNode29_g3686 = tex2Dlod( CrushRenderTexture, float4( ( ( ( (transform584_g3679).xz + -CrushBufferOffset ) + ( CrushBufferSize / 2.0 ) ) / CrushBufferSize ), 0, 0.0) );
				float2 temp_output_96_0_g3686 = ( ( (tex2DNode29_g3686).rg - float2( 0.5,0.5 ) ) * float2( 2,2 ) );
				float2 break98_g3686 = temp_output_96_0_g3686;
				float3 appendResult102_g3686 = (float3(break98_g3686.x , 0.0 , break98_g3686.y));
				float3 worldToObjDir101_g3686 = mul( unity_WorldToObject, float4( appendResult102_g3686, 0 ) ).xyz;
				float3 crush_direction172_g3686 = worldToObjDir101_g3686;
				float vectorField_length134_g3686 = length( temp_output_96_0_g3686 );
				float3 temp_output_126_0_g3686 = float3( 0,0,0 );
				float3 ase_worldPos = mul(unity_ObjectToWorld, float4( (v.vertex).xyz, 1 )).xyz;
				float3 worldToObj14_g3686 = mul( unity_WorldToObject, float4( ase_worldPos, 1 ) ).xyz;
				float3 rotatedValue16_g3686 = RotateAroundAxis( temp_output_126_0_g3686, worldToObj14_g3686, crush_direction172_g3686, ( radians( _CrushAngle ) * vectorField_length134_g3686 ) );
				float3 appendResult195_g3686 = (float3(1.0 , ( 1.0 - _CrushFlattenScale ) , 1.0));
				float3 appendResult66_g3686 = (float3(0.0 , _CrushHeightOffset , 0.0));
				float crush_coordMasd87_g3686 = wpo_CoordMask184_g3679;
				float3 ase_parentObjectScale = ( 1.0 / float3( length( unity_WorldToObject[ 0 ].xyz ), length( unity_WorldToObject[ 1 ].xyz ), length( unity_WorldToObject[ 2 ].xyz ) ) );
				float RT_b236_g3686 = tex2DNode29_g3686.b;
				float4 transform223_g3686 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float temp_output_235_0_g3686 = ( RT_b236_g3686 == 0.0 ? ( ( vectorField_length134_g3686 * saturate( ( crush_coordMasd87_g3686 * 8.0 ) ) ) * saturate( ( ( CrushDistanceView - distance( float4( _WorldSpaceCameraPos , 0.0 ) , transform223_g3686 ) ) / CrushDistanceViewFalloff ) ) ) : 0.0 );
				float3 lerpResult160_g3686 = lerp( temp_output_159_0_g3686 , ( ( ( rotatedValue16_g3686 - worldToObj14_g3686 ) * appendResult195_g3686 ) + ( appendResult66_g3686 * crush_coordMasd87_g3686 * ase_parentObjectScale.y ) ) , temp_output_235_0_g3686);
				#ifdef _USECRUSH_ON
				float3 staticSwitch162_g3686 = lerpResult160_g3686;
				#else
				float3 staticSwitch162_g3686 = temp_output_159_0_g3686;
				#endif
				float3 out_wpo_crush432_g3679 = staticSwitch162_g3686;
				float smoothstepResult112_g3683 = smoothstep( 0.0 , _TurbulenceSmoothstepMax , wpo_wind_rawMask497_g3679);
				float temp_output_153_0_g3683 = saturate( smoothstepResult112_g3683 );
				float4 transform119_g3683 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float mulTime95_g3683 = _Time.y * _TurbulenceSpeed;
				float3 ase_objectScale = float3( length( unity_ObjectToWorld[ 0 ].xyz ), length( unity_ObjectToWorld[ 1 ].xyz ), length( unity_ObjectToWorld[ 2 ].xyz ) );
				float temp_output_99_0_g3683 = ( cos( ( ( ( ( ( transform119_g3683.x * 100.0 ) + ( transform119_g3683.z * 33.0 ) ) - mulTime95_g3683 ) + v.vertex.xyz.y ) / _TurbulenceFrequency ) ) * _TurbulenceDisplacement * ase_objectScale.y * v.ase_texcoord.y );
				float3 temp_output_88_0_g3683 = wpo_wind_direction306_g3679;
				float3 temp_output_544_0_g3679 = ( out_wpo_crush432_g3679 + ( temp_output_153_0_g3683 * temp_output_99_0_g3683 * temp_output_88_0_g3683 ) );
				#if defined(_WIND_NONE)
				float3 staticSwitch438_g3679 = float3( 0,0,0 );
				#elif defined(_WIND_SIMPLE)
				float3 staticSwitch438_g3679 = temp_output_544_0_g3679;
				#elif defined(_WIND_ADVANCED)
				float3 staticSwitch438_g3679 = temp_output_544_0_g3679;
				#else
				float3 staticSwitch438_g3679 = temp_output_544_0_g3679;
				#endif
				float3 wpo_out_turbulence508_g3679 = staticSwitch438_g3679;
				#ifdef _DEBUGDISABLEWINDDPO_ON
				float3 staticSwitch466_g3679 = ( debug_disableWPO486_g3679 == 1.0 ? out_wpo_crush432_g3679 : wpo_out_turbulence508_g3679 );
				#else
				float3 staticSwitch466_g3679 = wpo_out_turbulence508_g3679;
				#endif
				
				float3 lerpResult3_g2806 = lerp( v.normal , float3(0,1,0) , _FlattenVertexNormal);
				
				o.ase_texcoord9 = v.vertex;
				o.ase_texcoord10.xy = v.ase_texcoord.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord10.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = staticSwitch466_g3679;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.vertex.w = 1;
				v.normal = lerpResult3_g2806;
				v.tangent = v.tangent;

				o.pos = UnityObjectToClipPos(v.vertex);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
				o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				#if UNITY_VERSION >= 201810 && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_TRANSFER_LIGHTING(o, v.texcoord1.xy);
				#elif defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if UNITY_VERSION >= 201710
						UNITY_TRANSFER_SHADOW(o, v.texcoord1.xy);
					#else
						TRANSFER_SHADOW(o);
					#endif
				#endif

				#ifdef ASE_FOG
					UNITY_TRANSFER_FOG(o,o.pos);
				#endif
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
					o.screenPos = ComputeScreenPos(o.pos);
				#endif
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			v2f vert ( appdata v )
			{
				return VertexFunction( v );
			}
			#endif

			fixed4 frag ( v2f IN 
				#ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
				#endif
				) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				#ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
				#endif

				#if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
				#else
					SurfaceOutputStandard o = (SurfaceOutputStandard)0;
				#endif
				float3 WorldTangent = float3(IN.tSpace0.x,IN.tSpace1.x,IN.tSpace2.x);
				float3 WorldBiTangent = float3(IN.tSpace0.y,IN.tSpace1.y,IN.tSpace2.y);
				float3 WorldNormal = float3(IN.tSpace0.z,IN.tSpace1.z,IN.tSpace2.z);
				float3 worldPos = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
				#else
					half atten = 1;
				#endif
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 ScreenPos = IN.screenPos;
				#endif


				float3 temp_cast_0 = (IN.ase_texcoord9.xyz.y).xxx;
				float3 objToWorld541_g3660 = mul( unity_ObjectToWorld, float4( temp_cast_0, 1 ) ).xyz;
				float In1_g3661 = ( objToWorld541_g3660.y + _VariantOffset );
				float Value1_g3661 = _VariantContrast;
				float localCheapContrast1_g3661 = CheapContrast1_g3661( In1_g3661 , Value1_g3661 );
				float4 lerpResult350_g3660 = lerp( _MainBaseColor , _VariantBaseColor , saturate( localCheapContrast1_g3661 ));
				float4 appendResult442_g3660 = (float4((lerpResult350_g3660).rgb , 1.0));
				float2 uv_BaseMap53_g3660 = IN.ase_texcoord10.xy;
				float4 tex2DNode53_g3660 = tex2D( _BaseMap, uv_BaseMap53_g3660 );
				float4 _baseMap50_g3660 = tex2DNode53_g3660;
				float4 temp_output_428_0_g3660 = ( appendResult442_g3660 * _baseMap50_g3660 );
				float4 temp_output_124_0_g3662 = temp_output_428_0_g3660;
				float3 temp_output_125_0_g3662 = (temp_output_124_0_g3662).rgb;
				float _colormap_baseMap_Alpha146_g3662 = (temp_output_124_0_g3662).a;
				float4 appendResult132_g3662 = (float4(temp_output_125_0_g3662 , _colormap_baseMap_Alpha146_g3662));
				float coord_mask88_g3660 = IN.ase_color.r;
				float In1_g3663 = ( coord_mask88_g3660 - _ColorMapBlendOffset );
				float Value1_g3663 = _ColorMapFadeContrast;
				float localCheapContrast1_g3663 = CheapContrast1_g3663( In1_g3663 , Value1_g3663 );
				float3 lerpResult97_g3662 = lerp( (tex2D( ColorMap, ( ( (worldPos).xz + ColorMapOffset ) / ColorMapTillingSize ) )).rgb , temp_output_125_0_g3662 , saturate( ( (lerpResult350_g3660).a * localCheapContrast1_g3663 ) ));
				float3 break65_g3662 = lerpResult97_g3662;
				float4 appendResult64_g3662 = (float4(break65_g3662.x , break65_g3662.y , break65_g3662.z , _colormap_baseMap_Alpha146_g3662));
				#ifdef _USECOLORMAP_ON
				float4 staticSwitch128_g3662 = appendResult64_g3662;
				#else
				float4 staticSwitch128_g3662 = appendResult132_g3662;
				#endif
				float4 temp_output_23_0_g3665 = staticSwitch128_g3662;
				float3 objToWorld183_g3687 = mul( unity_ObjectToWorld, float4( IN.ase_texcoord9.xyz, 1 ) ).xyz;
				float3 break153_g3687 = -objToWorld183_g3687;
				float2 appendResult155_g3687 = (float2(break153_g3687.x , break153_g3687.z));
				float2 _wind_UVs106_g3687 = appendResult155_g3687;
				float mulTime137_g3687 = _Time.y * ( WindOffsetSpeed / 10.0 );
				float3 break187_g3687 = WindDirection;
				float2 appendResult188_g3687 = (float2(break187_g3687.x , break187_g3687.z));
				float2 _wind_direction110_g3687 = appendResult188_g3687;
				float4 tex2DNode144_g3687 = tex2D( WindMap, ( ( _wind_UVs106_g3687 / WindTillingSize ) + ( mulTime137_g3687 * _wind_direction110_g3687 ) ) );
				float smoothstepResult53_g3687 = smoothstep( WindSmoothstep.x , WindSmoothstep.y , tex2DNode144_g3687.r);
				float smoothstepResult170_g3687 = smoothstep( _SecondWindSmoothstep.x , _SecondWindSmoothstep.y , smoothstepResult53_g3687);
				float _wind_amplitude116_g3687 = WindAmplitude;
				float temp_output_2490_0 = ( smoothstepResult170_g3687 * _wind_amplitude116_g3687 );
				float windMask397_g3660 = temp_output_2490_0;
				float lerpResult71_g3665 = lerp( 1.0 , _WindBrightness , windMask397_g3660);
				float4 transform584_g3679 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float4 tex2DNode29_g3686 = tex2D( CrushRenderTexture, ( ( ( (transform584_g3679).xz + -CrushBufferOffset ) + ( CrushBufferSize / 2.0 ) ) / CrushBufferSize ) );
				float RT_b236_g3686 = tex2DNode29_g3686.b;
				float2 temp_output_96_0_g3686 = ( ( (tex2DNode29_g3686).rg - float2( 0.5,0.5 ) ) * float2( 2,2 ) );
				float vectorField_length134_g3686 = length( temp_output_96_0_g3686 );
				float wpo_CoordMask184_g3679 = IN.ase_color.r;
				float crush_coordMasd87_g3686 = wpo_CoordMask184_g3679;
				float4 transform223_g3686 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float temp_output_235_0_g3686 = ( RT_b236_g3686 == 0.0 ? ( ( vectorField_length134_g3686 * saturate( ( crush_coordMasd87_g3686 * 8.0 ) ) ) * saturate( ( ( CrushDistanceView - distance( float4( _WorldSpaceCameraPos , 0.0 ) , transform223_g3686 ) ) / CrushDistanceViewFalloff ) ) ) : 0.0 );
				#ifdef _USECRUSH_ON
				float staticSwitch163_g3686 = temp_output_235_0_g3686;
				#else
				float staticSwitch163_g3686 = 0.0;
				#endif
				float lerpResult78_g3665 = lerp( lerpResult71_g3665 , _CrushBrightness , staticSwitch163_g3686);
				float lerpResult83_g3665 = lerp( 1.0 , lerpResult78_g3665 , saturate( ( coord_mask88_g3660 * 2.0 ) ));
				float4 appendResult29_g3665 = (float4((saturate( ( temp_output_23_0_g3665 * lerpResult83_g3665 ) )).rgb , (temp_output_23_0_g3665).a));
				float4 temp_output_529_0_g3660 = appendResult29_g3665;
				float4 temp_output_72_0_g3667 = temp_output_529_0_g3660;
				float2 temp_output_5_0_g3667 = (worldPos).xz;
				float mulTime8_g3667 = _Time.y * -( WindOffsetSpeed * AirSpeedMultiplier );
				float2 UV67_g3667 = ( temp_output_5_0_g3667 + ( mulTime8_g3667 * (WindDirection).xz ) );
				float windAngle482_g3660 = WindAngle;
				float Angle67_g3667 = windAngle482_g3660;
				float2 localRotateUV67_g3667 = RotateUV67_g3667( UV67_g3667 , Angle67_g3667 );
				float smoothstepResult23_g3667 = smoothstep( AirSmoothstep.x , AirSmoothstep.y , tex2D( AirMap, ( (UnpackScaleNormal( tex2D( AirRefractionMap, ( temp_output_5_0_g3667 / AirRefractionTillingSize ) ), AirRefractionStrength )).xy + ( localRotateUV67_g3667 / AirTillingSize ) ) ).r);
				#ifdef _USEAIRSHEENTINT_ON
				float4 staticSwitch73_g3667 = saturate( ( temp_output_72_0_g3667 + ( smoothstepResult23_g3667 * AirStrength * saturate( ( IN.ase_color.r * 4.0 ) ) * windMask397_g3660 ) ) );
				#else
				float4 staticSwitch73_g3667 = temp_output_72_0_g3667;
				#endif
				float4 albedo109_g3669 = staticSwitch73_g3667;
				int isDebugWind98_g3669 = ( DebugWind + DebugWindTurbulence );
				int debugWindTurbulence103_g3669 = DebugWindTurbulence;
				int debugWind105_g3669 = DebugWind;
				half4 color126_g3669 = IsGammaSpace() ? half4(0,0,0,0) : half4(0,0,0,0);
				Gradient gradient82_g3669 = NewGradient( 0, 7, 2, float4( 0.5, 0.5, 0.5, 0 ), float4( 0, 0.716, 0, 0.06471352 ), float4( 1, 1, 0, 0.2205844 ), float4( 1, 0.5698085, 0, 0.5470665 ), float4( 1, 0.3047979, 0, 0.7499962 ), float4( 1, 0, 0, 0.9411765 ), float4( 0.5626073, 0, 1, 1 ), 0, float2( 1, 0 ), float2( 1, 1 ), 0, 0, 0, 0, 0, 0 );
				float4 temp_output_106_0_g3669 = ( (float)debugWind105_g3669 == 1.0 ? SampleGradient( gradient82_g3669, windMask397_g3660 ) : albedo109_g3669 );
				float4 ifLocalVar131_g3669 = 0;
				if( debugWindTurbulence103_g3669 <= debugWind105_g3669 )
				ifLocalVar131_g3669 = temp_output_106_0_g3669;
				else
				ifLocalVar131_g3669 = color126_g3669;
				half4 color64_g3669 = IsGammaSpace() ? half4(1,1,1,0) : half4(1,1,1,0);
				float4 transform119_g3683 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float mulTime95_g3683 = _Time.y * _TurbulenceSpeed;
				float3 ase_objectScale = float3( length( unity_ObjectToWorld[ 0 ].xyz ), length( unity_ObjectToWorld[ 1 ].xyz ), length( unity_ObjectToWorld[ 2 ].xyz ) );
				float temp_output_99_0_g3683 = ( cos( ( ( ( ( ( transform119_g3683.x * 100.0 ) + ( transform119_g3683.z * 33.0 ) ) - mulTime95_g3683 ) + IN.ase_texcoord9.xyz.y ) / _TurbulenceFrequency ) ) * _TurbulenceDisplacement * ase_objectScale.y * IN.ase_texcoord10.xy.y );
				float wpo_wind_rawMask497_g3679 = temp_output_2490_0;
				float smoothstepResult112_g3683 = smoothstep( 0.0 , _TurbulenceSmoothstepMax , wpo_wind_rawMask497_g3679);
				float temp_output_153_0_g3683 = saturate( smoothstepResult112_g3683 );
				float temp_output_544_85_g3679 = ( temp_output_99_0_g3683 * temp_output_153_0_g3683 );
				#if defined(_WIND_NONE)
				float staticSwitch441_g3679 = 0.0;
				#elif defined(_WIND_SIMPLE)
				float staticSwitch441_g3679 = temp_output_544_85_g3679;
				#elif defined(_WIND_ADVANCED)
				float staticSwitch441_g3679 = temp_output_544_85_g3679;
				#else
				float staticSwitch441_g3679 = temp_output_544_85_g3679;
				#endif
				float4 lerpResult62_g3669 = lerp( ifLocalVar131_g3669 , color64_g3669 , ( (float)debugWindTurbulence103_g3669 == 1.0 ? saturate( ( staticSwitch441_g3679 * 20.0 ) ) : 0.0 ));
				#ifdef _DEBUGWIND_ON
				float4 staticSwitch134_g3669 = ( (float)isDebugWind98_g3669 >= 1.0 ? lerpResult62_g3669 : albedo109_g3669 );
				#else
				float4 staticSwitch134_g3669 = albedo109_g3669;
				#endif
				
				float2 uv_NormalMap71_g3660 = IN.ase_texcoord10.xy;
				float3 lerpResult417_g3660 = lerp( half3(0,0,1) , UnpackScaleNormal( tex2D( _NormalMap, uv_NormalMap71_g3660 ), _NormalStrength ) , saturate( ( coord_mask88_g3660 * 3.0 ) ));
				
				o.Albedo = (staticSwitch134_g3669).xyz;
				o.Normal = lerpResult417_g3660;
				o.Emission = half3( 0, 0, 0 );
				#if defined(_SPECULAR_SETUP)
					o.Specular = fixed3( 0, 0, 0 );
				#else
					o.Metallic = 0;
				#endif
				o.Smoothness = 0.0;
				o.Occlusion = 1;
				o.Alpha = (temp_output_529_0_g3660).a;
				float AlphaClipThreshold = _AlphaThreshold;
				float3 Transmission = 1;
				float3 Translucency = 1;

				#ifdef _ALPHATEST_ON
					clip( o.Alpha - AlphaClipThreshold );
				#endif

				#ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
				#endif

				#ifndef USING_DIRECTIONAL_LIGHT
					fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				#else
					fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				#endif

				fixed4 c = 0;
				float3 worldN;
				worldN.x = dot(IN.tSpace0.xyz, o.Normal);
				worldN.y = dot(IN.tSpace1.xyz, o.Normal);
				worldN.z = dot(IN.tSpace2.xyz, o.Normal);
				worldN = normalize(worldN);
				o.Normal = worldN;

				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
				gi.light.color = _LightColor0.rgb;
				gi.light.dir = lightDir;
				gi.light.color *= atten;

				#if defined(_SPECULAR_SETUP)
					c += LightingStandardSpecular( o, worldViewDir, gi );
				#else
					c += LightingStandard( o, worldViewDir, gi );
				#endif

				#ifdef ASE_TRANSMISSION
				{
					float shadow = _TransmissionShadow;
					#ifdef DIRECTIONAL
						float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
					#else
						float3 lightAtten = gi.light.color;
					#endif
					half3 transmission = max(0 , -dot(o.Normal, gi.light.dir)) * lightAtten * Transmission;
					c.rgb += o.Albedo * transmission;
				}
				#endif

				#ifdef ASE_TRANSLUCENCY
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					#ifdef DIRECTIONAL
						float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
					#else
						float3 lightAtten = gi.light.color;
					#endif
					half3 lightDir = gi.light.dir + o.Normal * normal;
					half transVdotL = pow( saturate( dot( worldViewDir, -lightDir ) ), scattering );
					half3 translucency = lightAtten * (transVdotL * direct + gi.indirect.diffuse * ambient) * Translucency;
					c.rgb += o.Albedo * translucency * strength;
				}
				#endif

				//#ifdef ASE_REFRACTION
				//	float4 projScreenPos = ScreenPos / ScreenPos.w;
				//	float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, WorldNormal ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
				//	projScreenPos.xy += refractionOffset.xy;
				//	float3 refraction = UNITY_SAMPLE_SCREENSPACE_TEXTURE( _GrabTexture, projScreenPos ) * RefractionColor;
				//	color.rgb = lerp( refraction, color.rgb, color.a );
				//	color.a = 1;
				//#endif

				#ifdef ASE_FOG
					UNITY_APPLY_FOG(IN.fogCoord, c);
				#endif
				return c;
			}
			ENDCG
		}

		
		Pass
		{
			
			Name "Deferred"
			Tags { "LightMode"="Deferred" }

			AlphaToMask Off

			CGPROGRAM
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile_instancing
			#pragma multi_compile __ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#pragma multi_compile_prepassfinal
			#ifndef UNITY_PASS_DEFERRED
				#define UNITY_PASS_DEFERRED
			#endif
			#include "HLSLSupport.cginc"
			#if !defined( UNITY_INSTANCED_LOD_FADE )
				#define UNITY_INSTANCED_LOD_FADE
			#endif
			#if !defined( UNITY_INSTANCED_SH )
				#define UNITY_INSTANCED_SH
			#endif
			#if !defined( UNITY_INSTANCED_LIGHTMAPSTS )
				#define UNITY_INSTANCED_LIGHTMAPSTS
			#endif
			#include "UnityShaderVariables.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"

			#include "UnityStandardUtils.cginc"
			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_POSITION
			#define ASE_NEEDS_FRAG_COLOR
			#pragma multi_compile_local __ _DEBUGDISABLEWINDDPO_ON
			#pragma shader_feature_local _WIND_NONE _WIND_SIMPLE _WIND_ADVANCED
			#pragma shader_feature_local _USECRUSH_ON
			#pragma multi_compile_local_fragment __ _DEBUGWIND_ON
			#pragma shader_feature_local _USEAIRSHEENTINT_ON
			#pragma shader_feature_local _USECOLORMAP_ON

			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				#if UNITY_VERSION >= 201810
					UNITY_POSITION(pos);
				#else
					float4 pos : SV_POSITION;
				#endif
				float4 lmap : TEXCOORD2;
				#ifndef LIGHTMAP_ON
					#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
						half3 sh : TEXCOORD3;
					#endif
				#else
					#ifdef DIRLIGHTMAP_OFF
						float4 lmapFadePos : TEXCOORD4;
					#endif
				#endif
				float4 tSpace0 : TEXCOORD5;
				float4 tSpace1 : TEXCOORD6;
				float4 tSpace2 : TEXCOORD7;
				float4 ase_texcoord8 : TEXCOORD8;
				float4 ase_texcoord9 : TEXCOORD9;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#ifdef LIGHTMAP_ON
			float4 unity_LightmapFade;
			#endif
			fixed4 unity_Ambient;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			uniform half _UseTreeBend;
			uniform float3 WindDirection;
			uniform float WindOffsetSpeed;
			uniform float WindTillingSize;
			uniform float2 _SecondWindSmoothstep;
			uniform float2 WindSmoothstep;
			uniform sampler2D WindMap;
			uniform half WindAmplitude;
			uniform half DebugDisableWPO;
			uniform half2 _BezierP1;
			uniform half _BezierAlpha;
			uniform half2 _BezierOffsetP1;
			uniform half _BezierOffsetAlpha;
			uniform half2 _BezierP2;
			uniform half2 _BezierOffsetP2;
			uniform half _SimpleWindyYOffset;
			uniform half _SimpleWindDisplacement;
			uniform sampler2D CrushRenderTexture;
			uniform float2 CrushBufferOffset;
			uniform half CrushBufferSize;
			uniform half _CrushAngle;
			uniform half _CrushFlattenScale;
			uniform half _CrushHeightOffset;
			uniform half CrushDistanceView;
			uniform half CrushDistanceViewFalloff;
			uniform half _TurbulenceSmoothstepMax;
			uniform half _TurbulenceSpeed;
			uniform half _TurbulenceFrequency;
			uniform half _TurbulenceDisplacement;
			uniform float _FlattenVertexNormal;
			uniform half4 _MainBaseColor;
			uniform half4 _VariantBaseColor;
			uniform half _VariantOffset;
			uniform half _VariantContrast;
			uniform sampler2D _BaseMap;
			uniform sampler2D ColorMap;
			uniform float2 ColorMapOffset;
			uniform float2 ColorMapTillingSize;
			uniform half _ColorMapBlendOffset;
			uniform half _ColorMapFadeContrast;
			uniform half _WindBrightness;
			uniform half _CrushBrightness;
			uniform half2 AirSmoothstep;
			uniform sampler2D AirMap;
			uniform sampler2D AirRefractionMap;
			uniform half AirRefractionTillingSize;
			uniform half AirRefractionStrength;
			uniform half AirSpeedMultiplier;
			uniform float WindAngle;
			uniform half2 AirTillingSize;
			uniform half AirStrength;
			uniform int DebugWind;
			uniform int DebugWindTurbulence;
			uniform sampler2D _NormalMap;
			uniform half _NormalStrength;
			uniform half _AlphaThreshold;


			float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
			{
				original -= center;
				float C = cos( angle );
				float S = sin( angle );
				float t = 1 - C;
				float m00 = t * u.x * u.x + C;
				float m01 = t * u.x * u.y - S * u.z;
				float m02 = t * u.x * u.z + S * u.y;
				float m10 = t * u.x * u.y + S * u.z;
				float m11 = t * u.y * u.y + C;
				float m12 = t * u.y * u.z - S * u.x;
				float m20 = t * u.x * u.z - S * u.y;
				float m21 = t * u.y * u.z + S * u.x;
				float m22 = t * u.z * u.z + C;
				float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
				return mul( finalMatrix, original ) + center;
			}
			
			float3 TrigonometricBezierCurve( float3 p1, float3 p2, float t )
			{
				float3 p0 = float3(0, 0, 0);
				float u = 1 - t;
				float t2 = t * t;
				float u2 = u * u;
				float3 result =
					(u2)*p0 +
					(2 * u * t) * p1 +
					t2 * p2;
				return result;
			}
			
			float CheapContrast1_g3661( float In, float Value )
			{
				float A = 0 - Value;
				float B = 1 + Value;
				return clamp(0,1, lerp(A,B,In));
			}
			
			float CheapContrast1_g3663( float In, float Value )
			{
				float A = 0 - Value;
				float B = 1 + Value;
				return clamp(0,1, lerp(A,B,In));
			}
			
			float2 RotateUV67_g3667( float2 UV, float Angle )
			{
				// Rotation Matrix
				                float cosAngle = cos(Angle);
				                float sinAngle = sin(Angle);
				                float2x2 rot = float2x2(cosAngle, -sinAngle, sinAngle, cosAngle);
				 
				                // Rotation
				                return mul(rot, UV);
			}
			
			struct Gradient
			{
				int type;
				int colorsLength;
				int alphasLength;
				float4 colors[8];
				float2 alphas[8];
			};
			
			Gradient NewGradient(int type, int colorsLength, int alphasLength, 
			float4 colors0, float4 colors1, float4 colors2, float4 colors3, float4 colors4, float4 colors5, float4 colors6, float4 colors7,
			float2 alphas0, float2 alphas1, float2 alphas2, float2 alphas3, float2 alphas4, float2 alphas5, float2 alphas6, float2 alphas7)
			{
				Gradient g;
				g.type = type;
				g.colorsLength = colorsLength;
				g.alphasLength = alphasLength;
				g.colors[ 0 ] = colors0;
				g.colors[ 1 ] = colors1;
				g.colors[ 2 ] = colors2;
				g.colors[ 3 ] = colors3;
				g.colors[ 4 ] = colors4;
				g.colors[ 5 ] = colors5;
				g.colors[ 6 ] = colors6;
				g.colors[ 7 ] = colors7;
				g.alphas[ 0 ] = alphas0;
				g.alphas[ 1 ] = alphas1;
				g.alphas[ 2 ] = alphas2;
				g.alphas[ 3 ] = alphas3;
				g.alphas[ 4 ] = alphas4;
				g.alphas[ 5 ] = alphas5;
				g.alphas[ 6 ] = alphas6;
				g.alphas[ 7 ] = alphas7;
				return g;
			}
			
			float4 SampleGradient( Gradient gradient, float time )
			{
				float3 color = gradient.colors[0].rgb;
				UNITY_UNROLL
				for (int c = 1; c < 8; c++)
				{
				float colorPos = saturate((time - gradient.colors[c-1].w) / ( 0.00001 + (gradient.colors[c].w - gradient.colors[c-1].w)) * step(c, (float)gradient.colorsLength-1));
				color = lerp(color, gradient.colors[c].rgb, lerp(colorPos, step(0.01, colorPos), gradient.type));
				}
				#ifndef UNITY_COLORSPACE_GAMMA
				color = half3(GammaToLinearSpaceExact(color.r), GammaToLinearSpaceExact(color.g), GammaToLinearSpaceExact(color.b));
				#endif
				float alpha = gradient.alphas[0].x;
				UNITY_UNROLL
				for (int a = 1; a < 8; a++)
				{
				float alphaPos = saturate((time - gradient.alphas[a-1].y) / ( 0.00001 + (gradient.alphas[a].y - gradient.alphas[a-1].y)) * step(a, (float)gradient.alphasLength-1));
				alpha = lerp(alpha, gradient.alphas[a].x, lerp(alphaPos, step(0.01, alphaPos), gradient.type));
				}
				return float4(color, alpha);
			}
			

			v2f VertexFunction (appdata v  ) {
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 temp_output_331_0_g3680 = (half3(0,0,1)).xz;
				float3 worldToObjDir141_g3687 = normalize( mul( unity_WorldToObject, float4( WindDirection, 0 ) ).xyz );
				float3 wpo_wind_direction306_g3679 = worldToObjDir141_g3687;
				float3 temp_output_295_0_g3680 = wpo_wind_direction306_g3679;
				float dotResult330_g3680 = dot( temp_output_331_0_g3680 , (temp_output_295_0_g3680).xz );
				float3 break444_g3680 = temp_output_295_0_g3680;
				float2 appendResult355_g3680 = (float2(break444_g3680.z , break444_g3680.x));
				float dotResult356_g3680 = dot( temp_output_331_0_g3680 , appendResult355_g3680 );
				float3 objToWorld183_g3687 = mul( unity_ObjectToWorld, float4( v.vertex.xyz, 1 ) ).xyz;
				float3 break153_g3687 = -objToWorld183_g3687;
				float2 appendResult155_g3687 = (float2(break153_g3687.x , break153_g3687.z));
				float2 _wind_UVs106_g3687 = appendResult155_g3687;
				float mulTime137_g3687 = _Time.y * ( WindOffsetSpeed / 10.0 );
				float3 break187_g3687 = WindDirection;
				float2 appendResult188_g3687 = (float2(break187_g3687.x , break187_g3687.z));
				float2 _wind_direction110_g3687 = appendResult188_g3687;
				float4 tex2DNode144_g3687 = tex2Dlod( WindMap, float4( ( ( _wind_UVs106_g3687 / WindTillingSize ) + ( mulTime137_g3687 * _wind_direction110_g3687 ) ), 0, 0.0) );
				float smoothstepResult53_g3687 = smoothstep( WindSmoothstep.x , WindSmoothstep.y , tex2DNode144_g3687.r);
				float smoothstepResult170_g3687 = smoothstep( _SecondWindSmoothstep.x , _SecondWindSmoothstep.y , smoothstepResult53_g3687);
				float _wind_amplitude116_g3687 = WindAmplitude;
				float temp_output_2490_0 = ( smoothstepResult170_g3687 * _wind_amplitude116_g3687 );
				float wpo_wind_rawMask497_g3679 = temp_output_2490_0;
				float debug_disableWPO486_g3679 = DebugDisableWPO;
				#ifdef _DEBUGDISABLEWINDDPO_ON
				float staticSwitch479_g3679 = ( debug_disableWPO486_g3679 == 1.0 ? 0.0 : wpo_wind_rawMask497_g3679 );
				#else
				float staticSwitch479_g3679 = wpo_wind_rawMask497_g3679;
				#endif
				float wpo_wind_mask302_g3679 = staticSwitch479_g3679;
				float wind_mask423_g3680 = wpo_wind_mask302_g3679;
				float lerpResult192_g3680 = lerp( 0.0 , ( acos( dotResult330_g3680 ) * sign( dotResult356_g3680 ) ) , wind_mask423_g3680);
				float3 appendResult465_g3680 = (float3(0.0 , _BezierP1.y , _BezierP1.x));
				float3 temp_output_453_0_g3680 = ( appendResult465_g3680 * _BezierAlpha );
				float3 appendResult419_g3680 = (float3(0.0 , _BezierOffsetP1.y , _BezierOffsetP1.x));
				float3 rotatedValue187_g3680 = RotateAroundAxis( float3( 0,0,0 ), ( temp_output_453_0_g3680 + ( appendResult419_g3680 * wind_mask423_g3680 * _BezierOffsetAlpha ) ), float3( 0,1,0 ), lerpResult192_g3680 );
				float3 temp_output_15_0_g3681 = rotatedValue187_g3680;
				float3 p121_g3681 = temp_output_15_0_g3681;
				float3 appendResult463_g3680 = (float3(0.0 , _BezierP2.y , _BezierP2.x));
				float3 temp_output_454_0_g3680 = ( appendResult463_g3680 * _BezierAlpha );
				float3 appendResult420_g3680 = (float3(0.0 , _BezierOffsetP2.y , _BezierOffsetP2.x));
				float3 rotatedValue195_g3680 = RotateAroundAxis( float3( 0,0,0 ), ( temp_output_454_0_g3680 + ( appendResult420_g3680 * wind_mask423_g3680 * _BezierOffsetAlpha ) ), float3( 0,1,0 ), lerpResult192_g3680 );
				float3 temp_output_14_0_g3681 = rotatedValue195_g3680;
				float3 p221_g3681 = temp_output_14_0_g3681;
				float wpo_CoordMask184_g3679 = v.ase_color.r;
				float temp_output_6_0_g3681 = wpo_CoordMask184_g3679;
				float t21_g3681 = temp_output_6_0_g3681;
				float3 localTrigonometricBezierCurve21_g3681 = TrigonometricBezierCurve( p121_g3681 , p221_g3681 , t21_g3681 );
				float3 temp_output_500_0_g3679 = localTrigonometricBezierCurve21_g3681;
				half3 _RelativeUp = half3(0,1,0);
				float3 temp_output_26_0_g3682 = wpo_wind_direction306_g3679;
				float dotResult7_g3682 = dot( temp_output_26_0_g3682 , _RelativeUp );
				float lerpResult10_g3682 = lerp( -1.570796 , 1.570796 , ( ( dotResult7_g3682 * 0.5 ) + 0.5 ));
				float3 rotatedValue17_g3682 = RotateAroundAxis( float3( 0,0,0 ), temp_output_26_0_g3682, normalize( cross( _RelativeUp , temp_output_26_0_g3682 ) ), lerpResult10_g3682 );
				float temp_output_25_0_g3682 = wpo_wind_mask302_g3679;
				float lerpResult21_g3682 = lerp( 0.0 , _SimpleWindyYOffset , temp_output_25_0_g3682);
				float3 appendResult23_g3682 = (float3(0.0 , lerpResult21_g3682 , 0.0));
				float3 temp_output_499_0_g3679 = ( wpo_CoordMask184_g3679 * ( ( rotatedValue17_g3682 + appendResult23_g3682 ) * _SimpleWindDisplacement * temp_output_25_0_g3682 ) );
				#if defined(_WIND_NONE)
				float3 staticSwitch166_g3679 = float3( 0,0,0 );
				#elif defined(_WIND_SIMPLE)
				float3 staticSwitch166_g3679 = temp_output_499_0_g3679;
				#elif defined(_WIND_ADVANCED)
				float3 staticSwitch166_g3679 = temp_output_500_0_g3679;
				#else
				float3 staticSwitch166_g3679 = temp_output_500_0_g3679;
				#endif
				float3 out_wpo_windy423_g3679 = staticSwitch166_g3679;
				float3 temp_output_159_0_g3686 = out_wpo_windy423_g3679;
				float4 transform584_g3679 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float4 tex2DNode29_g3686 = tex2Dlod( CrushRenderTexture, float4( ( ( ( (transform584_g3679).xz + -CrushBufferOffset ) + ( CrushBufferSize / 2.0 ) ) / CrushBufferSize ), 0, 0.0) );
				float2 temp_output_96_0_g3686 = ( ( (tex2DNode29_g3686).rg - float2( 0.5,0.5 ) ) * float2( 2,2 ) );
				float2 break98_g3686 = temp_output_96_0_g3686;
				float3 appendResult102_g3686 = (float3(break98_g3686.x , 0.0 , break98_g3686.y));
				float3 worldToObjDir101_g3686 = mul( unity_WorldToObject, float4( appendResult102_g3686, 0 ) ).xyz;
				float3 crush_direction172_g3686 = worldToObjDir101_g3686;
				float vectorField_length134_g3686 = length( temp_output_96_0_g3686 );
				float3 temp_output_126_0_g3686 = float3( 0,0,0 );
				float3 ase_worldPos = mul(unity_ObjectToWorld, float4( (v.vertex).xyz, 1 )).xyz;
				float3 worldToObj14_g3686 = mul( unity_WorldToObject, float4( ase_worldPos, 1 ) ).xyz;
				float3 rotatedValue16_g3686 = RotateAroundAxis( temp_output_126_0_g3686, worldToObj14_g3686, crush_direction172_g3686, ( radians( _CrushAngle ) * vectorField_length134_g3686 ) );
				float3 appendResult195_g3686 = (float3(1.0 , ( 1.0 - _CrushFlattenScale ) , 1.0));
				float3 appendResult66_g3686 = (float3(0.0 , _CrushHeightOffset , 0.0));
				float crush_coordMasd87_g3686 = wpo_CoordMask184_g3679;
				float3 ase_parentObjectScale = ( 1.0 / float3( length( unity_WorldToObject[ 0 ].xyz ), length( unity_WorldToObject[ 1 ].xyz ), length( unity_WorldToObject[ 2 ].xyz ) ) );
				float RT_b236_g3686 = tex2DNode29_g3686.b;
				float4 transform223_g3686 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float temp_output_235_0_g3686 = ( RT_b236_g3686 == 0.0 ? ( ( vectorField_length134_g3686 * saturate( ( crush_coordMasd87_g3686 * 8.0 ) ) ) * saturate( ( ( CrushDistanceView - distance( float4( _WorldSpaceCameraPos , 0.0 ) , transform223_g3686 ) ) / CrushDistanceViewFalloff ) ) ) : 0.0 );
				float3 lerpResult160_g3686 = lerp( temp_output_159_0_g3686 , ( ( ( rotatedValue16_g3686 - worldToObj14_g3686 ) * appendResult195_g3686 ) + ( appendResult66_g3686 * crush_coordMasd87_g3686 * ase_parentObjectScale.y ) ) , temp_output_235_0_g3686);
				#ifdef _USECRUSH_ON
				float3 staticSwitch162_g3686 = lerpResult160_g3686;
				#else
				float3 staticSwitch162_g3686 = temp_output_159_0_g3686;
				#endif
				float3 out_wpo_crush432_g3679 = staticSwitch162_g3686;
				float smoothstepResult112_g3683 = smoothstep( 0.0 , _TurbulenceSmoothstepMax , wpo_wind_rawMask497_g3679);
				float temp_output_153_0_g3683 = saturate( smoothstepResult112_g3683 );
				float4 transform119_g3683 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float mulTime95_g3683 = _Time.y * _TurbulenceSpeed;
				float3 ase_objectScale = float3( length( unity_ObjectToWorld[ 0 ].xyz ), length( unity_ObjectToWorld[ 1 ].xyz ), length( unity_ObjectToWorld[ 2 ].xyz ) );
				float temp_output_99_0_g3683 = ( cos( ( ( ( ( ( transform119_g3683.x * 100.0 ) + ( transform119_g3683.z * 33.0 ) ) - mulTime95_g3683 ) + v.vertex.xyz.y ) / _TurbulenceFrequency ) ) * _TurbulenceDisplacement * ase_objectScale.y * v.ase_texcoord.y );
				float3 temp_output_88_0_g3683 = wpo_wind_direction306_g3679;
				float3 temp_output_544_0_g3679 = ( out_wpo_crush432_g3679 + ( temp_output_153_0_g3683 * temp_output_99_0_g3683 * temp_output_88_0_g3683 ) );
				#if defined(_WIND_NONE)
				float3 staticSwitch438_g3679 = float3( 0,0,0 );
				#elif defined(_WIND_SIMPLE)
				float3 staticSwitch438_g3679 = temp_output_544_0_g3679;
				#elif defined(_WIND_ADVANCED)
				float3 staticSwitch438_g3679 = temp_output_544_0_g3679;
				#else
				float3 staticSwitch438_g3679 = temp_output_544_0_g3679;
				#endif
				float3 wpo_out_turbulence508_g3679 = staticSwitch438_g3679;
				#ifdef _DEBUGDISABLEWINDDPO_ON
				float3 staticSwitch466_g3679 = ( debug_disableWPO486_g3679 == 1.0 ? out_wpo_crush432_g3679 : wpo_out_turbulence508_g3679 );
				#else
				float3 staticSwitch466_g3679 = wpo_out_turbulence508_g3679;
				#endif
				
				float3 lerpResult3_g2806 = lerp( v.normal , float3(0,1,0) , _FlattenVertexNormal);
				
				o.ase_texcoord8 = v.vertex;
				o.ase_texcoord9.xy = v.ase_texcoord.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord9.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = staticSwitch466_g3679;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.vertex.w = 1;
				v.normal = lerpResult3_g2806;
				v.tangent = v.tangent;

				o.pos = UnityObjectToClipPos(v.vertex);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
				o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				#ifdef DYNAMICLIGHTMAP_ON
					o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#else
					o.lmap.zw = 0;
				#endif
				#ifdef LIGHTMAP_ON
					o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
					#ifdef DIRLIGHTMAP_OFF
						o.lmapFadePos.xyz = (mul(unity_ObjectToWorld, v.vertex).xyz - unity_ShadowFadeCenterAndType.xyz) * unity_ShadowFadeCenterAndType.w;
						o.lmapFadePos.w = (-UnityObjectToViewPos(v.vertex).z) * (1.0 - unity_ShadowFadeCenterAndType.w);
					#endif
				#else
					o.lmap.xy = 0;
					#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
						o.sh = 0;
						o.sh = ShadeSHPerVertex (worldNormal, o.sh);
					#endif
				#endif
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			v2f vert ( appdata v )
			{
				return VertexFunction( v );
			}
			#endif

			void frag (v2f IN 
				, out half4 outGBuffer0 : SV_Target0
				, out half4 outGBuffer1 : SV_Target1
				, out half4 outGBuffer2 : SV_Target2
				, out half4 outEmission : SV_Target3
				#if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
				, out half4 outShadowMask : SV_Target4
				#endif
				#ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
				#endif
			)
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				#ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
				#endif

				#if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
				#else
					SurfaceOutputStandard o = (SurfaceOutputStandard)0;
				#endif
				float3 WorldTangent = float3(IN.tSpace0.x,IN.tSpace1.x,IN.tSpace2.x);
				float3 WorldBiTangent = float3(IN.tSpace0.y,IN.tSpace1.y,IN.tSpace2.y);
				float3 WorldNormal = float3(IN.tSpace0.z,IN.tSpace1.z,IN.tSpace2.z);
				float3 worldPos = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				half atten = 1;

				float3 temp_cast_0 = (IN.ase_texcoord8.xyz.y).xxx;
				float3 objToWorld541_g3660 = mul( unity_ObjectToWorld, float4( temp_cast_0, 1 ) ).xyz;
				float In1_g3661 = ( objToWorld541_g3660.y + _VariantOffset );
				float Value1_g3661 = _VariantContrast;
				float localCheapContrast1_g3661 = CheapContrast1_g3661( In1_g3661 , Value1_g3661 );
				float4 lerpResult350_g3660 = lerp( _MainBaseColor , _VariantBaseColor , saturate( localCheapContrast1_g3661 ));
				float4 appendResult442_g3660 = (float4((lerpResult350_g3660).rgb , 1.0));
				float2 uv_BaseMap53_g3660 = IN.ase_texcoord9.xy;
				float4 tex2DNode53_g3660 = tex2D( _BaseMap, uv_BaseMap53_g3660 );
				float4 _baseMap50_g3660 = tex2DNode53_g3660;
				float4 temp_output_428_0_g3660 = ( appendResult442_g3660 * _baseMap50_g3660 );
				float4 temp_output_124_0_g3662 = temp_output_428_0_g3660;
				float3 temp_output_125_0_g3662 = (temp_output_124_0_g3662).rgb;
				float _colormap_baseMap_Alpha146_g3662 = (temp_output_124_0_g3662).a;
				float4 appendResult132_g3662 = (float4(temp_output_125_0_g3662 , _colormap_baseMap_Alpha146_g3662));
				float coord_mask88_g3660 = IN.ase_color.r;
				float In1_g3663 = ( coord_mask88_g3660 - _ColorMapBlendOffset );
				float Value1_g3663 = _ColorMapFadeContrast;
				float localCheapContrast1_g3663 = CheapContrast1_g3663( In1_g3663 , Value1_g3663 );
				float3 lerpResult97_g3662 = lerp( (tex2D( ColorMap, ( ( (worldPos).xz + ColorMapOffset ) / ColorMapTillingSize ) )).rgb , temp_output_125_0_g3662 , saturate( ( (lerpResult350_g3660).a * localCheapContrast1_g3663 ) ));
				float3 break65_g3662 = lerpResult97_g3662;
				float4 appendResult64_g3662 = (float4(break65_g3662.x , break65_g3662.y , break65_g3662.z , _colormap_baseMap_Alpha146_g3662));
				#ifdef _USECOLORMAP_ON
				float4 staticSwitch128_g3662 = appendResult64_g3662;
				#else
				float4 staticSwitch128_g3662 = appendResult132_g3662;
				#endif
				float4 temp_output_23_0_g3665 = staticSwitch128_g3662;
				float3 objToWorld183_g3687 = mul( unity_ObjectToWorld, float4( IN.ase_texcoord8.xyz, 1 ) ).xyz;
				float3 break153_g3687 = -objToWorld183_g3687;
				float2 appendResult155_g3687 = (float2(break153_g3687.x , break153_g3687.z));
				float2 _wind_UVs106_g3687 = appendResult155_g3687;
				float mulTime137_g3687 = _Time.y * ( WindOffsetSpeed / 10.0 );
				float3 break187_g3687 = WindDirection;
				float2 appendResult188_g3687 = (float2(break187_g3687.x , break187_g3687.z));
				float2 _wind_direction110_g3687 = appendResult188_g3687;
				float4 tex2DNode144_g3687 = tex2D( WindMap, ( ( _wind_UVs106_g3687 / WindTillingSize ) + ( mulTime137_g3687 * _wind_direction110_g3687 ) ) );
				float smoothstepResult53_g3687 = smoothstep( WindSmoothstep.x , WindSmoothstep.y , tex2DNode144_g3687.r);
				float smoothstepResult170_g3687 = smoothstep( _SecondWindSmoothstep.x , _SecondWindSmoothstep.y , smoothstepResult53_g3687);
				float _wind_amplitude116_g3687 = WindAmplitude;
				float temp_output_2490_0 = ( smoothstepResult170_g3687 * _wind_amplitude116_g3687 );
				float windMask397_g3660 = temp_output_2490_0;
				float lerpResult71_g3665 = lerp( 1.0 , _WindBrightness , windMask397_g3660);
				float4 transform584_g3679 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float4 tex2DNode29_g3686 = tex2D( CrushRenderTexture, ( ( ( (transform584_g3679).xz + -CrushBufferOffset ) + ( CrushBufferSize / 2.0 ) ) / CrushBufferSize ) );
				float RT_b236_g3686 = tex2DNode29_g3686.b;
				float2 temp_output_96_0_g3686 = ( ( (tex2DNode29_g3686).rg - float2( 0.5,0.5 ) ) * float2( 2,2 ) );
				float vectorField_length134_g3686 = length( temp_output_96_0_g3686 );
				float wpo_CoordMask184_g3679 = IN.ase_color.r;
				float crush_coordMasd87_g3686 = wpo_CoordMask184_g3679;
				float4 transform223_g3686 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float temp_output_235_0_g3686 = ( RT_b236_g3686 == 0.0 ? ( ( vectorField_length134_g3686 * saturate( ( crush_coordMasd87_g3686 * 8.0 ) ) ) * saturate( ( ( CrushDistanceView - distance( float4( _WorldSpaceCameraPos , 0.0 ) , transform223_g3686 ) ) / CrushDistanceViewFalloff ) ) ) : 0.0 );
				#ifdef _USECRUSH_ON
				float staticSwitch163_g3686 = temp_output_235_0_g3686;
				#else
				float staticSwitch163_g3686 = 0.0;
				#endif
				float lerpResult78_g3665 = lerp( lerpResult71_g3665 , _CrushBrightness , staticSwitch163_g3686);
				float lerpResult83_g3665 = lerp( 1.0 , lerpResult78_g3665 , saturate( ( coord_mask88_g3660 * 2.0 ) ));
				float4 appendResult29_g3665 = (float4((saturate( ( temp_output_23_0_g3665 * lerpResult83_g3665 ) )).rgb , (temp_output_23_0_g3665).a));
				float4 temp_output_529_0_g3660 = appendResult29_g3665;
				float4 temp_output_72_0_g3667 = temp_output_529_0_g3660;
				float2 temp_output_5_0_g3667 = (worldPos).xz;
				float mulTime8_g3667 = _Time.y * -( WindOffsetSpeed * AirSpeedMultiplier );
				float2 UV67_g3667 = ( temp_output_5_0_g3667 + ( mulTime8_g3667 * (WindDirection).xz ) );
				float windAngle482_g3660 = WindAngle;
				float Angle67_g3667 = windAngle482_g3660;
				float2 localRotateUV67_g3667 = RotateUV67_g3667( UV67_g3667 , Angle67_g3667 );
				float smoothstepResult23_g3667 = smoothstep( AirSmoothstep.x , AirSmoothstep.y , tex2D( AirMap, ( (UnpackScaleNormal( tex2D( AirRefractionMap, ( temp_output_5_0_g3667 / AirRefractionTillingSize ) ), AirRefractionStrength )).xy + ( localRotateUV67_g3667 / AirTillingSize ) ) ).r);
				#ifdef _USEAIRSHEENTINT_ON
				float4 staticSwitch73_g3667 = saturate( ( temp_output_72_0_g3667 + ( smoothstepResult23_g3667 * AirStrength * saturate( ( IN.ase_color.r * 4.0 ) ) * windMask397_g3660 ) ) );
				#else
				float4 staticSwitch73_g3667 = temp_output_72_0_g3667;
				#endif
				float4 albedo109_g3669 = staticSwitch73_g3667;
				int isDebugWind98_g3669 = ( DebugWind + DebugWindTurbulence );
				int debugWindTurbulence103_g3669 = DebugWindTurbulence;
				int debugWind105_g3669 = DebugWind;
				half4 color126_g3669 = IsGammaSpace() ? half4(0,0,0,0) : half4(0,0,0,0);
				Gradient gradient82_g3669 = NewGradient( 0, 7, 2, float4( 0.5, 0.5, 0.5, 0 ), float4( 0, 0.716, 0, 0.06471352 ), float4( 1, 1, 0, 0.2205844 ), float4( 1, 0.5698085, 0, 0.5470665 ), float4( 1, 0.3047979, 0, 0.7499962 ), float4( 1, 0, 0, 0.9411765 ), float4( 0.5626073, 0, 1, 1 ), 0, float2( 1, 0 ), float2( 1, 1 ), 0, 0, 0, 0, 0, 0 );
				float4 temp_output_106_0_g3669 = ( (float)debugWind105_g3669 == 1.0 ? SampleGradient( gradient82_g3669, windMask397_g3660 ) : albedo109_g3669 );
				float4 ifLocalVar131_g3669 = 0;
				if( debugWindTurbulence103_g3669 <= debugWind105_g3669 )
				ifLocalVar131_g3669 = temp_output_106_0_g3669;
				else
				ifLocalVar131_g3669 = color126_g3669;
				half4 color64_g3669 = IsGammaSpace() ? half4(1,1,1,0) : half4(1,1,1,0);
				float4 transform119_g3683 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float mulTime95_g3683 = _Time.y * _TurbulenceSpeed;
				float3 ase_objectScale = float3( length( unity_ObjectToWorld[ 0 ].xyz ), length( unity_ObjectToWorld[ 1 ].xyz ), length( unity_ObjectToWorld[ 2 ].xyz ) );
				float temp_output_99_0_g3683 = ( cos( ( ( ( ( ( transform119_g3683.x * 100.0 ) + ( transform119_g3683.z * 33.0 ) ) - mulTime95_g3683 ) + IN.ase_texcoord8.xyz.y ) / _TurbulenceFrequency ) ) * _TurbulenceDisplacement * ase_objectScale.y * IN.ase_texcoord9.xy.y );
				float wpo_wind_rawMask497_g3679 = temp_output_2490_0;
				float smoothstepResult112_g3683 = smoothstep( 0.0 , _TurbulenceSmoothstepMax , wpo_wind_rawMask497_g3679);
				float temp_output_153_0_g3683 = saturate( smoothstepResult112_g3683 );
				float temp_output_544_85_g3679 = ( temp_output_99_0_g3683 * temp_output_153_0_g3683 );
				#if defined(_WIND_NONE)
				float staticSwitch441_g3679 = 0.0;
				#elif defined(_WIND_SIMPLE)
				float staticSwitch441_g3679 = temp_output_544_85_g3679;
				#elif defined(_WIND_ADVANCED)
				float staticSwitch441_g3679 = temp_output_544_85_g3679;
				#else
				float staticSwitch441_g3679 = temp_output_544_85_g3679;
				#endif
				float4 lerpResult62_g3669 = lerp( ifLocalVar131_g3669 , color64_g3669 , ( (float)debugWindTurbulence103_g3669 == 1.0 ? saturate( ( staticSwitch441_g3679 * 20.0 ) ) : 0.0 ));
				#ifdef _DEBUGWIND_ON
				float4 staticSwitch134_g3669 = ( (float)isDebugWind98_g3669 >= 1.0 ? lerpResult62_g3669 : albedo109_g3669 );
				#else
				float4 staticSwitch134_g3669 = albedo109_g3669;
				#endif
				
				float2 uv_NormalMap71_g3660 = IN.ase_texcoord9.xy;
				float3 lerpResult417_g3660 = lerp( half3(0,0,1) , UnpackScaleNormal( tex2D( _NormalMap, uv_NormalMap71_g3660 ), _NormalStrength ) , saturate( ( coord_mask88_g3660 * 3.0 ) ));
				
				o.Albedo = (staticSwitch134_g3669).xyz;
				o.Normal = lerpResult417_g3660;
				o.Emission = half3( 0, 0, 0 );
				#if defined(_SPECULAR_SETUP)
					o.Specular = fixed3( 0, 0, 0 );
				#else
					o.Metallic = 0;
				#endif
				o.Smoothness = 0.0;
				o.Occlusion = 1;
				o.Alpha = (temp_output_529_0_g3660).a;
				float AlphaClipThreshold = _AlphaThreshold;
				float3 BakedGI = 0;

				#ifdef _ALPHATEST_ON
					clip( o.Alpha - AlphaClipThreshold );
				#endif

				#ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
				#endif

				#ifndef USING_DIRECTIONAL_LIGHT
					fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				#else
					fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				#endif

				float3 worldN;
				worldN.x = dot(IN.tSpace0.xyz, o.Normal);
				worldN.y = dot(IN.tSpace1.xyz, o.Normal);
				worldN.z = dot(IN.tSpace2.xyz, o.Normal);
				worldN = normalize(worldN);
				o.Normal = worldN;

				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
				gi.light.color = 0;
				gi.light.dir = half3(0,1,0);

				UnityGIInput giInput;
				UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
				giInput.light = gi.light;
				giInput.worldPos = worldPos;
				giInput.worldViewDir = worldViewDir;
				giInput.atten = atten;
				#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
					giInput.lightmapUV = IN.lmap;
				#else
					giInput.lightmapUV = 0.0;
				#endif
				#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
					giInput.ambient = IN.sh;
				#else
					giInput.ambient.rgb = 0.0;
				#endif
				giInput.probeHDR[0] = unity_SpecCube0_HDR;
				giInput.probeHDR[1] = unity_SpecCube1_HDR;
				#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
					giInput.boxMin[0] = unity_SpecCube0_BoxMin;
				#endif
				#ifdef UNITY_SPECCUBE_BOX_PROJECTION
					giInput.boxMax[0] = unity_SpecCube0_BoxMax;
					giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
					giInput.boxMax[1] = unity_SpecCube1_BoxMax;
					giInput.boxMin[1] = unity_SpecCube1_BoxMin;
					giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
				#endif

				#if defined(_SPECULAR_SETUP)
					LightingStandardSpecular_GI( o, giInput, gi );
				#else
					LightingStandard_GI( o, giInput, gi );
				#endif

				#ifdef ASE_BAKEDGI
					gi.indirect.diffuse = BakedGI;
				#endif

				#if UNITY_SHOULD_SAMPLE_SH && !defined(LIGHTMAP_ON) && defined(ASE_NO_AMBIENT)
					gi.indirect.diffuse = 0;
				#endif

				#if defined(_SPECULAR_SETUP)
					outEmission = LightingStandardSpecular_Deferred( o, worldViewDir, gi, outGBuffer0, outGBuffer1, outGBuffer2 );
				#else
					outEmission = LightingStandard_Deferred( o, worldViewDir, gi, outGBuffer0, outGBuffer1, outGBuffer2 );
				#endif

				#if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
					outShadowMask = UnityGetRawBakedOcclusions (IN.lmap.xy, float3(0, 0, 0));
				#endif
				#ifndef UNITY_HDR_ON
					outEmission.rgb = exp2(-outEmission.rgb);
				#endif
			}
			ENDCG
		}

		
		Pass
		{
			
			Name "Meta"
			Tags { "LightMode"="Meta" }
			Cull Off

			CGPROGRAM
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile_instancing
			#pragma multi_compile __ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1

			#pragma vertex vert
			#pragma fragment frag
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#pragma shader_feature EDITOR_VISUALIZATION
			#ifndef UNITY_PASS_META
				#define UNITY_PASS_META
			#endif
			#include "HLSLSupport.cginc"
			#if !defined( UNITY_INSTANCED_LOD_FADE )
				#define UNITY_INSTANCED_LOD_FADE
			#endif
			#if !defined( UNITY_INSTANCED_SH )
				#define UNITY_INSTANCED_SH
			#endif
			#if !defined( UNITY_INSTANCED_LIGHTMAPSTS )
				#define UNITY_INSTANCED_LIGHTMAPSTS
			#endif
			#include "UnityShaderVariables.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "UnityMetaPass.cginc"

			#include "UnityStandardUtils.cginc"
			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_POSITION
			#define ASE_NEEDS_FRAG_COLOR
			#pragma multi_compile_local __ _DEBUGDISABLEWINDDPO_ON
			#pragma shader_feature_local _WIND_NONE _WIND_SIMPLE _WIND_ADVANCED
			#pragma shader_feature_local _USECRUSH_ON
			#pragma multi_compile_local_fragment __ _DEBUGWIND_ON
			#pragma shader_feature_local _USEAIRSHEENTINT_ON
			#pragma shader_feature_local _USECOLORMAP_ON

			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			struct v2f {
				#if UNITY_VERSION >= 201810
					UNITY_POSITION(pos);
				#else
					float4 pos : SV_POSITION;
				#endif
				#ifdef EDITOR_VISUALIZATION
					float2 vizUV : TEXCOORD1;
					float4 lightCoord : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			uniform half _UseTreeBend;
			uniform float3 WindDirection;
			uniform float WindOffsetSpeed;
			uniform float WindTillingSize;
			uniform float2 _SecondWindSmoothstep;
			uniform float2 WindSmoothstep;
			uniform sampler2D WindMap;
			uniform half WindAmplitude;
			uniform half DebugDisableWPO;
			uniform half2 _BezierP1;
			uniform half _BezierAlpha;
			uniform half2 _BezierOffsetP1;
			uniform half _BezierOffsetAlpha;
			uniform half2 _BezierP2;
			uniform half2 _BezierOffsetP2;
			uniform half _SimpleWindyYOffset;
			uniform half _SimpleWindDisplacement;
			uniform sampler2D CrushRenderTexture;
			uniform float2 CrushBufferOffset;
			uniform half CrushBufferSize;
			uniform half _CrushAngle;
			uniform half _CrushFlattenScale;
			uniform half _CrushHeightOffset;
			uniform half CrushDistanceView;
			uniform half CrushDistanceViewFalloff;
			uniform half _TurbulenceSmoothstepMax;
			uniform half _TurbulenceSpeed;
			uniform half _TurbulenceFrequency;
			uniform half _TurbulenceDisplacement;
			uniform float _FlattenVertexNormal;
			uniform half4 _MainBaseColor;
			uniform half4 _VariantBaseColor;
			uniform half _VariantOffset;
			uniform half _VariantContrast;
			uniform sampler2D _BaseMap;
			uniform sampler2D ColorMap;
			uniform float2 ColorMapOffset;
			uniform float2 ColorMapTillingSize;
			uniform half _ColorMapBlendOffset;
			uniform half _ColorMapFadeContrast;
			uniform half _WindBrightness;
			uniform half _CrushBrightness;
			uniform half2 AirSmoothstep;
			uniform sampler2D AirMap;
			uniform sampler2D AirRefractionMap;
			uniform half AirRefractionTillingSize;
			uniform half AirRefractionStrength;
			uniform half AirSpeedMultiplier;
			uniform float WindAngle;
			uniform half2 AirTillingSize;
			uniform half AirStrength;
			uniform int DebugWind;
			uniform int DebugWindTurbulence;
			uniform half _AlphaThreshold;


			float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
			{
				original -= center;
				float C = cos( angle );
				float S = sin( angle );
				float t = 1 - C;
				float m00 = t * u.x * u.x + C;
				float m01 = t * u.x * u.y - S * u.z;
				float m02 = t * u.x * u.z + S * u.y;
				float m10 = t * u.x * u.y + S * u.z;
				float m11 = t * u.y * u.y + C;
				float m12 = t * u.y * u.z - S * u.x;
				float m20 = t * u.x * u.z - S * u.y;
				float m21 = t * u.y * u.z + S * u.x;
				float m22 = t * u.z * u.z + C;
				float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
				return mul( finalMatrix, original ) + center;
			}
			
			float3 TrigonometricBezierCurve( float3 p1, float3 p2, float t )
			{
				float3 p0 = float3(0, 0, 0);
				float u = 1 - t;
				float t2 = t * t;
				float u2 = u * u;
				float3 result =
					(u2)*p0 +
					(2 * u * t) * p1 +
					t2 * p2;
				return result;
			}
			
			float CheapContrast1_g3661( float In, float Value )
			{
				float A = 0 - Value;
				float B = 1 + Value;
				return clamp(0,1, lerp(A,B,In));
			}
			
			float CheapContrast1_g3663( float In, float Value )
			{
				float A = 0 - Value;
				float B = 1 + Value;
				return clamp(0,1, lerp(A,B,In));
			}
			
			float2 RotateUV67_g3667( float2 UV, float Angle )
			{
				// Rotation Matrix
				                float cosAngle = cos(Angle);
				                float sinAngle = sin(Angle);
				                float2x2 rot = float2x2(cosAngle, -sinAngle, sinAngle, cosAngle);
				 
				                // Rotation
				                return mul(rot, UV);
			}
			
			struct Gradient
			{
				int type;
				int colorsLength;
				int alphasLength;
				float4 colors[8];
				float2 alphas[8];
			};
			
			Gradient NewGradient(int type, int colorsLength, int alphasLength, 
			float4 colors0, float4 colors1, float4 colors2, float4 colors3, float4 colors4, float4 colors5, float4 colors6, float4 colors7,
			float2 alphas0, float2 alphas1, float2 alphas2, float2 alphas3, float2 alphas4, float2 alphas5, float2 alphas6, float2 alphas7)
			{
				Gradient g;
				g.type = type;
				g.colorsLength = colorsLength;
				g.alphasLength = alphasLength;
				g.colors[ 0 ] = colors0;
				g.colors[ 1 ] = colors1;
				g.colors[ 2 ] = colors2;
				g.colors[ 3 ] = colors3;
				g.colors[ 4 ] = colors4;
				g.colors[ 5 ] = colors5;
				g.colors[ 6 ] = colors6;
				g.colors[ 7 ] = colors7;
				g.alphas[ 0 ] = alphas0;
				g.alphas[ 1 ] = alphas1;
				g.alphas[ 2 ] = alphas2;
				g.alphas[ 3 ] = alphas3;
				g.alphas[ 4 ] = alphas4;
				g.alphas[ 5 ] = alphas5;
				g.alphas[ 6 ] = alphas6;
				g.alphas[ 7 ] = alphas7;
				return g;
			}
			
			float4 SampleGradient( Gradient gradient, float time )
			{
				float3 color = gradient.colors[0].rgb;
				UNITY_UNROLL
				for (int c = 1; c < 8; c++)
				{
				float colorPos = saturate((time - gradient.colors[c-1].w) / ( 0.00001 + (gradient.colors[c].w - gradient.colors[c-1].w)) * step(c, (float)gradient.colorsLength-1));
				color = lerp(color, gradient.colors[c].rgb, lerp(colorPos, step(0.01, colorPos), gradient.type));
				}
				#ifndef UNITY_COLORSPACE_GAMMA
				color = half3(GammaToLinearSpaceExact(color.r), GammaToLinearSpaceExact(color.g), GammaToLinearSpaceExact(color.b));
				#endif
				float alpha = gradient.alphas[0].x;
				UNITY_UNROLL
				for (int a = 1; a < 8; a++)
				{
				float alphaPos = saturate((time - gradient.alphas[a-1].y) / ( 0.00001 + (gradient.alphas[a].y - gradient.alphas[a-1].y)) * step(a, (float)gradient.alphasLength-1));
				alpha = lerp(alpha, gradient.alphas[a].x, lerp(alphaPos, step(0.01, alphaPos), gradient.type));
				}
				return float4(color, alpha);
			}
			

			v2f VertexFunction (appdata v  ) {
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 temp_output_331_0_g3680 = (half3(0,0,1)).xz;
				float3 worldToObjDir141_g3687 = normalize( mul( unity_WorldToObject, float4( WindDirection, 0 ) ).xyz );
				float3 wpo_wind_direction306_g3679 = worldToObjDir141_g3687;
				float3 temp_output_295_0_g3680 = wpo_wind_direction306_g3679;
				float dotResult330_g3680 = dot( temp_output_331_0_g3680 , (temp_output_295_0_g3680).xz );
				float3 break444_g3680 = temp_output_295_0_g3680;
				float2 appendResult355_g3680 = (float2(break444_g3680.z , break444_g3680.x));
				float dotResult356_g3680 = dot( temp_output_331_0_g3680 , appendResult355_g3680 );
				float3 objToWorld183_g3687 = mul( unity_ObjectToWorld, float4( v.vertex.xyz, 1 ) ).xyz;
				float3 break153_g3687 = -objToWorld183_g3687;
				float2 appendResult155_g3687 = (float2(break153_g3687.x , break153_g3687.z));
				float2 _wind_UVs106_g3687 = appendResult155_g3687;
				float mulTime137_g3687 = _Time.y * ( WindOffsetSpeed / 10.0 );
				float3 break187_g3687 = WindDirection;
				float2 appendResult188_g3687 = (float2(break187_g3687.x , break187_g3687.z));
				float2 _wind_direction110_g3687 = appendResult188_g3687;
				float4 tex2DNode144_g3687 = tex2Dlod( WindMap, float4( ( ( _wind_UVs106_g3687 / WindTillingSize ) + ( mulTime137_g3687 * _wind_direction110_g3687 ) ), 0, 0.0) );
				float smoothstepResult53_g3687 = smoothstep( WindSmoothstep.x , WindSmoothstep.y , tex2DNode144_g3687.r);
				float smoothstepResult170_g3687 = smoothstep( _SecondWindSmoothstep.x , _SecondWindSmoothstep.y , smoothstepResult53_g3687);
				float _wind_amplitude116_g3687 = WindAmplitude;
				float temp_output_2490_0 = ( smoothstepResult170_g3687 * _wind_amplitude116_g3687 );
				float wpo_wind_rawMask497_g3679 = temp_output_2490_0;
				float debug_disableWPO486_g3679 = DebugDisableWPO;
				#ifdef _DEBUGDISABLEWINDDPO_ON
				float staticSwitch479_g3679 = ( debug_disableWPO486_g3679 == 1.0 ? 0.0 : wpo_wind_rawMask497_g3679 );
				#else
				float staticSwitch479_g3679 = wpo_wind_rawMask497_g3679;
				#endif
				float wpo_wind_mask302_g3679 = staticSwitch479_g3679;
				float wind_mask423_g3680 = wpo_wind_mask302_g3679;
				float lerpResult192_g3680 = lerp( 0.0 , ( acos( dotResult330_g3680 ) * sign( dotResult356_g3680 ) ) , wind_mask423_g3680);
				float3 appendResult465_g3680 = (float3(0.0 , _BezierP1.y , _BezierP1.x));
				float3 temp_output_453_0_g3680 = ( appendResult465_g3680 * _BezierAlpha );
				float3 appendResult419_g3680 = (float3(0.0 , _BezierOffsetP1.y , _BezierOffsetP1.x));
				float3 rotatedValue187_g3680 = RotateAroundAxis( float3( 0,0,0 ), ( temp_output_453_0_g3680 + ( appendResult419_g3680 * wind_mask423_g3680 * _BezierOffsetAlpha ) ), float3( 0,1,0 ), lerpResult192_g3680 );
				float3 temp_output_15_0_g3681 = rotatedValue187_g3680;
				float3 p121_g3681 = temp_output_15_0_g3681;
				float3 appendResult463_g3680 = (float3(0.0 , _BezierP2.y , _BezierP2.x));
				float3 temp_output_454_0_g3680 = ( appendResult463_g3680 * _BezierAlpha );
				float3 appendResult420_g3680 = (float3(0.0 , _BezierOffsetP2.y , _BezierOffsetP2.x));
				float3 rotatedValue195_g3680 = RotateAroundAxis( float3( 0,0,0 ), ( temp_output_454_0_g3680 + ( appendResult420_g3680 * wind_mask423_g3680 * _BezierOffsetAlpha ) ), float3( 0,1,0 ), lerpResult192_g3680 );
				float3 temp_output_14_0_g3681 = rotatedValue195_g3680;
				float3 p221_g3681 = temp_output_14_0_g3681;
				float wpo_CoordMask184_g3679 = v.ase_color.r;
				float temp_output_6_0_g3681 = wpo_CoordMask184_g3679;
				float t21_g3681 = temp_output_6_0_g3681;
				float3 localTrigonometricBezierCurve21_g3681 = TrigonometricBezierCurve( p121_g3681 , p221_g3681 , t21_g3681 );
				float3 temp_output_500_0_g3679 = localTrigonometricBezierCurve21_g3681;
				half3 _RelativeUp = half3(0,1,0);
				float3 temp_output_26_0_g3682 = wpo_wind_direction306_g3679;
				float dotResult7_g3682 = dot( temp_output_26_0_g3682 , _RelativeUp );
				float lerpResult10_g3682 = lerp( -1.570796 , 1.570796 , ( ( dotResult7_g3682 * 0.5 ) + 0.5 ));
				float3 rotatedValue17_g3682 = RotateAroundAxis( float3( 0,0,0 ), temp_output_26_0_g3682, normalize( cross( _RelativeUp , temp_output_26_0_g3682 ) ), lerpResult10_g3682 );
				float temp_output_25_0_g3682 = wpo_wind_mask302_g3679;
				float lerpResult21_g3682 = lerp( 0.0 , _SimpleWindyYOffset , temp_output_25_0_g3682);
				float3 appendResult23_g3682 = (float3(0.0 , lerpResult21_g3682 , 0.0));
				float3 temp_output_499_0_g3679 = ( wpo_CoordMask184_g3679 * ( ( rotatedValue17_g3682 + appendResult23_g3682 ) * _SimpleWindDisplacement * temp_output_25_0_g3682 ) );
				#if defined(_WIND_NONE)
				float3 staticSwitch166_g3679 = float3( 0,0,0 );
				#elif defined(_WIND_SIMPLE)
				float3 staticSwitch166_g3679 = temp_output_499_0_g3679;
				#elif defined(_WIND_ADVANCED)
				float3 staticSwitch166_g3679 = temp_output_500_0_g3679;
				#else
				float3 staticSwitch166_g3679 = temp_output_500_0_g3679;
				#endif
				float3 out_wpo_windy423_g3679 = staticSwitch166_g3679;
				float3 temp_output_159_0_g3686 = out_wpo_windy423_g3679;
				float4 transform584_g3679 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float4 tex2DNode29_g3686 = tex2Dlod( CrushRenderTexture, float4( ( ( ( (transform584_g3679).xz + -CrushBufferOffset ) + ( CrushBufferSize / 2.0 ) ) / CrushBufferSize ), 0, 0.0) );
				float2 temp_output_96_0_g3686 = ( ( (tex2DNode29_g3686).rg - float2( 0.5,0.5 ) ) * float2( 2,2 ) );
				float2 break98_g3686 = temp_output_96_0_g3686;
				float3 appendResult102_g3686 = (float3(break98_g3686.x , 0.0 , break98_g3686.y));
				float3 worldToObjDir101_g3686 = mul( unity_WorldToObject, float4( appendResult102_g3686, 0 ) ).xyz;
				float3 crush_direction172_g3686 = worldToObjDir101_g3686;
				float vectorField_length134_g3686 = length( temp_output_96_0_g3686 );
				float3 temp_output_126_0_g3686 = float3( 0,0,0 );
				float3 ase_worldPos = mul(unity_ObjectToWorld, float4( (v.vertex).xyz, 1 )).xyz;
				float3 worldToObj14_g3686 = mul( unity_WorldToObject, float4( ase_worldPos, 1 ) ).xyz;
				float3 rotatedValue16_g3686 = RotateAroundAxis( temp_output_126_0_g3686, worldToObj14_g3686, crush_direction172_g3686, ( radians( _CrushAngle ) * vectorField_length134_g3686 ) );
				float3 appendResult195_g3686 = (float3(1.0 , ( 1.0 - _CrushFlattenScale ) , 1.0));
				float3 appendResult66_g3686 = (float3(0.0 , _CrushHeightOffset , 0.0));
				float crush_coordMasd87_g3686 = wpo_CoordMask184_g3679;
				float3 ase_parentObjectScale = ( 1.0 / float3( length( unity_WorldToObject[ 0 ].xyz ), length( unity_WorldToObject[ 1 ].xyz ), length( unity_WorldToObject[ 2 ].xyz ) ) );
				float RT_b236_g3686 = tex2DNode29_g3686.b;
				float4 transform223_g3686 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float temp_output_235_0_g3686 = ( RT_b236_g3686 == 0.0 ? ( ( vectorField_length134_g3686 * saturate( ( crush_coordMasd87_g3686 * 8.0 ) ) ) * saturate( ( ( CrushDistanceView - distance( float4( _WorldSpaceCameraPos , 0.0 ) , transform223_g3686 ) ) / CrushDistanceViewFalloff ) ) ) : 0.0 );
				float3 lerpResult160_g3686 = lerp( temp_output_159_0_g3686 , ( ( ( rotatedValue16_g3686 - worldToObj14_g3686 ) * appendResult195_g3686 ) + ( appendResult66_g3686 * crush_coordMasd87_g3686 * ase_parentObjectScale.y ) ) , temp_output_235_0_g3686);
				#ifdef _USECRUSH_ON
				float3 staticSwitch162_g3686 = lerpResult160_g3686;
				#else
				float3 staticSwitch162_g3686 = temp_output_159_0_g3686;
				#endif
				float3 out_wpo_crush432_g3679 = staticSwitch162_g3686;
				float smoothstepResult112_g3683 = smoothstep( 0.0 , _TurbulenceSmoothstepMax , wpo_wind_rawMask497_g3679);
				float temp_output_153_0_g3683 = saturate( smoothstepResult112_g3683 );
				float4 transform119_g3683 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float mulTime95_g3683 = _Time.y * _TurbulenceSpeed;
				float3 ase_objectScale = float3( length( unity_ObjectToWorld[ 0 ].xyz ), length( unity_ObjectToWorld[ 1 ].xyz ), length( unity_ObjectToWorld[ 2 ].xyz ) );
				float temp_output_99_0_g3683 = ( cos( ( ( ( ( ( transform119_g3683.x * 100.0 ) + ( transform119_g3683.z * 33.0 ) ) - mulTime95_g3683 ) + v.vertex.xyz.y ) / _TurbulenceFrequency ) ) * _TurbulenceDisplacement * ase_objectScale.y * v.ase_texcoord.y );
				float3 temp_output_88_0_g3683 = wpo_wind_direction306_g3679;
				float3 temp_output_544_0_g3679 = ( out_wpo_crush432_g3679 + ( temp_output_153_0_g3683 * temp_output_99_0_g3683 * temp_output_88_0_g3683 ) );
				#if defined(_WIND_NONE)
				float3 staticSwitch438_g3679 = float3( 0,0,0 );
				#elif defined(_WIND_SIMPLE)
				float3 staticSwitch438_g3679 = temp_output_544_0_g3679;
				#elif defined(_WIND_ADVANCED)
				float3 staticSwitch438_g3679 = temp_output_544_0_g3679;
				#else
				float3 staticSwitch438_g3679 = temp_output_544_0_g3679;
				#endif
				float3 wpo_out_turbulence508_g3679 = staticSwitch438_g3679;
				#ifdef _DEBUGDISABLEWINDDPO_ON
				float3 staticSwitch466_g3679 = ( debug_disableWPO486_g3679 == 1.0 ? out_wpo_crush432_g3679 : wpo_out_turbulence508_g3679 );
				#else
				float3 staticSwitch466_g3679 = wpo_out_turbulence508_g3679;
				#endif
				
				float3 lerpResult3_g2806 = lerp( v.normal , float3(0,1,0) , _FlattenVertexNormal);
				
				o.ase_texcoord5.xyz = ase_worldPos;
				
				o.ase_texcoord3 = v.vertex;
				o.ase_texcoord4.xy = v.ase_texcoord.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord4.zw = 0;
				o.ase_texcoord5.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = staticSwitch466_g3679;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.vertex.w = 1;
				v.normal = lerpResult3_g2806;
				v.tangent = v.tangent;

				#ifdef EDITOR_VISUALIZATION
					o.vizUV = 0;
					o.lightCoord = 0;
					if (unity_VisualizationMode == EDITORVIZ_TEXTURE)
						o.vizUV = UnityMetaVizUV(unity_EditorViz_UVIndex, v.texcoord.xy, v.texcoord1.xy, v.texcoord2.xy, unity_EditorViz_Texture_ST);
					else if (unity_VisualizationMode == EDITORVIZ_SHOWLIGHTMASK)
					{
						o.vizUV = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
						o.lightCoord = mul(unity_EditorViz_WorldToLight, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)));
					}
				#endif

				o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			v2f vert ( appdata v )
			{
				return VertexFunction( v );
			}
			#endif

			fixed4 frag (v2f IN 
				#ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
				#endif
				) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				#ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
				#endif

				#if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
				#else
					SurfaceOutputStandard o = (SurfaceOutputStandard)0;
				#endif

				float3 temp_cast_0 = (IN.ase_texcoord3.xyz.y).xxx;
				float3 objToWorld541_g3660 = mul( unity_ObjectToWorld, float4( temp_cast_0, 1 ) ).xyz;
				float In1_g3661 = ( objToWorld541_g3660.y + _VariantOffset );
				float Value1_g3661 = _VariantContrast;
				float localCheapContrast1_g3661 = CheapContrast1_g3661( In1_g3661 , Value1_g3661 );
				float4 lerpResult350_g3660 = lerp( _MainBaseColor , _VariantBaseColor , saturate( localCheapContrast1_g3661 ));
				float4 appendResult442_g3660 = (float4((lerpResult350_g3660).rgb , 1.0));
				float2 uv_BaseMap53_g3660 = IN.ase_texcoord4.xy;
				float4 tex2DNode53_g3660 = tex2D( _BaseMap, uv_BaseMap53_g3660 );
				float4 _baseMap50_g3660 = tex2DNode53_g3660;
				float4 temp_output_428_0_g3660 = ( appendResult442_g3660 * _baseMap50_g3660 );
				float4 temp_output_124_0_g3662 = temp_output_428_0_g3660;
				float3 temp_output_125_0_g3662 = (temp_output_124_0_g3662).rgb;
				float _colormap_baseMap_Alpha146_g3662 = (temp_output_124_0_g3662).a;
				float4 appendResult132_g3662 = (float4(temp_output_125_0_g3662 , _colormap_baseMap_Alpha146_g3662));
				float3 ase_worldPos = IN.ase_texcoord5.xyz;
				float coord_mask88_g3660 = IN.ase_color.r;
				float In1_g3663 = ( coord_mask88_g3660 - _ColorMapBlendOffset );
				float Value1_g3663 = _ColorMapFadeContrast;
				float localCheapContrast1_g3663 = CheapContrast1_g3663( In1_g3663 , Value1_g3663 );
				float3 lerpResult97_g3662 = lerp( (tex2D( ColorMap, ( ( (ase_worldPos).xz + ColorMapOffset ) / ColorMapTillingSize ) )).rgb , temp_output_125_0_g3662 , saturate( ( (lerpResult350_g3660).a * localCheapContrast1_g3663 ) ));
				float3 break65_g3662 = lerpResult97_g3662;
				float4 appendResult64_g3662 = (float4(break65_g3662.x , break65_g3662.y , break65_g3662.z , _colormap_baseMap_Alpha146_g3662));
				#ifdef _USECOLORMAP_ON
				float4 staticSwitch128_g3662 = appendResult64_g3662;
				#else
				float4 staticSwitch128_g3662 = appendResult132_g3662;
				#endif
				float4 temp_output_23_0_g3665 = staticSwitch128_g3662;
				float3 objToWorld183_g3687 = mul( unity_ObjectToWorld, float4( IN.ase_texcoord3.xyz, 1 ) ).xyz;
				float3 break153_g3687 = -objToWorld183_g3687;
				float2 appendResult155_g3687 = (float2(break153_g3687.x , break153_g3687.z));
				float2 _wind_UVs106_g3687 = appendResult155_g3687;
				float mulTime137_g3687 = _Time.y * ( WindOffsetSpeed / 10.0 );
				float3 break187_g3687 = WindDirection;
				float2 appendResult188_g3687 = (float2(break187_g3687.x , break187_g3687.z));
				float2 _wind_direction110_g3687 = appendResult188_g3687;
				float4 tex2DNode144_g3687 = tex2D( WindMap, ( ( _wind_UVs106_g3687 / WindTillingSize ) + ( mulTime137_g3687 * _wind_direction110_g3687 ) ) );
				float smoothstepResult53_g3687 = smoothstep( WindSmoothstep.x , WindSmoothstep.y , tex2DNode144_g3687.r);
				float smoothstepResult170_g3687 = smoothstep( _SecondWindSmoothstep.x , _SecondWindSmoothstep.y , smoothstepResult53_g3687);
				float _wind_amplitude116_g3687 = WindAmplitude;
				float temp_output_2490_0 = ( smoothstepResult170_g3687 * _wind_amplitude116_g3687 );
				float windMask397_g3660 = temp_output_2490_0;
				float lerpResult71_g3665 = lerp( 1.0 , _WindBrightness , windMask397_g3660);
				float4 transform584_g3679 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float4 tex2DNode29_g3686 = tex2D( CrushRenderTexture, ( ( ( (transform584_g3679).xz + -CrushBufferOffset ) + ( CrushBufferSize / 2.0 ) ) / CrushBufferSize ) );
				float RT_b236_g3686 = tex2DNode29_g3686.b;
				float2 temp_output_96_0_g3686 = ( ( (tex2DNode29_g3686).rg - float2( 0.5,0.5 ) ) * float2( 2,2 ) );
				float vectorField_length134_g3686 = length( temp_output_96_0_g3686 );
				float wpo_CoordMask184_g3679 = IN.ase_color.r;
				float crush_coordMasd87_g3686 = wpo_CoordMask184_g3679;
				float4 transform223_g3686 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float temp_output_235_0_g3686 = ( RT_b236_g3686 == 0.0 ? ( ( vectorField_length134_g3686 * saturate( ( crush_coordMasd87_g3686 * 8.0 ) ) ) * saturate( ( ( CrushDistanceView - distance( float4( _WorldSpaceCameraPos , 0.0 ) , transform223_g3686 ) ) / CrushDistanceViewFalloff ) ) ) : 0.0 );
				#ifdef _USECRUSH_ON
				float staticSwitch163_g3686 = temp_output_235_0_g3686;
				#else
				float staticSwitch163_g3686 = 0.0;
				#endif
				float lerpResult78_g3665 = lerp( lerpResult71_g3665 , _CrushBrightness , staticSwitch163_g3686);
				float lerpResult83_g3665 = lerp( 1.0 , lerpResult78_g3665 , saturate( ( coord_mask88_g3660 * 2.0 ) ));
				float4 appendResult29_g3665 = (float4((saturate( ( temp_output_23_0_g3665 * lerpResult83_g3665 ) )).rgb , (temp_output_23_0_g3665).a));
				float4 temp_output_529_0_g3660 = appendResult29_g3665;
				float4 temp_output_72_0_g3667 = temp_output_529_0_g3660;
				float2 temp_output_5_0_g3667 = (ase_worldPos).xz;
				float mulTime8_g3667 = _Time.y * -( WindOffsetSpeed * AirSpeedMultiplier );
				float2 UV67_g3667 = ( temp_output_5_0_g3667 + ( mulTime8_g3667 * (WindDirection).xz ) );
				float windAngle482_g3660 = WindAngle;
				float Angle67_g3667 = windAngle482_g3660;
				float2 localRotateUV67_g3667 = RotateUV67_g3667( UV67_g3667 , Angle67_g3667 );
				float smoothstepResult23_g3667 = smoothstep( AirSmoothstep.x , AirSmoothstep.y , tex2D( AirMap, ( (UnpackScaleNormal( tex2D( AirRefractionMap, ( temp_output_5_0_g3667 / AirRefractionTillingSize ) ), AirRefractionStrength )).xy + ( localRotateUV67_g3667 / AirTillingSize ) ) ).r);
				#ifdef _USEAIRSHEENTINT_ON
				float4 staticSwitch73_g3667 = saturate( ( temp_output_72_0_g3667 + ( smoothstepResult23_g3667 * AirStrength * saturate( ( IN.ase_color.r * 4.0 ) ) * windMask397_g3660 ) ) );
				#else
				float4 staticSwitch73_g3667 = temp_output_72_0_g3667;
				#endif
				float4 albedo109_g3669 = staticSwitch73_g3667;
				int isDebugWind98_g3669 = ( DebugWind + DebugWindTurbulence );
				int debugWindTurbulence103_g3669 = DebugWindTurbulence;
				int debugWind105_g3669 = DebugWind;
				half4 color126_g3669 = IsGammaSpace() ? half4(0,0,0,0) : half4(0,0,0,0);
				Gradient gradient82_g3669 = NewGradient( 0, 7, 2, float4( 0.5, 0.5, 0.5, 0 ), float4( 0, 0.716, 0, 0.06471352 ), float4( 1, 1, 0, 0.2205844 ), float4( 1, 0.5698085, 0, 0.5470665 ), float4( 1, 0.3047979, 0, 0.7499962 ), float4( 1, 0, 0, 0.9411765 ), float4( 0.5626073, 0, 1, 1 ), 0, float2( 1, 0 ), float2( 1, 1 ), 0, 0, 0, 0, 0, 0 );
				float4 temp_output_106_0_g3669 = ( (float)debugWind105_g3669 == 1.0 ? SampleGradient( gradient82_g3669, windMask397_g3660 ) : albedo109_g3669 );
				float4 ifLocalVar131_g3669 = 0;
				if( debugWindTurbulence103_g3669 <= debugWind105_g3669 )
				ifLocalVar131_g3669 = temp_output_106_0_g3669;
				else
				ifLocalVar131_g3669 = color126_g3669;
				half4 color64_g3669 = IsGammaSpace() ? half4(1,1,1,0) : half4(1,1,1,0);
				float4 transform119_g3683 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float mulTime95_g3683 = _Time.y * _TurbulenceSpeed;
				float3 ase_objectScale = float3( length( unity_ObjectToWorld[ 0 ].xyz ), length( unity_ObjectToWorld[ 1 ].xyz ), length( unity_ObjectToWorld[ 2 ].xyz ) );
				float temp_output_99_0_g3683 = ( cos( ( ( ( ( ( transform119_g3683.x * 100.0 ) + ( transform119_g3683.z * 33.0 ) ) - mulTime95_g3683 ) + IN.ase_texcoord3.xyz.y ) / _TurbulenceFrequency ) ) * _TurbulenceDisplacement * ase_objectScale.y * IN.ase_texcoord4.xy.y );
				float wpo_wind_rawMask497_g3679 = temp_output_2490_0;
				float smoothstepResult112_g3683 = smoothstep( 0.0 , _TurbulenceSmoothstepMax , wpo_wind_rawMask497_g3679);
				float temp_output_153_0_g3683 = saturate( smoothstepResult112_g3683 );
				float temp_output_544_85_g3679 = ( temp_output_99_0_g3683 * temp_output_153_0_g3683 );
				#if defined(_WIND_NONE)
				float staticSwitch441_g3679 = 0.0;
				#elif defined(_WIND_SIMPLE)
				float staticSwitch441_g3679 = temp_output_544_85_g3679;
				#elif defined(_WIND_ADVANCED)
				float staticSwitch441_g3679 = temp_output_544_85_g3679;
				#else
				float staticSwitch441_g3679 = temp_output_544_85_g3679;
				#endif
				float4 lerpResult62_g3669 = lerp( ifLocalVar131_g3669 , color64_g3669 , ( (float)debugWindTurbulence103_g3669 == 1.0 ? saturate( ( staticSwitch441_g3679 * 20.0 ) ) : 0.0 ));
				#ifdef _DEBUGWIND_ON
				float4 staticSwitch134_g3669 = ( (float)isDebugWind98_g3669 >= 1.0 ? lerpResult62_g3669 : albedo109_g3669 );
				#else
				float4 staticSwitch134_g3669 = albedo109_g3669;
				#endif
				
				o.Albedo = (staticSwitch134_g3669).xyz;
				o.Normal = fixed3( 0, 0, 1 );
				o.Emission = half3( 0, 0, 0 );
				o.Alpha = (temp_output_529_0_g3660).a;
				float AlphaClipThreshold = _AlphaThreshold;

				#ifdef _ALPHATEST_ON
					clip( o.Alpha - AlphaClipThreshold );
				#endif

				#ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
				#endif

				UnityMetaInput metaIN;
				UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaIN);
				metaIN.Albedo = o.Albedo;
				metaIN.Emission = o.Emission;
				#ifdef EDITOR_VISUALIZATION
					metaIN.VizUV = IN.vizUV;
					metaIN.LightCoord = IN.lightCoord;
				#endif
				return UnityMetaFragment(metaIN);
			}
			ENDCG
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }
			ZWrite On
			ZTest LEqual
			AlphaToMask Off

			CGPROGRAM
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile_instancing
			#pragma multi_compile __ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1

			#pragma vertex vert
			#pragma fragment frag
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#pragma multi_compile_shadowcaster
			#ifndef UNITY_PASS_SHADOWCASTER
				#define UNITY_PASS_SHADOWCASTER
			#endif
			#include "HLSLSupport.cginc"
			#ifndef UNITY_INSTANCED_LOD_FADE
				#define UNITY_INSTANCED_LOD_FADE
			#endif
			#ifndef UNITY_INSTANCED_SH
				#define UNITY_INSTANCED_SH
			#endif
			#ifndef UNITY_INSTANCED_LIGHTMAPSTS
				#define UNITY_INSTANCED_LIGHTMAPSTS
			#endif
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityShaderVariables.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_POSITION
			#define ASE_NEEDS_FRAG_COLOR
			#pragma multi_compile_local __ _DEBUGDISABLEWINDDPO_ON
			#pragma shader_feature_local _WIND_NONE _WIND_SIMPLE _WIND_ADVANCED
			#pragma shader_feature_local _USECRUSH_ON
			#pragma shader_feature_local _USECOLORMAP_ON

			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				V2F_SHADOW_CASTER;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#ifdef UNITY_STANDARD_USE_DITHER_MASK
				sampler3D _DitherMaskLOD;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			uniform half _UseTreeBend;
			uniform float3 WindDirection;
			uniform float WindOffsetSpeed;
			uniform float WindTillingSize;
			uniform float2 _SecondWindSmoothstep;
			uniform float2 WindSmoothstep;
			uniform sampler2D WindMap;
			uniform half WindAmplitude;
			uniform half DebugDisableWPO;
			uniform half2 _BezierP1;
			uniform half _BezierAlpha;
			uniform half2 _BezierOffsetP1;
			uniform half _BezierOffsetAlpha;
			uniform half2 _BezierP2;
			uniform half2 _BezierOffsetP2;
			uniform half _SimpleWindyYOffset;
			uniform half _SimpleWindDisplacement;
			uniform sampler2D CrushRenderTexture;
			uniform float2 CrushBufferOffset;
			uniform half CrushBufferSize;
			uniform half _CrushAngle;
			uniform half _CrushFlattenScale;
			uniform half _CrushHeightOffset;
			uniform half CrushDistanceView;
			uniform half CrushDistanceViewFalloff;
			uniform half _TurbulenceSmoothstepMax;
			uniform half _TurbulenceSpeed;
			uniform half _TurbulenceFrequency;
			uniform half _TurbulenceDisplacement;
			uniform float _FlattenVertexNormal;
			uniform half4 _MainBaseColor;
			uniform half4 _VariantBaseColor;
			uniform half _VariantOffset;
			uniform half _VariantContrast;
			uniform sampler2D _BaseMap;
			uniform sampler2D ColorMap;
			uniform float2 ColorMapOffset;
			uniform float2 ColorMapTillingSize;
			uniform half _ColorMapBlendOffset;
			uniform half _ColorMapFadeContrast;
			uniform half _WindBrightness;
			uniform half _CrushBrightness;
			uniform half _AlphaThreshold;


			float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
			{
				original -= center;
				float C = cos( angle );
				float S = sin( angle );
				float t = 1 - C;
				float m00 = t * u.x * u.x + C;
				float m01 = t * u.x * u.y - S * u.z;
				float m02 = t * u.x * u.z + S * u.y;
				float m10 = t * u.x * u.y + S * u.z;
				float m11 = t * u.y * u.y + C;
				float m12 = t * u.y * u.z - S * u.x;
				float m20 = t * u.x * u.z - S * u.y;
				float m21 = t * u.y * u.z + S * u.x;
				float m22 = t * u.z * u.z + C;
				float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
				return mul( finalMatrix, original ) + center;
			}
			
			float3 TrigonometricBezierCurve( float3 p1, float3 p2, float t )
			{
				float3 p0 = float3(0, 0, 0);
				float u = 1 - t;
				float t2 = t * t;
				float u2 = u * u;
				float3 result =
					(u2)*p0 +
					(2 * u * t) * p1 +
					t2 * p2;
				return result;
			}
			
			float CheapContrast1_g3661( float In, float Value )
			{
				float A = 0 - Value;
				float B = 1 + Value;
				return clamp(0,1, lerp(A,B,In));
			}
			
			float CheapContrast1_g3663( float In, float Value )
			{
				float A = 0 - Value;
				float B = 1 + Value;
				return clamp(0,1, lerp(A,B,In));
			}
			

			v2f VertexFunction (appdata v  ) {
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 temp_output_331_0_g3680 = (half3(0,0,1)).xz;
				float3 worldToObjDir141_g3687 = normalize( mul( unity_WorldToObject, float4( WindDirection, 0 ) ).xyz );
				float3 wpo_wind_direction306_g3679 = worldToObjDir141_g3687;
				float3 temp_output_295_0_g3680 = wpo_wind_direction306_g3679;
				float dotResult330_g3680 = dot( temp_output_331_0_g3680 , (temp_output_295_0_g3680).xz );
				float3 break444_g3680 = temp_output_295_0_g3680;
				float2 appendResult355_g3680 = (float2(break444_g3680.z , break444_g3680.x));
				float dotResult356_g3680 = dot( temp_output_331_0_g3680 , appendResult355_g3680 );
				float3 objToWorld183_g3687 = mul( unity_ObjectToWorld, float4( v.vertex.xyz, 1 ) ).xyz;
				float3 break153_g3687 = -objToWorld183_g3687;
				float2 appendResult155_g3687 = (float2(break153_g3687.x , break153_g3687.z));
				float2 _wind_UVs106_g3687 = appendResult155_g3687;
				float mulTime137_g3687 = _Time.y * ( WindOffsetSpeed / 10.0 );
				float3 break187_g3687 = WindDirection;
				float2 appendResult188_g3687 = (float2(break187_g3687.x , break187_g3687.z));
				float2 _wind_direction110_g3687 = appendResult188_g3687;
				float4 tex2DNode144_g3687 = tex2Dlod( WindMap, float4( ( ( _wind_UVs106_g3687 / WindTillingSize ) + ( mulTime137_g3687 * _wind_direction110_g3687 ) ), 0, 0.0) );
				float smoothstepResult53_g3687 = smoothstep( WindSmoothstep.x , WindSmoothstep.y , tex2DNode144_g3687.r);
				float smoothstepResult170_g3687 = smoothstep( _SecondWindSmoothstep.x , _SecondWindSmoothstep.y , smoothstepResult53_g3687);
				float _wind_amplitude116_g3687 = WindAmplitude;
				float temp_output_2490_0 = ( smoothstepResult170_g3687 * _wind_amplitude116_g3687 );
				float wpo_wind_rawMask497_g3679 = temp_output_2490_0;
				float debug_disableWPO486_g3679 = DebugDisableWPO;
				#ifdef _DEBUGDISABLEWINDDPO_ON
				float staticSwitch479_g3679 = ( debug_disableWPO486_g3679 == 1.0 ? 0.0 : wpo_wind_rawMask497_g3679 );
				#else
				float staticSwitch479_g3679 = wpo_wind_rawMask497_g3679;
				#endif
				float wpo_wind_mask302_g3679 = staticSwitch479_g3679;
				float wind_mask423_g3680 = wpo_wind_mask302_g3679;
				float lerpResult192_g3680 = lerp( 0.0 , ( acos( dotResult330_g3680 ) * sign( dotResult356_g3680 ) ) , wind_mask423_g3680);
				float3 appendResult465_g3680 = (float3(0.0 , _BezierP1.y , _BezierP1.x));
				float3 temp_output_453_0_g3680 = ( appendResult465_g3680 * _BezierAlpha );
				float3 appendResult419_g3680 = (float3(0.0 , _BezierOffsetP1.y , _BezierOffsetP1.x));
				float3 rotatedValue187_g3680 = RotateAroundAxis( float3( 0,0,0 ), ( temp_output_453_0_g3680 + ( appendResult419_g3680 * wind_mask423_g3680 * _BezierOffsetAlpha ) ), float3( 0,1,0 ), lerpResult192_g3680 );
				float3 temp_output_15_0_g3681 = rotatedValue187_g3680;
				float3 p121_g3681 = temp_output_15_0_g3681;
				float3 appendResult463_g3680 = (float3(0.0 , _BezierP2.y , _BezierP2.x));
				float3 temp_output_454_0_g3680 = ( appendResult463_g3680 * _BezierAlpha );
				float3 appendResult420_g3680 = (float3(0.0 , _BezierOffsetP2.y , _BezierOffsetP2.x));
				float3 rotatedValue195_g3680 = RotateAroundAxis( float3( 0,0,0 ), ( temp_output_454_0_g3680 + ( appendResult420_g3680 * wind_mask423_g3680 * _BezierOffsetAlpha ) ), float3( 0,1,0 ), lerpResult192_g3680 );
				float3 temp_output_14_0_g3681 = rotatedValue195_g3680;
				float3 p221_g3681 = temp_output_14_0_g3681;
				float wpo_CoordMask184_g3679 = v.ase_color.r;
				float temp_output_6_0_g3681 = wpo_CoordMask184_g3679;
				float t21_g3681 = temp_output_6_0_g3681;
				float3 localTrigonometricBezierCurve21_g3681 = TrigonometricBezierCurve( p121_g3681 , p221_g3681 , t21_g3681 );
				float3 temp_output_500_0_g3679 = localTrigonometricBezierCurve21_g3681;
				half3 _RelativeUp = half3(0,1,0);
				float3 temp_output_26_0_g3682 = wpo_wind_direction306_g3679;
				float dotResult7_g3682 = dot( temp_output_26_0_g3682 , _RelativeUp );
				float lerpResult10_g3682 = lerp( -1.570796 , 1.570796 , ( ( dotResult7_g3682 * 0.5 ) + 0.5 ));
				float3 rotatedValue17_g3682 = RotateAroundAxis( float3( 0,0,0 ), temp_output_26_0_g3682, normalize( cross( _RelativeUp , temp_output_26_0_g3682 ) ), lerpResult10_g3682 );
				float temp_output_25_0_g3682 = wpo_wind_mask302_g3679;
				float lerpResult21_g3682 = lerp( 0.0 , _SimpleWindyYOffset , temp_output_25_0_g3682);
				float3 appendResult23_g3682 = (float3(0.0 , lerpResult21_g3682 , 0.0));
				float3 temp_output_499_0_g3679 = ( wpo_CoordMask184_g3679 * ( ( rotatedValue17_g3682 + appendResult23_g3682 ) * _SimpleWindDisplacement * temp_output_25_0_g3682 ) );
				#if defined(_WIND_NONE)
				float3 staticSwitch166_g3679 = float3( 0,0,0 );
				#elif defined(_WIND_SIMPLE)
				float3 staticSwitch166_g3679 = temp_output_499_0_g3679;
				#elif defined(_WIND_ADVANCED)
				float3 staticSwitch166_g3679 = temp_output_500_0_g3679;
				#else
				float3 staticSwitch166_g3679 = temp_output_500_0_g3679;
				#endif
				float3 out_wpo_windy423_g3679 = staticSwitch166_g3679;
				float3 temp_output_159_0_g3686 = out_wpo_windy423_g3679;
				float4 transform584_g3679 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float4 tex2DNode29_g3686 = tex2Dlod( CrushRenderTexture, float4( ( ( ( (transform584_g3679).xz + -CrushBufferOffset ) + ( CrushBufferSize / 2.0 ) ) / CrushBufferSize ), 0, 0.0) );
				float2 temp_output_96_0_g3686 = ( ( (tex2DNode29_g3686).rg - float2( 0.5,0.5 ) ) * float2( 2,2 ) );
				float2 break98_g3686 = temp_output_96_0_g3686;
				float3 appendResult102_g3686 = (float3(break98_g3686.x , 0.0 , break98_g3686.y));
				float3 worldToObjDir101_g3686 = mul( unity_WorldToObject, float4( appendResult102_g3686, 0 ) ).xyz;
				float3 crush_direction172_g3686 = worldToObjDir101_g3686;
				float vectorField_length134_g3686 = length( temp_output_96_0_g3686 );
				float3 temp_output_126_0_g3686 = float3( 0,0,0 );
				float3 ase_worldPos = mul(unity_ObjectToWorld, float4( (v.vertex).xyz, 1 )).xyz;
				float3 worldToObj14_g3686 = mul( unity_WorldToObject, float4( ase_worldPos, 1 ) ).xyz;
				float3 rotatedValue16_g3686 = RotateAroundAxis( temp_output_126_0_g3686, worldToObj14_g3686, crush_direction172_g3686, ( radians( _CrushAngle ) * vectorField_length134_g3686 ) );
				float3 appendResult195_g3686 = (float3(1.0 , ( 1.0 - _CrushFlattenScale ) , 1.0));
				float3 appendResult66_g3686 = (float3(0.0 , _CrushHeightOffset , 0.0));
				float crush_coordMasd87_g3686 = wpo_CoordMask184_g3679;
				float3 ase_parentObjectScale = ( 1.0 / float3( length( unity_WorldToObject[ 0 ].xyz ), length( unity_WorldToObject[ 1 ].xyz ), length( unity_WorldToObject[ 2 ].xyz ) ) );
				float RT_b236_g3686 = tex2DNode29_g3686.b;
				float4 transform223_g3686 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float temp_output_235_0_g3686 = ( RT_b236_g3686 == 0.0 ? ( ( vectorField_length134_g3686 * saturate( ( crush_coordMasd87_g3686 * 8.0 ) ) ) * saturate( ( ( CrushDistanceView - distance( float4( _WorldSpaceCameraPos , 0.0 ) , transform223_g3686 ) ) / CrushDistanceViewFalloff ) ) ) : 0.0 );
				float3 lerpResult160_g3686 = lerp( temp_output_159_0_g3686 , ( ( ( rotatedValue16_g3686 - worldToObj14_g3686 ) * appendResult195_g3686 ) + ( appendResult66_g3686 * crush_coordMasd87_g3686 * ase_parentObjectScale.y ) ) , temp_output_235_0_g3686);
				#ifdef _USECRUSH_ON
				float3 staticSwitch162_g3686 = lerpResult160_g3686;
				#else
				float3 staticSwitch162_g3686 = temp_output_159_0_g3686;
				#endif
				float3 out_wpo_crush432_g3679 = staticSwitch162_g3686;
				float smoothstepResult112_g3683 = smoothstep( 0.0 , _TurbulenceSmoothstepMax , wpo_wind_rawMask497_g3679);
				float temp_output_153_0_g3683 = saturate( smoothstepResult112_g3683 );
				float4 transform119_g3683 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float mulTime95_g3683 = _Time.y * _TurbulenceSpeed;
				float3 ase_objectScale = float3( length( unity_ObjectToWorld[ 0 ].xyz ), length( unity_ObjectToWorld[ 1 ].xyz ), length( unity_ObjectToWorld[ 2 ].xyz ) );
				float temp_output_99_0_g3683 = ( cos( ( ( ( ( ( transform119_g3683.x * 100.0 ) + ( transform119_g3683.z * 33.0 ) ) - mulTime95_g3683 ) + v.vertex.xyz.y ) / _TurbulenceFrequency ) ) * _TurbulenceDisplacement * ase_objectScale.y * v.ase_texcoord.y );
				float3 temp_output_88_0_g3683 = wpo_wind_direction306_g3679;
				float3 temp_output_544_0_g3679 = ( out_wpo_crush432_g3679 + ( temp_output_153_0_g3683 * temp_output_99_0_g3683 * temp_output_88_0_g3683 ) );
				#if defined(_WIND_NONE)
				float3 staticSwitch438_g3679 = float3( 0,0,0 );
				#elif defined(_WIND_SIMPLE)
				float3 staticSwitch438_g3679 = temp_output_544_0_g3679;
				#elif defined(_WIND_ADVANCED)
				float3 staticSwitch438_g3679 = temp_output_544_0_g3679;
				#else
				float3 staticSwitch438_g3679 = temp_output_544_0_g3679;
				#endif
				float3 wpo_out_turbulence508_g3679 = staticSwitch438_g3679;
				#ifdef _DEBUGDISABLEWINDDPO_ON
				float3 staticSwitch466_g3679 = ( debug_disableWPO486_g3679 == 1.0 ? out_wpo_crush432_g3679 : wpo_out_turbulence508_g3679 );
				#else
				float3 staticSwitch466_g3679 = wpo_out_turbulence508_g3679;
				#endif
				
				float3 lerpResult3_g2806 = lerp( v.normal , float3(0,1,0) , _FlattenVertexNormal);
				
				o.ase_texcoord4.xyz = ase_worldPos;
				
				o.ase_texcoord2 = v.vertex;
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				o.ase_texcoord4.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = staticSwitch466_g3679;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.vertex.w = 1;
				v.normal = lerpResult3_g2806;
				v.tangent = v.tangent;

				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			v2f vert ( appdata v )
			{
				return VertexFunction( v );
			}
			#endif

			fixed4 frag (v2f IN 
				#ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
				#endif
				#if !defined( CAN_SKIP_VPOS )
				, UNITY_VPOS_TYPE vpos : VPOS
				#endif
				) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				#ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
				#endif

				#if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
				#else
					SurfaceOutputStandard o = (SurfaceOutputStandard)0;
				#endif

				float3 temp_cast_0 = (IN.ase_texcoord2.xyz.y).xxx;
				float3 objToWorld541_g3660 = mul( unity_ObjectToWorld, float4( temp_cast_0, 1 ) ).xyz;
				float In1_g3661 = ( objToWorld541_g3660.y + _VariantOffset );
				float Value1_g3661 = _VariantContrast;
				float localCheapContrast1_g3661 = CheapContrast1_g3661( In1_g3661 , Value1_g3661 );
				float4 lerpResult350_g3660 = lerp( _MainBaseColor , _VariantBaseColor , saturate( localCheapContrast1_g3661 ));
				float4 appendResult442_g3660 = (float4((lerpResult350_g3660).rgb , 1.0));
				float2 uv_BaseMap53_g3660 = IN.ase_texcoord3.xy;
				float4 tex2DNode53_g3660 = tex2D( _BaseMap, uv_BaseMap53_g3660 );
				float4 _baseMap50_g3660 = tex2DNode53_g3660;
				float4 temp_output_428_0_g3660 = ( appendResult442_g3660 * _baseMap50_g3660 );
				float4 temp_output_124_0_g3662 = temp_output_428_0_g3660;
				float3 temp_output_125_0_g3662 = (temp_output_124_0_g3662).rgb;
				float _colormap_baseMap_Alpha146_g3662 = (temp_output_124_0_g3662).a;
				float4 appendResult132_g3662 = (float4(temp_output_125_0_g3662 , _colormap_baseMap_Alpha146_g3662));
				float3 ase_worldPos = IN.ase_texcoord4.xyz;
				float coord_mask88_g3660 = IN.ase_color.r;
				float In1_g3663 = ( coord_mask88_g3660 - _ColorMapBlendOffset );
				float Value1_g3663 = _ColorMapFadeContrast;
				float localCheapContrast1_g3663 = CheapContrast1_g3663( In1_g3663 , Value1_g3663 );
				float3 lerpResult97_g3662 = lerp( (tex2D( ColorMap, ( ( (ase_worldPos).xz + ColorMapOffset ) / ColorMapTillingSize ) )).rgb , temp_output_125_0_g3662 , saturate( ( (lerpResult350_g3660).a * localCheapContrast1_g3663 ) ));
				float3 break65_g3662 = lerpResult97_g3662;
				float4 appendResult64_g3662 = (float4(break65_g3662.x , break65_g3662.y , break65_g3662.z , _colormap_baseMap_Alpha146_g3662));
				#ifdef _USECOLORMAP_ON
				float4 staticSwitch128_g3662 = appendResult64_g3662;
				#else
				float4 staticSwitch128_g3662 = appendResult132_g3662;
				#endif
				float4 temp_output_23_0_g3665 = staticSwitch128_g3662;
				float3 objToWorld183_g3687 = mul( unity_ObjectToWorld, float4( IN.ase_texcoord2.xyz, 1 ) ).xyz;
				float3 break153_g3687 = -objToWorld183_g3687;
				float2 appendResult155_g3687 = (float2(break153_g3687.x , break153_g3687.z));
				float2 _wind_UVs106_g3687 = appendResult155_g3687;
				float mulTime137_g3687 = _Time.y * ( WindOffsetSpeed / 10.0 );
				float3 break187_g3687 = WindDirection;
				float2 appendResult188_g3687 = (float2(break187_g3687.x , break187_g3687.z));
				float2 _wind_direction110_g3687 = appendResult188_g3687;
				float4 tex2DNode144_g3687 = tex2D( WindMap, ( ( _wind_UVs106_g3687 / WindTillingSize ) + ( mulTime137_g3687 * _wind_direction110_g3687 ) ) );
				float smoothstepResult53_g3687 = smoothstep( WindSmoothstep.x , WindSmoothstep.y , tex2DNode144_g3687.r);
				float smoothstepResult170_g3687 = smoothstep( _SecondWindSmoothstep.x , _SecondWindSmoothstep.y , smoothstepResult53_g3687);
				float _wind_amplitude116_g3687 = WindAmplitude;
				float temp_output_2490_0 = ( smoothstepResult170_g3687 * _wind_amplitude116_g3687 );
				float windMask397_g3660 = temp_output_2490_0;
				float lerpResult71_g3665 = lerp( 1.0 , _WindBrightness , windMask397_g3660);
				float4 transform584_g3679 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float4 tex2DNode29_g3686 = tex2D( CrushRenderTexture, ( ( ( (transform584_g3679).xz + -CrushBufferOffset ) + ( CrushBufferSize / 2.0 ) ) / CrushBufferSize ) );
				float RT_b236_g3686 = tex2DNode29_g3686.b;
				float2 temp_output_96_0_g3686 = ( ( (tex2DNode29_g3686).rg - float2( 0.5,0.5 ) ) * float2( 2,2 ) );
				float vectorField_length134_g3686 = length( temp_output_96_0_g3686 );
				float wpo_CoordMask184_g3679 = IN.ase_color.r;
				float crush_coordMasd87_g3686 = wpo_CoordMask184_g3679;
				float4 transform223_g3686 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float temp_output_235_0_g3686 = ( RT_b236_g3686 == 0.0 ? ( ( vectorField_length134_g3686 * saturate( ( crush_coordMasd87_g3686 * 8.0 ) ) ) * saturate( ( ( CrushDistanceView - distance( float4( _WorldSpaceCameraPos , 0.0 ) , transform223_g3686 ) ) / CrushDistanceViewFalloff ) ) ) : 0.0 );
				#ifdef _USECRUSH_ON
				float staticSwitch163_g3686 = temp_output_235_0_g3686;
				#else
				float staticSwitch163_g3686 = 0.0;
				#endif
				float lerpResult78_g3665 = lerp( lerpResult71_g3665 , _CrushBrightness , staticSwitch163_g3686);
				float lerpResult83_g3665 = lerp( 1.0 , lerpResult78_g3665 , saturate( ( coord_mask88_g3660 * 2.0 ) ));
				float4 appendResult29_g3665 = (float4((saturate( ( temp_output_23_0_g3665 * lerpResult83_g3665 ) )).rgb , (temp_output_23_0_g3665).a));
				float4 temp_output_529_0_g3660 = appendResult29_g3665;
				
				o.Normal = fixed3( 0, 0, 1 );
				o.Occlusion = 1;
				o.Alpha = (temp_output_529_0_g3660).a;
				float AlphaClipThreshold = _AlphaThreshold;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_SHADOW_ON
					if (unity_LightShadowBias.z != 0.0)
						clip(o.Alpha - AlphaClipThresholdShadow);
					#ifdef _ALPHATEST_ON
					else
						clip(o.Alpha - AlphaClipThreshold);
					#endif
				#else
					#ifdef _ALPHATEST_ON
						clip(o.Alpha - AlphaClipThreshold);
					#endif
				#endif

				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif

				#ifdef UNITY_STANDARD_USE_DITHER_MASK
					half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy*0.25,o.Alpha*0.9375)).a;
					clip(alphaRef - 0.01);
				#endif

				#ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
				#endif

				SHADOW_CASTER_FRAGMENT(IN)
			}
			ENDCG
		}
		
	}
	CustomEditor "EoleEditor.EoleShaderGUI"
	
	Fallback Off
}
/*ASEBEGIN
Version=19202
Node;AmplifyShaderEditor.FunctionNode;2399;-1408,0;Inherit;False;Flatten Vertex Normal;3;;2806;89489359c96a5cf41b0229f019cfd1c8;0;0;1;FLOAT3;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2481;-1152,-266;Float;False;False;-1;2;ASEMaterialInspector;0;4;New Amplify Shader;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;ExtraPrePass;0;0;ExtraPrePass;6;False;True;0;1;False;;0;False;;0;1;False;;0;False;;True;0;False;;0;False;;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;False;True;3;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;DisableBatching=False=DisableBatching;True;2;False;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2482;-1152,-266;Float;False;True;-1;2;EoleEditor.EoleShaderGUI;0;4;Eole/Built-In/Grass Advanced Height Position;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;ForwardBase;0;1;ForwardBase;18;False;True;0;1;False;;0;False;;0;1;False;;0;False;;True;0;False;;0;False;;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;2;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;False;True;3;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;DisableBatching=False=DisableBatching;True;2;False;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;40;Workflow,InvertActionOnDeselection;1;0;Surface;0;0;  Blend;0;0;  Refraction Model;0;0;  Dither Shadows;1;0;Two Sided;0;638405744183508071;Deferred Pass;1;0;Transmission;0;0;  Transmission Shadow;0.5,False,;0;Translucency;0;0;  Translucency Strength;1,False,;0;  Normal Distortion;0.5,False,;0;  Scattering;2,False,;0;  Direct;0.9,False,;0;  Ambient;0.1,False,;0;  Shadow;0.5,False,;0;Cast Shadows;1;0;  Use Shadow Threshold;0;0;Receive Shadows;1;0;GPU Instancing;1;0;LOD CrossFade;1;0;Built-in Fog;1;0;Ambient Light;1;0;Meta Pass;1;638406752566013568;Add Pass;1;638406752558680865;Override Baked GI;0;0;Extra Pre Pass;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Fwd Specular Highlights Toggle;0;0;Fwd Reflections Toggle;0;0;Disable Batching;0;0;Vertex Position,InvertActionOnDeselection;1;0;0;6;False;True;True;True;True;True;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2483;-1152,-266;Float;False;False;-1;2;ASEMaterialInspector;0;4;New Amplify Shader;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;ForwardAdd;0;2;ForwardAdd;0;False;True;0;1;False;;0;False;;0;1;False;;0;False;;True;0;False;;0;False;;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;False;True;3;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;DisableBatching=False=DisableBatching;True;2;False;0;False;True;4;1;False;;1;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;True;1;LightMode=ForwardAdd;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2484;-1152,-266;Float;False;False;-1;2;ASEMaterialInspector;0;4;New Amplify Shader;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;Deferred;0;3;Deferred;0;False;True;0;1;False;;0;False;;0;1;False;;0;False;;True;0;False;;0;False;;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;False;True;3;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;DisableBatching=False=DisableBatching;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Deferred;True;2;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2485;-1152,-266;Float;False;False;-1;2;ASEMaterialInspector;0;4;New Amplify Shader;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;Meta;0;4;Meta;0;False;True;0;1;False;;0;False;;0;1;False;;0;False;;True;0;False;;0;False;;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;False;True;3;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;DisableBatching=False=DisableBatching;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2486;-1152,-266;Float;False;False;-1;2;ASEMaterialInspector;0;4;New Amplify Shader;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;ShadowCaster;0;5;ShadowCaster;0;False;True;0;1;False;;0;False;;0;1;False;;0;False;;True;0;False;;0;False;;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;False;True;3;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;DisableBatching=False=DisableBatching;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.FunctionNode;2465;-1553,-271;Inherit;False;Foliage Color & Shading;5;;3660;f4505f717c4abe64b899f0eb94054985;5,360,1,501,0,503,1,148,1,458,2;6;457;FLOAT;0;False;480;FLOAT;0;False;466;FLOAT;0;False;161;FLOAT;0;False;147;FLOAT;1;False;426;FLOAT;0;False;5;FLOAT3;0;FLOAT3;70;FLOAT;251;FLOAT;1;FLOAT;273
Node;AmplifyShaderEditor.FunctionNode;2489;-1872,-80;Inherit;False;Foliage Vertex Offset;37;;3679;0fe3090401650924eb84218df3d02dc9;8,177,2,28,3,435,3,437,3,507,0,117,1,65,1,583,0;3;421;FLOAT;0;False;422;FLOAT3;0,0,0;False;176;FLOAT;1;False;3;FLOAT3;0;FLOAT;61;FLOAT;109
Node;AmplifyShaderEditor.FunctionNode;2490;-2101,-272;Inherit;False;Wind System;0;;3687;04c8c7036a454954194d751ad91ea181;4,171,1,184,0,186,0,140,1;0;4;FLOAT;197;FLOAT;0;FLOAT;139;FLOAT3;24
WireConnection;2482;0;2465;0
WireConnection;2482;1;2465;70
WireConnection;2482;5;2465;251
WireConnection;2482;7;2465;1
WireConnection;2482;8;2465;273
WireConnection;2482;15;2489;0
WireConnection;2482;16;2399;0
WireConnection;2465;457;2490;0
WireConnection;2465;480;2490;139
WireConnection;2465;466;2489;61
WireConnection;2465;161;2489;109
WireConnection;2489;421;2490;0
WireConnection;2489;422;2490;24
ASEEND*/
//CHKSM=00ADE2A2D3EFB520EDAF09ADB0C25D83D9A19C60