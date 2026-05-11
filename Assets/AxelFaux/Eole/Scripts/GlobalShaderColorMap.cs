//Eole
//Copyright protected under Unity Asset Store EULA

using Eole.Shaders;
using UnityEngine;

namespace Eole
{
    [ExecuteAlways]
    public class GlobalShaderColorMap : MonoBehaviour
    {
        #region Properties
        public ColorMapMode colorMapMode = ColorMapMode.Terrain;
        public Terrain terrain;
        public int layerIndex; // Temporary. To do : allow blend with multiple layers
        public Texture2D colorMap;
        public Vector2 size = Vector2.one;
        public Vector2 offset = Vector2.zero;
        #endregion

        public enum ColorMapMode
        {
            Custom,
            Terrain
        }

        private void Awake()
        {
            ApplyGlobalProperties();
        }

        public void ApplyGlobalProperties() { ApplyGlobalProperties(false); } // To be able to call it from SendMessage function
        public void ApplyGlobalProperties(bool debugIfSuccess = false)
        {
#if UNITY_EDITOR
            if (!Utility.IsSceneValid(gameObject))
                return;
#endif

            if (colorMapMode == ColorMapMode.Terrain)
            {
                // Try get Terrain reference automatically if Terrain is null
                terrain ??= Utility.FindObject<Terrain>();

                if (terrain == null)
                {
                    Debug.LogWarning("Eole GlobalShaderColorMap: Global properties not applied. A Terrain reference is missing.", this);
                    return;
                }

                // Get properties from Terrain data
                if (terrain.terrainData.terrainLayers.Length > 0)
                {
                    var layer = terrain.terrainData.terrainLayers[layerIndex];

                    colorMap = layer.diffuseTexture;
                    offset = layer.tileOffset - new Vector2(terrain.transform.position.x, terrain.transform.position.z);
                    size = layer.tileSize;
                }
            }

            Shader.SetGlobalTexture(ShaderPropertyID.ColorMap, colorMap);
            Shader.SetGlobalVector(ShaderPropertyID.ColorMapOffset, offset);
            Shader.SetGlobalVector(ShaderPropertyID.ColorMapTillingSize, size);


            if (colorMap != null)
            {
                Shader.SetGlobalTexture(ShaderPropertyID.ColorMap, colorMap);

                if (debugIfSuccess)
                    Debug.Log("Global property applied.", this);
            }
            else
            {
                if (colorMapMode == ColorMapMode.Custom)
                    Debug.LogWarning("ColorMap is not set.", this);
                else if (colorMapMode == ColorMapMode.Terrain)
                    Debug.LogWarning("ColorMap is not set, as the selected diffuse map's Terrain layer is empty.", this);
            }
                
        }
    }
}