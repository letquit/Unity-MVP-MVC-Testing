//Eole
//Copyright protected under Unity Asset Store EULA

using UnityEngine;

namespace Eole.Shaders
{
    public struct ShaderPropertyID
    {
        // Wind
        static public int WindMap = Shader.PropertyToID("WindMap");
        static public int WindDirection = Shader.PropertyToID("WindDirection");
        static public int WindAngle = Shader.PropertyToID("WindAngle");
        static public int WindOffsetSpeed = Shader.PropertyToID("WindOffsetSpeed");
        static public int WindTillingSize = Shader.PropertyToID("WindTillingSize");
        static public int WindSmoothstep = Shader.PropertyToID("WindSmoothstep");
        static public int WindAmplitude = Shader.PropertyToID("WindAmplitude");

        // Terrain
        static public int ColorMap = Shader.PropertyToID("ColorMap");
        static public int ColorMapTillingSize = Shader.PropertyToID("ColorMapTillingSize");
        static public int ColorMapOffset = Shader.PropertyToID("ColorMapOffset");

        // Air
        static public int AirStrength = Shader.PropertyToID("AirStrength");
        static public int AirMap = Shader.PropertyToID("AirMap");
        static public int AirTillingSize = Shader.PropertyToID("AirTillingSize");
        static public int AirSmoothstep = Shader.PropertyToID("AirSmoothstep");
        static public int AirSpeedMultiplier = Shader.PropertyToID("AirSpeedMultiplier");
        static public int AirRefractionMap = Shader.PropertyToID("AirRefractionMap");
        static public int AirRefractionTillingSize = Shader.PropertyToID("AirRefractionTillingSize");
        static public int AirRefractionStrength = Shader.PropertyToID("AirRefractionStrength");

        // Crush
        static public int CrushRenderTexture = Shader.PropertyToID("CrushRenderTexture");
        static public int CrushBufferSize = Shader.PropertyToID("CrushBufferSize");
        static public int CrushBufferOffset = Shader.PropertyToID("CrushBufferOffset");
        static public int CrushDistanceView = Shader.PropertyToID("CrushDistanceView");
        static public int CrushDistanceViewFalloff = Shader.PropertyToID("CrushDistanceViewFalloff");

        // Debug (Editor only)
        static public int DebugWind = Shader.PropertyToID("DebugWind");
        static public int DebugWindTurbulence = Shader.PropertyToID("DebugWindTurbulence");
        static public int DebugDisableWPO = Shader.PropertyToID("DebugDisableWPO");

        /*// Grass Repulse
        static public int RepulsePosition = Shader.PropertyToID("RepulsePosition");
        static public int RepulseDistanceThreshold = Shader.PropertyToID("RepulseDistanceThreshold");*/
    }
}