//Eole
//Copyright protected under Unity Asset Store EULA

using Eole;
using UnityEditor;
using UnityEngine;


namespace EoleEditor
{
    [CustomEditor(typeof(WindManager))]
    public class WindManagerEditor : Editor
    {
        WindManager script;
        private Vector3 oldEulerAngles; // store the eulerAngles to refresh after each modification

        public override void OnInspectorGUI()
        {
            script = (WindManager)target;
            EditorUtils.DrawEoleLabelVersion();

            EditorGUI.BeginChangeCheck();

            script.windSource = (WindSource)EditorGUILayout.EnumPopup("Wind Source", script.windSource);
            Undo.RecordObject(script, "Wind source mode");

            EditorGUILayout.Separator();

            if (script.windSource == WindSource.Custom)
            {
                script.amplitude = EditorGUILayout.Slider("Amplitude", script.GetAmplitude(), 0f, 1f);
                Undo.RecordObject(script, "Wind amplitude");

                script.speed = EditorGUILayout.FloatField("Speed", script.GetSpeed());
                Undo.RecordObject(script, "Wind speed");
            }
            else if (script.windSource == WindSource.WindZone)
            {
                // Button apply modifications
                GUIContent gui_applyModification = new GUIContent("Apply Modifications", "Apply the modification done on the WindZone (rotation, amplitude...).");
                if (GUILayout.Button(gui_applyModification, GUILayout.Height(30)))
                {
                    script.ApplyModification();
                }

                script.windZone = (WindZone)EditorGUILayout.ObjectField("Wind Zone", script.windZone, typeof(WindZone), true);
                Undo.RecordObject(script, "WindZone reference");

                script.windStrengthMultiplier = EditorGUILayout.FloatField("Main Multiplier (Amplitude)", script.windStrengthMultiplier);
                Undo.RecordObject(script, "Wind Main Multiplier (Amplitude)");

                script.windSpeedMultiplier = EditorGUILayout.FloatField("Turbulence Multiplier (Speed)", script.windSpeedMultiplier);
                Undo.RecordObject(script, "Wind Turbulence Multiplier (Speed)");
            }

            EditorGUILayout.Separator();

            string infoWindData = "Amplitude: " + script.GetAmplitude() + "\n" +
                "Speed: " + script.GetSpeed() + "\n" +
                "Normalized Direction: " + script.GetDirection();
            EditorGUILayout.HelpBox(infoWindData, MessageType.None);

            // Check if transform eulerAngles has been modified
            if (script.transform.eulerAngles != oldEulerAngles)
            {
                oldEulerAngles = script.transform.eulerAngles;
                script.ApplyModification();
            }

            if (GUI.changed || Undo.isProcessing)
            {
                script.ApplyModification();

                EditorUtility.SetDirty(script);
                PrefabUtility.RecordPrefabInstancePropertyModifications(script);
            }
        }
    }
}