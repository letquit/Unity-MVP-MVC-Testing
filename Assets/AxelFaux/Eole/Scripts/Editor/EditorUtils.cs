//Eole
//Copyright protected under Unity Asset Store EULA

using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;


namespace EoleEditor
{
    public static class EditorUtils
    {
        #region EditorGUI : Inspector & ShaderGUI
        public static void DrawEoleLabelVersion()
        {
            GUIStyle centeredStyle = GUI.skin.GetStyle("Label");
            centeredStyle.alignment = TextAnchor.MiddleCenter;
            centeredStyle.fontSize = 10;
            centeredStyle.normal.textColor = Color.gray;

            EditorGUILayout.LabelField("Eole - Version 2.0.0", centeredStyle);
        }

        public static void DrawCustomSeparatorLine()
        {
            Rect lineRect = EditorGUILayout.GetControlRect(false, 1);
            EditorGUI.DrawRect(lineRect, Color.grey);
        }

        // https://github.com/Unity-Technologies/Graphics/blob/d0473769091ff202422ad13b7b764c7b6a7ef0be/com.unity.render-pipelines.core/Editor/CoreEditorUtils.cs#L298C1-L364C10
        public static bool DrawHeaderFoldout(string title, bool state, bool isBoxed = false) { return DrawHeaderFoldout(new GUIContent(title), state, isBoxed); }
        public static bool DrawHeaderFoldout(GUIContent content, bool state, bool isBoxed = false)
        {
            const float height = 20f; //17f;
            var backgroundRect = GUILayoutUtility.GetRect(1f, height);

            var labelRect = backgroundRect;
            labelRect.xMin += 16f;
            labelRect.xMax -= 20f;

            var foldoutRect = backgroundRect;
            foldoutRect.y += height / 4 - 1; // Approximated centered      //foldoutRect.y += 1f;
            foldoutRect.width = 13f;
            foldoutRect.height = 13f;
            foldoutRect.x = labelRect.xMin + 15 * (EditorGUI.indentLevel - 1); //fix for presset

            // Background rect should be full-width
            backgroundRect.xMin = 0f;
            backgroundRect.width += 4f;

            if (isBoxed)
            {
                labelRect.xMin += 5;
                foldoutRect.xMin += 5;
                backgroundRect.xMin = EditorGUIUtility.singleLineHeight;
                backgroundRect.width -= 1;
            }

            // Background
            float backgroundTint = EditorGUIUtility.isProSkin ? 0.1f : 1f;
            EditorGUI.DrawRect(backgroundRect, new Color(backgroundTint, backgroundTint, backgroundTint, 0.2f));

            // Title
            GUIStyle customStyle = new GUIStyle(EditorStyles.boldLabel);
            //customStyle.fontSize = 14; // Custom font size
            EditorGUI.LabelField(labelRect, content, customStyle);

            // Active checkbox
            state = GUI.Toggle(foldoutRect, state, GUIContent.none, EditorStyles.foldout);

            var e = Event.current;
            if (e.type == EventType.MouseDown && backgroundRect.Contains(e.mousePosition) && /*!moreOptionsRect.Contains(e.mousePosition) &&*/ e.button == 0)
            {
                state = !state;
                e.Use();
            }

            return state;
        }
        #endregion

        #region ShaderGUI only
        public static bool TryGetMaterialProperty(string name, MaterialProperty[] propertiesPool, out MaterialProperty property)
        {
            property = GetMaterialProperty(name, propertiesPool);

            if (property == null)
                return false;
            else
                return true;
        }
        public static MaterialProperty[] GetMaterialProperties(string[] propertyNames, MaterialProperty[] propertiesPool)
        {
            List<MaterialProperty> propertyList = new();
            foreach (var name in propertyNames)
            {
                if (TryGetMaterialProperty(name, propertiesPool, out MaterialProperty property))
                {
                    propertyList.Add(property);
                }
            }

            return propertyList.ToArray();
        }
        public static MaterialProperty GetMaterialProperty(string name, MaterialProperty[] propertiesPool)
        {
            foreach (var prop in propertiesPool)
                if (prop.name == name)
                {
                    return prop;
                }

            // Debug.LogWarning("The property '" + name + "' does not exist.");

            return null;
        }

        /// <summary>
        /// Return true if existing AND enabled, otherwise it will return false.
        /// </summary>
        /// <param name="material"></param>
        /// <param name="keyword"></param>
        /// <returns></returns>
        public static bool HasKeyword(Material material, string keyword)
        {
            foreach (var k in material.enabledKeywords)
            {
                if (keyword == k.ToString())
                    return true;
            }
            return false;
        }
        #endregion

        /// <summary>
        /// Create a new layer 'GrassCrusher' if not existing in the TagManager at the available index.
        /// </summary>
        /// <returns></returns>
        public static int AddLayer()
        {
            SerializedObject tagManager = new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/TagManager.asset")[0]);
            SerializedProperty layers = tagManager.FindProperty("layers");

            string newLayerName = "GrassCrusher";
            int newLayerIndex = -1;

            // Check if "GrassCrusher" layer already exists
            for (int i = 8; i < layers.arraySize; i++) // Start from index 8 (layers before that are reserved)
            {
                SerializedProperty layer = layers.GetArrayElementAtIndex(i);
                if (layer.stringValue == newLayerName)
                {
                    //Debug.Log("Layer 'GrassCrusher' already exists.");
                    return i;
                }

                if (layer.stringValue == "")
                {
                    // Array element available, use this index to create a new one.
                    newLayerIndex = i;
                    break;
                }
            }

            if (newLayerIndex == -1)
            {
                Debug.LogWarning("No available layer slots. Please make sure you have free layer slots.");
                return -1;
            }

            // Add "GrassCrusher" layer
            layers.GetArrayElementAtIndex(newLayerIndex).stringValue = newLayerName;
            tagManager.ApplyModifiedProperties();

            Debug.Log("Layer 'GrassCrusher' added at index: " + newLayerIndex);

            return newLayerIndex;
        }


        /// <summary>
        /// Use FindObjectOfType to pass the argument. If null, it will instantiate the prefab.
        /// </summary>
        /// <returns></returns>
        public static GameObject InstantiateCameraCrushRenderTexture(bool useDialog = true)
        {
            // Popup to create a new camera

            bool b = useDialog ? EditorUtility.DisplayDialog("Crush Camera reference error", "EoleManager > GlobalShaderCrush component requires a specific 'Crush Camera'.\nCreate a new one?", "Yes", "No") : true;

            if (b)
                return InstantiatePrefab("CameraCrushRenderTexture");
            else
                return null;
        }

        public static GameObject InstantiatePrefab(string path)
        {
            var obj = Resources.Load<GameObject>("Prefabs/" + path);

            if (obj != null)
            {
                GameObject clone = (GameObject)PrefabUtility.InstantiatePrefab(obj);
                Selection.activeObject = clone;

                // Get scene camera position
                Camera sceneCamera = SceneView.lastActiveSceneView.camera;
                Vector3 cameraPosition = sceneCamera.transform.position;
                Vector3 cameraForward = sceneCamera.transform.forward;

                // Calculate position in front of the camera
                Vector3 spawnPosition = cameraPosition + cameraForward * 5f; // Move 5 units forward

                clone.transform.position = spawnPosition;

                return clone;
            }
            else
            {
                Debug.LogWarning("The prefab '" + path + "' is not existing at this path: Resources/Prefabs/" + path);
                return null;
            }
        }
    }

    static class ToolbarUtility
    {
        public static Texture2D GetIcon(string fileName)
        {
            string guid = GetFilePath(fileName);
            if (guid != "")
                return AssetDatabase.LoadAssetAtPath<Texture2D>(guid);

            return null;
        }

        public static string GetFilePath(string fileName)
        {
            string[] guids = AssetDatabase.FindAssets(fileName);
            //sring path = AssetDatabase.GUIDToAssetPath(guids[0]);

            // Get the file at the right index
            foreach (string guid in guids)
            {
                string path = AssetDatabase.GUIDToAssetPath(guid);

                if (Path.GetFileNameWithoutExtension(path) == fileName)
                    return path; // File found
            }

            return "";
        }
    }
}