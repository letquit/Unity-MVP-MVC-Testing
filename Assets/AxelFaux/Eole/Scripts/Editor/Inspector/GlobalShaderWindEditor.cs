//Eole
//Copyright protected under Unity Asset Store EULA

using Eole;
using UnityEditor;
using UnityEngine;

namespace EoleEditor
{
    [CustomEditor(typeof(GlobalShaderWind))]
    public class GlobalShaderWindEditor : Editor
    {
        private GlobalShaderWind script;
        private bool foldWind = false;
        private bool foldTint = false;

        public override void OnInspectorGUI()
        {
            script = (GlobalShaderWind)target;
            EditorUtils.DrawEoleLabelVersion();

            #region Wind

            if (script.windMap == null)
                EditorGUILayout.HelpBox("WindMap is empty.", MessageType.Warning);

            foldWind = EditorUtils.DrawHeaderFoldout(new GUIContent("Wind", "Global properties to set up the wind mask. This will mostly define how the foliage behaves with vertex position offset."), foldWind, true);

            if (foldWind)
            {
                script.windMap = (Texture)EditorGUILayout.ObjectField("Wind Map", script.windMap, typeof(Texture), false);
                Undo.RecordObject(script, "Wind Map texture reference");
                script.windMapSize = EditorGUILayout.FloatField("Tilling Size", script.windMapSize);
                Undo.RecordObject(script, "Wind Map tilling size");
                script.windSmoothstep = EditorGUILayout.Vector2Field("Smoothstep", script.windSmoothstep);
                Undo.RecordObject(script, "Wind Map smoothstep");

                EditorGUILayout.Space(20);
            }
            #endregion

            #region Air Sheen Tint
            if (script.airMap == null)
                EditorGUILayout.HelpBox("AirMap is empty.", MessageType.Warning);

            foldTint = EditorUtils.DrawHeaderFoldout(new GUIContent("Air Sheen", "This has only an effect on the foliage color. It is a projected texture which represents the wind/air flowing in the foliage."), foldTint, true);

            if (foldTint)
            {
                script.airStrength = EditorGUILayout.Slider("Brightness", script.airStrength, -1f, 1f);
                Undo.RecordObject(script, "Air Sheen brightness");
                script.airMap = (Texture2D)EditorGUILayout.ObjectField("Air Map", script.airMap, typeof(Texture2D), false);
                Undo.RecordObject(script, "Air Sheen Map texture reference");
                script.airTillingSize = EditorGUILayout.Vector2Field("Tilling Size", script.airTillingSize);
                Undo.RecordObject(script, "Air Sheen tilling size");
                script.airSmoothstep = EditorGUILayout.Vector2Field("Smoothstep", script.airSmoothstep);
                Undo.RecordObject(script, "Air Sheen smoothstep");
                script.airSpeedMultiplier = EditorGUILayout.FloatField("Speed Multiplier", script.airSpeedMultiplier);
                Undo.RecordObject(script, "Air Sheen speed multiplier");

                EditorGUILayout.Separator();
                EditorUtils.DrawCustomSeparatorLine();
                EditorGUILayout.Separator();

                script.refractionMap = (Texture2D)EditorGUILayout.ObjectField("Refraction Map", script.refractionMap, typeof(Texture2D), false);
                Undo.RecordObject(script, "Air Sheen refraction map reference");
                script.refractionTillingSize = EditorGUILayout.FloatField("Tilling Size", script.refractionTillingSize);
                Undo.RecordObject(script, "Air Sheen refraction map tilling size");
                script.refractionStrength = EditorGUILayout.Slider("Refraction Strength", script.refractionStrength, 0f, 1f);
                Undo.RecordObject(script, "Air Sheen refraction map strength");

                EditorGUILayout.Separator();
            }
            #endregion


            if (GUI.changed || Undo.isProcessing)
            {
                script.ApplyGlobalProperties();

                EditorUtility.SetDirty(script);
                PrefabUtility.RecordPrefabInstancePropertyModifications(script);
            }
        }
    }
}