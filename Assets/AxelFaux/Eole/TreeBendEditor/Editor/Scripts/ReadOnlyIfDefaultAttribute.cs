//Eole
//Copyright protected under Unity Asset Store EULA

using UnityEditor;
using UnityEngine;

namespace EoleEditor.TreeBend
{
    public class ReadOnlyIfDefaultAttribute : PropertyAttribute { }

    [CustomPropertyDrawer(typeof(ReadOnlyIfDefaultAttribute))]
    public class ReadOnlyDrawer : PropertyDrawer
    {
        public override float GetPropertyHeight(SerializedProperty property, GUIContent label)
        {
            return EditorGUI.GetPropertyHeight(property, label, true);
        }

        public override void OnGUI(Rect position, SerializedProperty property, GUIContent label)
        {
            GUI.enabled = false;
            EditorGUI.PropertyField(position, property, label, true);
            GUI.enabled = true;
        }
    }
}