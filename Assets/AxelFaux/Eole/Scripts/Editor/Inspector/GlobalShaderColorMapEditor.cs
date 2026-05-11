//Eole
//Copyright protected under Unity Asset Store EULA

using Eole;
using UnityEditor;
using UnityEngine;


namespace EoleEditor
{
    [CustomEditor(typeof(GlobalShaderColorMap))]
    public class GlobalShaderColorMapEditor : Editor
    {
        private GlobalShaderColorMap script;

        public override void OnInspectorGUI()
        {
            script = (GlobalShaderColorMap)target;
            EditorUtils.DrawEoleLabelVersion();


            script.colorMapMode = (GlobalShaderColorMap.ColorMapMode)EditorGUILayout.EnumPopup("ColorMap Mode", script.colorMapMode);
            Undo.RecordObject(script, "ColorMap mode");

            EditorGUILayout.Space(20);

            if (script.colorMapMode == GlobalShaderColorMap.ColorMapMode.Terrain)
            {
                #region ColorMapMode Terrain
                EditorGUILayout.HelpBox("Only one Terrain layer is supported for the moment.", MessageType.Info);
                script.terrain = (Terrain)EditorGUILayout.ObjectField("Terrain", script.terrain, typeof(Terrain), true);
                Undo.RecordObject(script, "Terrain reference");

                if (script.terrain != null)
                {
                    // Get layers
                    var layers = script.terrain.terrainData.terrainLayers;

                    string[] layerNames = new string[layers.Length];
                    for (int i = 0; i < layers.Length; i++)
                    {
                        layerNames[i] = layers[i].name;
                    }

                    script.layerIndex = EditorGUILayout.Popup("Terrain Layer Used", script.layerIndex, layerNames);
                    Undo.RecordObject(script, "Terrain layer used");
                }
                else
                    EditorGUILayout.HelpBox("Terrain reference is null.", MessageType.Warning);
                #endregion
            }
            else
            {
                #region ColorMapMode Custom
                script.colorMap = (Texture2D)EditorGUILayout.ObjectField("ColorMap", script.colorMap, typeof(Texture2D), false);
                Undo.RecordObject(script, "ColorMap texture reference");

                script.size = EditorGUILayout.Vector2Field("Size", script.size);
                Undo.RecordObject(script, "ColorMap size");

                script.offset = EditorGUILayout.Vector2Field("Offset", script.offset);
                Undo.RecordObject(script, "ColorMap offset");
                #endregion
            }

            if (GUI.changed || Undo.isProcessing)
            {
                script.ApplyGlobalProperties();

                EditorUtility.SetDirty(script);
                PrefabUtility.RecordPrefabInstancePropertyModifications(script);
            }
        }
    }
}