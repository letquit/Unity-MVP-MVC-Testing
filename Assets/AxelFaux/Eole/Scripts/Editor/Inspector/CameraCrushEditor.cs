//Eole
//Copyright protected under Unity Asset Store EULA

using Eole;
using UnityEditor;

namespace EoleEditor
{
    [CustomEditor(typeof(CameraCrush))]
    public class CameraCrushEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            CameraCrush script = (CameraCrush)target;

            if (script == null)
                return;

            EditorGUILayout.HelpBox("This class automatically setup the camera background color depending on the project's color space.", MessageType.None);
        }
    }
}