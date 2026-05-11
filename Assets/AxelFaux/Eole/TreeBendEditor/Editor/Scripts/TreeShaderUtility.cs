//Eole
//Copyright protected under Unity Asset Store EULA

using UnityEditor;
using UnityEngine;

namespace EoleEditor.TreeBend
{
    public static class TreeShaderUtility
    {
        public static void RenameAsset(Object assetObject, string newName)
        {
            string assetPath = AssetDatabase.GetAssetPath(assetObject);

            if (!string.IsNullOrEmpty(assetPath))
            {
                AssetDatabase.RenameAsset(assetPath, newName);
                AssetDatabase.Refresh();
            }
        }
        public static void DeleteAsset(Object assetObject)
        {
            bool userConfirmed = EditorUtility.DisplayDialog("Confirmation", "Do you really want to delete the setting?", "Yes", "No");

            if (userConfirmed)
            {
                string assetPath = AssetDatabase.GetAssetPath(assetObject);
                AssetDatabase.DeleteAsset(assetPath);
            }
        }
    }
}
