//Eole
//Copyright protected under Unity Asset Store EULA

using Eole.Shaders;
using UnityEngine;
using UnityEngine.SocialPlatforms;

namespace Eole
{
    [ExecuteAlways]
    public class GlobalShaderCrush : MonoBehaviour
    {
        public LayerMask crushLayer = 8;
        public Camera crushCamera;
        public RenderTexture crushRenderTexture;
        public bool updateBufferPosition = true; // update each frame

        // Distance view threshold
        public float distanceViewThreshold = 20f;
        public float distanceViewFalloff = 5f;

        [SerializeField, HideInInspector] private RenderTexture bgRenderTexture;

        private void Awake()
        {
            if (bgRenderTexture == null)
            {
                CreateCustomRenderTexture();
            }

            ApplyGlobalProperties();
        }

        private void Update()
        {
            if (updateBufferPosition)
                ApplyBufferPosition();

            ApplyRenderTexture();
        }

        public void ApplyGlobalProperties() { ApplyGlobalProperties(false); } // To be able to call it from SendMessage function
        public void ApplyGlobalProperties(bool debugIfSuccess)
        {
#if UNITY_EDITOR
            if (!Utility.IsSceneValid(gameObject))
                return;
#endif

            if (crushCamera != null && IsValidCamera())
            {
                Shader.SetGlobalFloat(ShaderPropertyID.CrushBufferSize, crushCamera.orthographicSize * 2); //, crushBufferSize * 2

                ApplyBufferPosition();
            }

            ApplyRenderTexture();

            // Debug info
            if (crushRenderTexture != null)
            {
                if (debugIfSuccess)
                    Debug.Log(this + "Global property applied.");
            }
            else
                Debug.LogWarning(this + " CrushRenderTexture is not set.");

            // Distance view
            Shader.SetGlobalFloat(ShaderPropertyID.CrushDistanceView, distanceViewThreshold);
            Shader.SetGlobalFloat(ShaderPropertyID.CrushDistanceViewFalloff, distanceViewFalloff);
        }

        private void ApplyRenderTexture()
        {
            if (crushRenderTexture != null && IsValidCamera())
                Shader.SetGlobalTexture(ShaderPropertyID.CrushRenderTexture, crushRenderTexture);
            else
                Shader.SetGlobalTexture(ShaderPropertyID.CrushRenderTexture, bgRenderTexture);
        }

        public void ApplyBufferPosition()
        {
            if (!IsValidCamera())
                return;

            Vector2 bufferOffset = new Vector2(crushCamera.transform.position.x, crushCamera.transform.position.z);
            Shader.SetGlobalVector(ShaderPropertyID.CrushBufferOffset, bufferOffset);
        }

        private void CreateCustomRenderTexture()
        {
            bgRenderTexture = new CustomRenderTexture(2, 2);
            bgRenderTexture.dimension = UnityEngine.Rendering.TextureDimension.Tex2D;
            bgRenderTexture.format = RenderTextureFormat.Default;
            bgRenderTexture.wrapMode = TextureWrapMode.Clamp;

            // Apply custom color as default
            Shader shad = Shader.Find("Unlit/Color");

            if (shad == null)
            {
                Debug.LogWarning("Eole GlobalShaderCrush: The CrushCamera property is null and the manager couldn't create a default render texture with the Unlit/Color shader. The RenderTexture is null, resulting some foliages should be entirely crushed if the feature is used.", this);
                return;
            }

            Material mat = new Material(shad);

            if (QualitySettings.activeColorSpace == ColorSpace.Gamma)
                mat.color = new Color(0.5f, 0.5f, 0, 1); // Gamma color space
            else
                mat.color = new Color(0.7225f, 0.7225f, 0, 1); // Linear color space

            Graphics.Blit(null, bgRenderTexture, mat);
        }


        /// <summary>
        /// Return true if the crush camera reference is not null and is not the MainCamera.
        /// </summary>
        /// <returns></returns>
        private bool IsValidCamera()
        {
            if (crushCamera != null && crushCamera.tag != "MainCamera")
                return true;
            else
                return false;
        }
    }
}
