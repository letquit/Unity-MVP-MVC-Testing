//Eole
//Copyright protected under Unity Asset Store EULA

using Eole.VFX;
using UnityEditor;
using UnityEngine;

namespace EoleEditor
{
    [CustomEditor(typeof(VFXCalculateVelocity))]
    public class VFXCalculateVelocityEditor : Editor
    {
        private VFXCalculateVelocity script;
        public override void OnInspectorGUI()
        {
            //base.OnInspectorGUI();
            EditorUtils.DrawEoleLabelVersion();

            script = (VFXCalculateVelocity)target;

            if (script == null)
                return;

            //EditorGUILayout.HelpBox("For Visual Effect component only", MessageType.None);
            EditorGUILayout.HelpBox("Writes the current velocity of the gameObject in the property 'Velocity' (Vector3) in its Visual Effects component.", MessageType.None);

            script.executeInEditor = EditorGUILayout.Toggle("Execute In Editor", script.executeInEditor);
            Undo.RecordObject(script, "Execute In Editor");


            if (GUI.changed || Undo.isProcessing)
            {
                EditorUtility.SetDirty(script);
                PrefabUtility.RecordPrefabInstancePropertyModifications(script);
            }
        }
    }
}