//Eole
//Copyright protected under Unity Asset Store EULA

using Eole;
using UnityEditor;
using UnityEngine;

namespace EoleEditor
{
    public class EoleMenu : Editor
    {
        #region Tool
        [MenuItem("Tools/Eole/Apply All #s")]
        private static void ApplyAll()
        {
            RefreshCrushLayerMasks();
            ApplyGlobalProperties();
        }

        [MenuItem("Tools/Eole/Refresh Crush LayerMasks")]
        private static void RefreshCrushLayerMasks()
        {
            GlobalShaderCrush target = Utility.FindObject<GlobalShaderCrush>();

            if (target != null)
            {
                CrushLayerMaskUtility.ApplyCrusherLayerMasks(target);
            }
            else
            {
                Debug.LogWarning("'RefreshCrushLayerMasks' query canceled. The GlobalShaderCrush type does not exists in your scene(s).");
            }
        }

        [MenuItem("Tools/Eole/Apply Global Registered Properties")]
        private static void ApplyGlobalProperties()
        {
            WindManager eoleManager = Utility.FindObject<WindManager>();

            if (eoleManager != null)
            {
                // Ping the game object as success feedback
                EditorGUIUtility.PingObject(eoleManager.gameObject);

                if (eoleManager.TryGetComponent(out GlobalShaderWind gsw))
                    gsw.ApplyGlobalProperties();
                if (eoleManager.TryGetComponent(out GlobalShaderColorMap gscm))
                    gscm.ApplyGlobalProperties();
                if (eoleManager.TryGetComponent(out GlobalShaderCrush gsc))
                    gsc.ApplyGlobalProperties();

            }
            else
            {
                Debug.LogWarning("'ApplyGlobalProperties' query canceled. The EoleManager type does not exists in your scene(s).");
            }
        }
        #endregion

        #region GameObject/3D Object/Eole

        [MenuItem("GameObject/3D Object/Eole/Eole Manager")]
        private static void InstantiateEoleManager()
        {
            EditorUtils.InstantiatePrefab("EoleManager");
        }

        /*[MenuItem("GameObject/3D Object/Eole/Camera Crush RenderTexture")]
        public static GameObject InstantiateCameraCrushRenderTexture()
        {
            var crushManager = FindObjectOfType<GlobalShaderCrush>(); // temporary solution as it has no other unique component

            Debug.LogWarning("")

            return EditorUtils.InstantiateCameraCrushRenderTexture(crushManager);
        }*/

        [MenuItem("GameObject/3D Object/Eole/Grass Crusher/Static Radial")]
        public static void InstantiateGrassCrusherStaticRadial()
        {
            EditorUtils.InstantiatePrefab("Crusher_StaticRadial");
        }

        [MenuItem("GameObject/3D Object/Eole/Grass Crusher/Static Square")]
        public static void InstantiateGrassCrusherStaticSquare()
        {
            EditorUtils.InstantiatePrefab("Crusher_StaticSquare");
        }

        [MenuItem("GameObject/3D Object/Eole/Grass Crusher/Trail Renderer")]
        public static void InstantiateGrassCrusherTrailRenderer()
        {
            EditorUtils.InstantiatePrefab("Crusher_TrailRenderer");
        }

        [MenuItem("GameObject/3D Object/Eole/Grass Crusher/Dynamic Particle (Visual Effect)")]
        public static void InstantiateGrassCrusherDynamicParticleVFX()
        {
            EditorUtils.InstantiatePrefab("Crusher_VFX_DynamicParticle (VisualEffect)");
        }

        [MenuItem("GameObject/3D Object/Eole/Grass Crusher/Dynamic Particle (Particle System)")]
        public static void InstantiateGrassCrusherDynamicParticleFX()
        {
            EditorUtils.InstantiatePrefab("Crusher_VFX_DynamicParticle (ParticleSystem)");
        }
        #endregion
    }
}