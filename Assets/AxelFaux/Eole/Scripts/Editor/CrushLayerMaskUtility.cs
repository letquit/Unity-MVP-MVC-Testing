using Eole;
using UnityEditor;
using UnityEngine;

namespace EoleEditor
{
    public static class CrushLayerMaskUtility
    {
        /// <summary>
        /// For each crusher type type in the scenes, including the prefabs resources in the project, set their layer mask.
        /// </summary>
        public static void ApplyCrusherLayerMasks(GlobalShaderCrush target)
        {
            if (target.crushLayer.value <= 7 || LayerMask.LayerToName(target.crushLayer.value) == "") // Start from index 8 (layers before that are reserved)
            {
                int newLayerIndex = EditorUtils.AddLayer(); // Return the layer mask if existing, else add a new layer
                if (newLayerIndex <= 7)
                    return;
                else
                    target.crushLayer.value = newLayerIndex; // Set this new layer mask in the manager
            }

            ValidateCrushCameraReference(target);
            SetCameraProperties(target); // Apply the layer mask on the crush camera
            SetCrushersLayerMask(target.crushLayer);
            DisableCullMaskOnMainCamera(target.crushLayer);
        }

        /// <summary>
        /// Disable the crush mask layer from MainCamera culling mask 
        /// </summary>
        private static void DisableCullMaskOnMainCamera(LayerMask crushLayer)
        {
            if (crushLayer.value != 0 && Camera.main != null) // default layerMask value
            {
                Camera.main.cullingMask &= ~(1 << crushLayer.value);

                //int layerIndex = script.crushLayer.value;
                //Debug.Log("The culling mask layer '" + LayerMask.LayerToName(layerIndex) + "' (" + layerIndex + ") has been disabled from the MainCamera.");
            }
        }

        /// <summary>
        /// Get all crushers in actives scene and the prefabs from the project resources, and set their layer mask
        /// </summary>
        private static void SetCrushersLayerMask(LayerMask crushLayer)
        {
            var crushers = Resources.FindObjectsOfTypeAll<Crusher>();

            foreach (var c in crushers)
            {
                c.gameObject.layer = crushLayer.value;
            }

            Debug.Log("Layer Mask '" + LayerMask.LayerToName(crushLayer.value) + "' (" + crushLayer.value + ") applied on " + crushers.Length + " crusher gameObject(s).");
        }

        /// <summary>
        /// Instantiate a crush camera if not existing and referenced. If the reference is not valid (missing a type), it will be replaced by a new one.
        /// </summary>
        private static void ValidateCrushCameraReference(GlobalShaderCrush target)
        {
            // MainCamera is set as reference. Remove it.
            if (target.crushCamera != null && target.crushCamera.tag == "MainCamera")
                target.crushCamera = null;

            // If crush camera is null, find the CameraCrush class
            target.crushCamera ??= Utility.FindObject<CameraCrush>()?.GetComponent<Camera>();

            if (target.crushCamera == null)
            {
                target.crushCamera = EditorUtils.InstantiateCameraCrushRenderTexture()?.GetComponent<Camera>();
                //Debug.Log("No crush camera was referenced in the GlobalShaderCrush, a new one has been instanciated.");
            }

            // Is not a camera inheriting the CameraCrush type
            if (target.crushCamera != null)
            {
                if (!target.crushCamera.TryGetComponent(out CameraCrush cam) || target.crushCamera.tag == "MainCamera")
                {
                    target.crushCamera = EditorUtils.InstantiateCameraCrushRenderTexture()?.GetComponent<Camera>();
                    
                    return;
                }
            }

            // Crush camera missing / not added by the user
            if (target.crushCamera == null)
                Debug.LogWarning("CrushCamera reference is missing. The foliage will not be crushed/bended.", target);

            // Marks object dirty
            if (target.crushCamera != null)
                EditorUtility.SetDirty(target);
        }

        /// <summary>
        /// Set the camera properties used for the crush features, as the culling mask (layer), and its render texture output.
        /// </summary>
        public static void SetCameraProperties(GlobalShaderCrush target)
        {
            if (target.crushCamera == null || target.crushCamera.tag == "MainCamera")
                return;

            // Set the layermask on the crush camera
            int maskToKeep = 1 << target.crushLayer; // Create a mask with only one bit active corresponding to the layer to keep
            int invertedMask = ~maskToKeep; // Invert the bits to disable all other layers
            target.crushCamera.cullingMask = maskToKeep; // Assign the inverted mask to the camera's culling mask

            // Set the render texture as output
            if (target.crushRenderTexture != null)
                target.crushCamera.targetTexture = target.crushRenderTexture;
        }
    }
}