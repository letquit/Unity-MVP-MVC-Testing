//Eole
//Copyright protected under Unity Asset Store EULA

using Eole;
using UnityEditor;

namespace EoleEditor
{
    [CustomEditor(typeof(Crusher))]
    public class CrusherEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            Crusher script = (Crusher)target;

            if (script == null)
                return;

            EditorGUILayout.HelpBox("This class only allows to automate the crushers initilization in EoleManager.", MessageType.None);
        }
    }
}