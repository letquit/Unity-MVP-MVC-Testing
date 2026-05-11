//Eole
//Copyright protected under Unity Asset Store EULA

using Eole;
using UnityEditor;
using UnityEngine;

namespace EoleEditor
{
    [CustomEditor(typeof(GlobalShaderCrush))]
    public class GlobalShaderCrushEditor : Editor
    {
        private GlobalShaderCrush script;

        private void OnValidate()
        {
            if (script != null)
                script.ApplyGlobalProperties();
        }

        public override void OnInspectorGUI()
        {
            script = (GlobalShaderCrush)target;
            EditorUtils.DrawEoleLabelVersion();


            // Button apply layer
            GUIContent applyLayerGUI = new GUIContent("Apply LayerMasks", "Apply the layer mask to each Crusher types (prefabs resources included). CameraCrush will render only this layer, and the MainCamera will not render anymore this layer.");
            if (GUILayout.Button(applyLayerGUI, GUILayout.Height(30)) || LayerMask.LayerToName(script.crushLayer) == "") // If press button, or the layer mask has been lost / empty
            {
                CrushLayerMaskUtility.ApplyCrusherLayerMasks(script);
            }

            EditorGUILayout.Separator();

            // Layer field
            script.crushLayer = EditorGUILayout.LayerField("Crush Layer", script.crushLayer);
            Undo.RecordObject(script, "Crush LayerMask");

            if (script.crushLayer <= 7)
            {
                EditorGUILayout.HelpBox("The crush camera should render a custom layer above index 7.", MessageType.Warning);
            }

            EditorGUILayout.Separator();

            #region Camera field
            script.crushCamera = EditorGUILayout.ObjectField("Crush Camera", script.crushCamera, typeof(Camera), true) as Camera;
            Undo.RecordObject(script, "Crush Camera reference");

            if (script.crushCamera == null || script.crushCamera.tag == "MainCamera")
            {
                EditorGUILayout.HelpBox("CrushCamera needs a valid reference. Press 'Add a CrushCamera' button to fix this issue.", MessageType.Warning);
                if (GUILayout.Button("Add a CrushCamera", GUILayout.Height(30)))
                {
                    var temp = Utility.FindObject<CameraCrush>();

                    if (temp == null)
                        script.crushCamera = EditorUtils.InstantiateCameraCrushRenderTexture(false)?.GetComponent<Camera>();
                    else
                        script.crushCamera = temp.GetComponent<Camera>();

                    // Apply background color based on current color space
                    if (script.crushCamera != null)
                        if (script.crushCamera.TryGetComponent(out CameraCrush component))
                            component.SetBackgroundColor();
                }
            }
            else
            {
                if (script.crushCamera.tag == "MainCamera")
                {
                    EditorGUILayout.HelpBox("Misuse camera reference. Do not use your main camera as the crush camera. Press 'Add a CrushCamera' button to fix this issue.", MessageType.Error);
                }
            }
            #endregion

            #region Render texture field
            script.crushRenderTexture = EditorGUILayout.ObjectField("Render Texture", script.crushRenderTexture, typeof(RenderTexture), false) as RenderTexture;

            if (script.crushRenderTexture == null)
            {
                EditorGUILayout.HelpBox("RenderTexture needs a reference. You can use RT_Crush from the given resources.", MessageType.Warning);
            }
            #endregion

            // Toggle field
            script.updateBufferPosition = EditorGUILayout.Toggle("Update Position In Game", script.updateBufferPosition);
            Undo.RecordObject(script, "Update Position In Game");

            #region Distance view threshold
            // Header
            EditorGUILayout.Separator();
            EditorGUILayout.LabelField("Distance View Threshold", EditorStyles.boldLabel);

            script.distanceViewThreshold = EditorGUILayout.FloatField("Distance", script.distanceViewThreshold);
            script.distanceViewFalloff = EditorGUILayout.Slider("Falloff", script.distanceViewFalloff, 1, 100);
            #endregion


            if (GUI.changed || Undo.isProcessing)
            {
                script.ApplyGlobalProperties();
                CrushLayerMaskUtility.SetCameraProperties(script);

                EditorUtility.SetDirty(script);
                PrefabUtility.RecordPrefabInstancePropertyModifications(script);
            }
        }
    }
}