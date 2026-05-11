//Eole
//Copyright protected under Unity Asset Store EULA

using Eole.Shaders;
using UnityEngine;
using System;

namespace Eole
{
    [RequireComponent(typeof(WindManager))]
    [ExecuteAlways] // Execute at Awake to force the update while Unity start
    public class GlobalShaderWind : MonoBehaviour
    {
        public WindManager windManager;
        public WindZone windZone;

        #region Main Wind Properties
        [Header("Main Wind Data")]
        public Texture windMap;
        public float windMapSize = 35f;
        public Vector2 windSmoothstep = new Vector2(-0.3f, 1f);
        #endregion
        #region Air Tint Properties
        [Header("Air Tint")]
        [Range(-1, 1)] public float airStrength = 0.15f;
        public Texture2D airMap;
        public Vector2 airTillingSize = new Vector2(5f, 20f);
        public Vector2 airSmoothstep = new Vector2(0.2f, 1f);
        public float airSpeedMultiplier = 1f;
        public Texture2D refractionMap;
        public float refractionTillingSize = 30f;
        public float refractionStrength = 0.2f;
        #endregion


        private void Awake()
        {
            // If null, get WindManager reference
            windManager ??= Utility.FindObject<WindManager>();

            ApplyGlobalProperties();
        }

        public void ApplyGlobalProperties() { ApplyGlobalProperties(false); } // To be able to call it from SendMessage function
        public void ApplyGlobalProperties(bool debugLog = false)
        {
#if UNITY_EDITOR
            if (!Utility.IsSceneValid(gameObject))
                return;
#endif

            ApplyGlobalPropertiesWind();
            ApplyGlobalPropertiesAir();

            if (debugLog)
                Debug.Log(this + "Global shader properties applied.");
        }

        public void ApplyGlobalPropertiesWind()
        {
#if UNITY_EDITOR
            if (!Utility.IsSceneValid(gameObject))
                return;
#endif

            windManager ??= Utility.FindObject<WindManager>();
            if (windManager == null)
                return;

            // Main wind data
            Shader.SetGlobalFloat(ShaderPropertyID.WindAmplitude, windManager.GetAmplitude());
            Shader.SetGlobalFloat(ShaderPropertyID.WindOffsetSpeed, windManager.GetSpeed());
            Shader.SetGlobalFloat(ShaderPropertyID.WindAngle, windManager.GetAngleInRadian()); // Convert in radian
            Shader.SetGlobalVector(ShaderPropertyID.WindDirection, windManager.GetDirection());

            // Tex
            Shader.SetGlobalTexture(ShaderPropertyID.WindMap, windMap);
            // Float
            Shader.SetGlobalFloat(ShaderPropertyID.WindTillingSize, windMapSize);
            // Vector

            Shader.SetGlobalVector(ShaderPropertyID.WindSmoothstep, windSmoothstep);
        }

        public void ApplyGlobalPropertiesAir()
        {
            Shader.SetGlobalTexture(ShaderPropertyID.AirMap, airMap);
            Shader.SetGlobalVector(ShaderPropertyID.AirTillingSize, airTillingSize);
            Shader.SetGlobalVector(ShaderPropertyID.AirSmoothstep, airSmoothstep);
            Shader.SetGlobalFloat(ShaderPropertyID.AirSpeedMultiplier, airSpeedMultiplier);
            Shader.SetGlobalFloat(ShaderPropertyID.AirStrength, airStrength);

            Shader.SetGlobalTexture(ShaderPropertyID.AirRefractionMap, refractionMap);
            Shader.SetGlobalFloat(ShaderPropertyID.AirRefractionStrength, refractionStrength);
            Shader.SetGlobalFloat(ShaderPropertyID.AirRefractionTillingSize, refractionTillingSize);

        }
    }
}