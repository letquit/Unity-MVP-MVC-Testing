//Eole
//Copyright protected under Unity Asset Store EULA

using Eole;
using Eole.VFX;
using UnityEditor;
using UnityEngine;

namespace EoleEditor
{
    [CustomEditor(typeof(VFXSetWindProperties))]
    public class VFXSetWindPropertiesEditor : Editor
    {
        private VFXSetWindProperties script;

        public override void OnInspectorGUI()
        {
            //base.OnInspectorGUI();
            EditorUtils.DrawEoleLabelVersion();

            script = (VFXSetWindProperties)target;

            if (script == null)
                return;


            script.windManager = EditorGUILayout.ObjectField("Wind Manager", script.windManager, typeof(WindManager), true) as WindManager;
            Undo.RecordObject(script, "Wind Manager reference");

            script.fXType = (VFXSetWindProperties.FXType)EditorGUILayout.EnumPopup("FX Type", script.fXType);
            Undo.RecordObject(script, "FX Type");

            EditorGUILayout.Space(10);

            switch (script.fXType)
            {
                case VFXSetWindProperties.FXType.ParticleSystem:
                    {
                        EditorGUILayout.LabelField("Particle Effect", EditorStyles.boldLabel);

                        script.startSpeed = EditorGUILayout.FloatField("Start Speed", script.startSpeed);
                        Undo.RecordObject(script, "Start Speed");
                        script.rateOverTime = EditorGUILayout.Vector2Field("Rate Over Time", script.rateOverTime);
                        Undo.RecordObject(script, "Rate Over Time (range)");

                        EditorGUILayout.Space(10);
                        EditorGUILayout.LabelField("Force Field", EditorStyles.boldLabel);

                        script.particleSystemForceField = EditorGUILayout.ObjectField("Force Field", script.particleSystemForceField, typeof(ParticleSystemForceField), true) as ParticleSystemForceField;
                        Undo.RecordObject(script, "Force Field reference");
                        script.forceFieldMultiplier = EditorGUILayout.FloatField("Force Multiplier", script.forceFieldMultiplier);
                        Undo.RecordObject(script, "Force Field Multiplier");

                        break;
                    }

                case VFXSetWindProperties.FXType.VisualEffect:
                    {
                        EditorGUILayout.LabelField("Visual Effect", EditorStyles.boldLabel);

                        script.windAmplitude = EditorGUILayout.TextField(new GUIContent("Wind Amplitude", "Enter the name of the property in your visual effect which will be overriden by the WindAmplitude."), script.windAmplitude);
                        Undo.RecordObject(script, "Wind Amplitude VFX property name");
                        script.windSpeed = EditorGUILayout.TextField(new GUIContent("Wind Speed", "Enter the name of the property in your visual effect which will be overriden by the WindSpeed."), script.windSpeed);
                        Undo.RecordObject(script, "Wind Speed VFX property name");
                        script.windDirection = EditorGUILayout.TextField(new GUIContent("Wind Speed", "Enter the name of the property in your visual effect which will be overriden by the WindDirection."), script.windDirection);
                        Undo.RecordObject(script, "Wind Direction VFX property name");

                        break;
                    }
            }

            EditorGUILayout.Space(10);

            script.isUpdatedEachFrame = EditorGUILayout.Toggle("Is Updated Each Frame", script.isUpdatedEachFrame);
            Undo.RecordObject(script, "Is Updated Each Frame");


            if (GUI.changed || Undo.isProcessing)
            {
                EditorUtility.SetDirty(script);
                PrefabUtility.RecordPrefabInstancePropertyModifications(script);
            }
        }
    }
}
