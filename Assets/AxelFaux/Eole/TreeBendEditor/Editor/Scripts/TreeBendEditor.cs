//Eole
//Copyright protected under Unity Asset Store EULA

using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace EoleEditor.TreeBend
{
    public class TreeBendEditor : EditorWindow
    {
        #region Properties
        GameObject[] selectedObjects;
        TreeBendWindowSettings windowSettings;
        TreeBendShaderSettings currentTreeSettings;
        TreeBendShaderSettings[] arTreeSettings;

        // Enum utility
        string[] settingsEnum;
        string selectedSettings = "Default";
        string previousSelectedSettings;
        int selectedSettingsIndex;


        bool displayInfo = false;
        bool displaySettings = false;
        bool autoApply = false; // automatically apply changes to materials
        string settingRename;

        Vector2 scrollPosition;
        #endregion

        [MenuItem("Tools/Eole/Tree Bend Editor", false, 1)]
        public static void ShowWindow()
        {
            EditorWindow.GetWindow<TreeBendEditor>();
        }

        private void OnEnable()
        {
            LoadWindowSettings();
            FindShaderSettings();
        }

        #region Init
        private void LoadWindowSettings()
        {
            // Window Settings
            if (windowSettings == null)
            {
                var guid = AssetDatabase.FindAssets("t:TreeBendWindowSettings")[0];
                if (guid != null)
                {
                    var path = AssetDatabase.GUIDToAssetPath(guid);
                    windowSettings = AssetDatabase.LoadAssetAtPath<TreeBendWindowSettings>(path);
                }
                else
                {
                    windowSettings = CreateNewScriptableObject<TreeBendWindowSettings>(subFolderLocation: "/Editor/Configs/WindowSettings/", fileName: "TreeBendWindowSettings.asset");
                }
            }

            // Init dictionnary settings
            if (windowSettings != null)
            {
                if (windowSettings.DictionnarySettings != null)
                {
                    if (windowSettings.DictionnarySettings.Count == 0) // first init only
                        windowSettings.Init(arTreeSettings);
                    if (windowSettings.DictionnarySettings.Count > 0) // refresh array
                        windowSettings.Refresh();
                }
            }
        }
        /// <summary>
        ///  Generate the array of TreeBendShaderSettings by finding all the assets in the project.
        /// </summary>
        private void FindShaderSettings()
        {
            // Shader Settings
            var guids = AssetDatabase.FindAssets("t:TreeBendShaderSettings");
            List<TreeBendShaderSettings> settings = new();

            foreach (var guid in guids)
            {
                var path = AssetDatabase.GUIDToAssetPath(guid);
                settings.Add(AssetDatabase.LoadAssetAtPath<TreeBendShaderSettings>(path));
            }

            arTreeSettings = settings.ToArray();
        }
        /// <summary>
        /// Select a valid setting if value is null
        /// </summary>
        private void SelectSettings()
        {
            if (!IsSettingsArrayValid())
                return;

            if (currentTreeSettings == null)
            {
                foreach (var t in arTreeSettings)
                {
                    if (selectedSettings == null)
                        selectedSettings = "Default";

                    if (t.GetSettingName() == selectedSettings)
                    {
                        currentTreeSettings = t;
                        break;
                    }
                }
            }
        }
        #endregion


        public void OnGUI()
        {
            FindShaderSettings();
            SelectSettings();

            DrawHeader();

            if (windowSettings == null)
                return;

            if (!IsSettingsArrayValid())
                return;

            RefreshSettingsEnum();

            EditorGUI.BeginChangeCheck();

            selectedObjects = Selection.gameObjects;

            // TOP MAIN BUTTONS
            EditorGUILayout.BeginHorizontal();
            GUILayout.FlexibleSpace(); // BeginCenter

            if (Btn_GetTreeMaterials())
            {
                EditorGUILayout.EndHorizontal(); // Fix error GUI layout
                return;
            }

            // Info button
            if (GUILayout.Button("?", GUILayout.Width(25), GUILayout.Height(25)))
                displayInfo = !displayInfo;

            GUILayout.FlexibleSpace(); // EndCenter
            EditorGUILayout.EndHorizontal();

            if (displayInfo)
                EditorGUILayout.HelpBox("This tool is made to help you modifying the trees Materials at once. You can change their behaviour, based on multiple properties, from different and customizable settings " +
                    "(each part of the tree should have the same settings/properties value to be synchronized).", MessageType.Info);

            //GUILayout.Label("Selected gameObject(s): " + selectedObjects.Length);
            EditorGUILayout.Separator();

            // BEGIN SCROLL VIEW
            scrollPosition = EditorGUILayout.BeginScrollView(scrollPosition, GUILayout.Width(position.width), GUILayout.Height(position.height - 100));

            // MATERIAL LIST
            CentererLabel("MATERIALS", 12);
            DrawMaterialsList();
            EditorGUILayout.Separator();

            // PROPERTIES
            CentererLabel("SHADER PROPERTIES", 12);

            displaySettings = false; // Init

            // Centered button "Start Override"
            if (windowSettings.GetCommonMaterialsGuid() == -1)
            {
                EditorGUILayout.BeginHorizontal();
                GUILayout.FlexibleSpace();

                // Display Override button
                if (IsMaterialsHaveValidElement())
                {
                    if (GUILayout.Button("Start Override", GUILayout.Width(160)))
                        SetMaterialProperties(); // Override properties with a setting
                }

                GUILayout.FlexibleSpace();
                EditorGUILayout.EndHorizontal();
            }

            if (IsMaterialsHaveValidElement())
            {
                // All materials don't have the same guid / shader settings
                if (windowSettings.GetCommonMaterialsGuid() == -1)
                {
                    displaySettings = false;

                    EditorGUILayout.HelpBox("No settings found on the material(s), or all materials don't share the same TreeBend setting!" +
                        "\n\nClick on a button to start editing.\n" +
                        "\t'+' to create a setting with the material values.\n" +
                        "\t'#' to override all material with the existing setting.", MessageType.Info);
                }
                else
                    displaySettings = true;
            }

            if (displaySettings)
            {
                // HORIZONTAL Settings and buttons
                EditorGUILayout.BeginHorizontal();

                selectedSettingsIndex = Mathf.Clamp(EditorGUILayout.Popup("Settings", System.Array.IndexOf(settingsEnum, selectedSettings), settingsEnum), 0, int.MaxValue);

                // BUTTON New Settings
                if (GUILayout.Button("New", GUILayout.Width(40f)))
                    NewSettings();

                if (Btn_DeleteSettings())
                {
                    // fix "invalid GUI layout" error
                    EditorGUILayout.EndHorizontal();
                    EditorGUILayout.EndScrollView();

                    return;
                }

                EditorGUILayout.EndHorizontal();

                RefreshSelectedSettings();

                if (currentTreeSettings == null)
                    return;

                DrawRenameField();
                EditorGUILayout.Separator();
                DrawProperties();

                // Apply / Auto apply
                EditorGUILayout.Separator();
                EditorGUILayout.BeginHorizontal();
                GUILayout.FlexibleSpace();

                autoApply = EditorGUILayout.Toggle(autoApply, GUILayout.Width(20));

                EditorGUILayout.LabelField("Auto Apply", GUILayout.Width(70));
                EditorGUI.BeginDisabledGroup(autoApply);

                if (GUILayout.Button("Apply to materials", GUILayout.Width(150)))
                {
                    SetMaterialProperties();

                    // Fix error GUI Layout
                    EditorGUI.EndDisabledGroup();
                    EditorGUILayout.EndHorizontal();
                    EditorGUILayout.EndScrollView();
                    return;
                }

                EditorGUI.EndDisabledGroup();
                EditorGUILayout.EndHorizontal();
                EditorGUILayout.Space(20);

                Btn_SetDefaultValue();
            }

            // END SCROLL VIEW
            EditorGUILayout.EndScrollView();

            if (GUI.changed || Undo.isProcessing)
            {
                if (displaySettings && autoApply)
                    SetMaterialProperties();

                if (windowSettings.Materials != null & windowSettings.Materials.Count > 0)
                    foreach (var mat in windowSettings.Materials)
                    {
                        if (mat != null)
                            EditorUtility.SetDirty(mat);
                    }

                EditorUtility.SetDirty(windowSettings);
            }
        }

        private void SetMaterialProperties()
        {
            if (currentTreeSettings == null)
            {
                Debug.LogWarning("Current tree settings is null.", this);
                return;
            }

            foreach (var mat in windowSettings.Materials)
            {
                if (IsTreeMaterial(mat))
                {
                    mat.SetFloat("_UseTreeBend", windowSettings.GetShaderSettingsGuid(currentTreeSettings));
                    mat.SetFloat("_TreeBendMaskDistanceOffset", currentTreeSettings.treeBendProperties.MaskDistanceOffset);
                    mat.SetFloat("_TreeBendMaskFalloff", currentTreeSettings.treeBendProperties.MaskFalloff);
                    mat.SetFloat("_TreeBendFrequency", currentTreeSettings.treeBendProperties.Frequency);
                    mat.SetFloat("_TreeBendFrequencySpeed", currentTreeSettings.treeBendProperties.FrequencySpeed);
                    mat.SetFloat("_TreeBendFrequencyOffsetRandomn", currentTreeSettings.treeBendProperties.FrequencyRandom);
                    mat.SetFloat("_TreeBendMinAngle", (float)(currentTreeSettings.treeBendProperties.BendMinAngle * (Math.PI / 180)));
                    mat.SetFloat("_TreeBendMaxAngle", (float)(currentTreeSettings.treeBendProperties.BendMaxAngle * (Math.PI / 180)));
                }
            }
        }

        private void RefreshSettingsEnum()
        {
            // Init available options
            List<string> settings = new List<string>();

            foreach (var t in arTreeSettings)
            {
                settings.Add(t.GetSettingName());
            }

            settingsEnum = settings.ToArray();

            // If selection has changed, set selectedSettings
            if (selectedSettings == "-1" && settingsEnum.Length > 0)
                selectedSettings = settingsEnum[0];
        }
        private void RefreshSelectedSettings()
        {
            if (selectedSettingsIndex >= 0 && selectedSettingsIndex < settingsEnum.Length)
            {
                selectedSettings = settingsEnum[selectedSettingsIndex];
            }

            // Has value changed ?
            if (previousSelectedSettings != selectedSettings)
            {
                foreach (var t in arTreeSettings)
                {
                    if (t.GetSettingName() == selectedSettings)
                    {
                        currentTreeSettings = t;
                        break;
                    }
                }

                previousSelectedSettings = selectedSettings;

                // Refresh current setting name (rename text field)
                settingRename = currentTreeSettings.GetSettingName();
            }
        }

        #region Utility
        /// <summary>
        /// Return false if the array is not existing or there are no setting existing.
        /// This should never be false as the "Default" setting is not removable from the editor.
        /// </summary>
        /// <returns></returns>
        private bool IsSettingsArrayValid()
        {
            bool b = arTreeSettings != null && arTreeSettings.Length > 0;

            if (b == false)
                Debug.LogWarning("TreeBendEditor stopped to draw its GUI as there are no TreeBendShaderSettings scriptable object found in the project.\n" +
                    "They have to be in a directory path like following: 'TreeBendEditor > Editor > ShaderSettings'.");

            return b;
        }
        private bool IsMaterialsHaveValidElement()
        {
            bool isValid = false;

            if (windowSettings.Materials != null && windowSettings.Materials.Count > 0)
            {
                foreach (var mat in windowSettings.Materials)
                {
                    if (isValid == false) // If there is at least one valid material, it will still allows to draw the properties
                        isValid = IsTreeMaterial(mat);
                }
            }

            return isValid;
        }
        private bool IsTreeMaterial(Material material)
        {
            if (material == null)
                return false;

            if (material.HasFloat("_TreeBendMaskDistanceOffset"))
                return true;
            else
                return false;
        }
        private bool IsDefaultSettings()
        {
            if (currentTreeSettings != null && currentTreeSettings.GetSettingName() == "Default")
            {
                return true;
            }
            else
                return false;
        }
        private int FindIndexFromSettingsName(string settingsName)
        {
            int toReturn = -1;

            // Find the corresponding index to the current settings selected
            for (int i = 0; i < settingsEnum.Length; i++)
            {
                if (settingsEnum[i] == settingsName)
                    toReturn = i;
            }

            return toReturn;
        }
        private string FindFolderByName(string folderName)
        {
            string[] folderGUIDs = AssetDatabase.FindAssets("t:Folder");

            foreach (string folderGUID in folderGUIDs)
            {
                string folderPath = AssetDatabase.GUIDToAssetPath(folderGUID);
                if (AssetDatabase.IsValidFolder(folderPath) && folderPath.EndsWith(folderName))
                {
                    return folderPath;
                }
            }

            return null;
        }
        private T CreateNewScriptableObject<T>(string rootFolderLocation = "TreeBendEditor", string subFolderLocation = "/Editor/Configs/ShaderSettings/", string fileName = "Custom.asset") where T : ScriptableObject
        {
            // Create a new instance of ScriptableObject
            T newObject = ScriptableObject.CreateInstance<T>();

            // Find the folder named "TreeBendShaderSettings" in the project
            string folderPath = FindFolderByName(rootFolderLocation);

            if (string.IsNullOrEmpty(folderPath))
            {
                Debug.LogError("Folder ' " + rootFolderLocation + "' not found in the project.");
                return null;
            }

            string path = AssetDatabase.GenerateUniqueAssetPath(folderPath + subFolderLocation + fileName);

            // Save the object to the project
            AssetDatabase.CreateAsset(newObject, path);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            return newObject;
        }
        #endregion

        #region GUI Utility
        private void CentererLabel(string label, int fontSize)
        {
            GUIStyle windowStyle = new GUIStyle(GUI.skin.window);
            int windowSize = 8;
            windowStyle.padding = new RectOffset(windowSize, windowSize, windowSize, windowSize);

            EditorGUILayout.BeginHorizontal(windowStyle, GUILayout.Height(windowSize));

            GUIStyle littleTitleStyle = new GUIStyle(GUI.skin.label);
            littleTitleStyle.fontSize = fontSize;
            littleTitleStyle.alignment = TextAnchor.MiddleCenter;

            GUILayout.Label(label, littleTitleStyle);

            EditorGUILayout.EndHorizontal();
        }
        private void DrawHeader()
        {
            EditorGUILayout.Space();

            GUIStyle titleStyle = new GUIStyle(GUI.skin.label);
            titleStyle.fontSize = 20;
            titleStyle.alignment = TextAnchor.MiddleCenter;

            GUILayout.Label("Eole|TreeBendEditor", titleStyle);
            EditorUtils.DrawEoleLabelVersion();

            EditorGUILayout.Separator();
        }
        #endregion

        #region GUI Group
        private void DrawMaterialsList()
        {
            if (displayInfo)
                EditorGUILayout.HelpBox("The materials (using the tree bend feature) store a GUID which refer to the last tree bend setting name. If the value of your setting have changed, you will need to refresh them manually with the tool (add them in the list below and apply the setting).", MessageType.Warning);

            // LIST MATERIAL ASSETS
            EditorGUILayout.BeginHorizontal();
            GUILayout.Label(windowSettings.Materials.Count + " Materials");

            // Push to the right
            GUILayout.FlexibleSpace();
            if (GUILayout.Button("Clear", GUILayout.Width(63)))
            {
                windowSettings.Materials.Clear();
            }

            EditorGUILayout.EndHorizontal();

            SerializedObject serializedObject = new SerializedObject(windowSettings);
            SerializedProperty materialsProperty = serializedObject.FindProperty("Materials");

            if (materialsProperty != null)
            {
                for (int i = 0; i < materialsProperty.arraySize; i++)
                {
                    EditorGUILayout.BeginHorizontal();

                    SerializedProperty materialElement = materialsProperty.GetArrayElementAtIndex(i);

                    // Try to find the tree bend shader settings name used (from its GUID) on this 
                    Material thisMat = windowSettings.Materials[i];

                    // Check if treeBend is existing in the shader/material
                    bool hasTreeBend = (thisMat != null && thisMat.HasProperty("_TreeBendMaskDistanceOffset")) ? true : false; // Is a TreeBend existing ? (don't do this with _UseTreeBend as it's auto registered
                    int guid = (hasTreeBend ? (int)windowSettings.Materials[i].GetFloat("_UseTreeBend") : -1); // If the material is not valid, return -1
                    string guidSettingName = string.Empty;

                    if (guid == -1)
                        guidSettingName = "none";
                    else if (guid == 0)
                        guidSettingName = "Custom User";
                    else
                        guidSettingName = windowSettings.FindShaderSettingNameFromGuid(guid);

                    // Show/Hide Buttons
                    if (!displaySettings)
                    {
                        EditorGUI.BeginDisabledGroup(guid > 0 || !hasTreeBend);
                        if (GUILayout.Button(new GUIContent("+", "Create a new setting from this material."), GUILayout.Width(20)))
                        {
                            NewSettings();
                            SetMaterialProperties();
                        }
                        EditorGUI.EndDisabledGroup();

                        EditorGUI.BeginDisabledGroup(guid <= 0);
                        if (GUILayout.Button(new GUIContent("#", "Override materials from this existing setting."), GUILayout.Width(20)))
                        {
                            selectedSettingsIndex = FindIndexFromSettingsName(windowSettings.FindShaderSettingNameFromGuid(guid));
                            RefreshSelectedSettings();

                            SetMaterialProperties();
                            //NewSettings();
                        }
                        EditorGUI.EndDisabledGroup();
                    }

                    // Color in red if this element is not valid
                    Color defaultGUIColor = GUI.color;
                    GUI.contentColor = (!hasTreeBend && thisMat != null) ? new Color(1.2f, 0.2f, 0.2f) : defaultGUIColor;

                    GUIContent customLabel = new GUIContent(i + ": " + guidSettingName);
                    EditorGUILayout.LabelField(customLabel, GUILayout.Width(120));

                    // Draw property
                    EditorGUILayout.PropertyField(materialElement, new GUIContent(), false);

                    // Reset GUI color
                    GUI.contentColor = defaultGUIColor;

                    // Button remove element
                    if (GUILayout.Button("X", GUILayout.Width(20)))
                    {
                        windowSettings.Materials.RemoveAt(i);
                        i = Mathf.Clamp(i--, 0, i);

                        EditorGUILayout.EndHorizontal(); // Fix error GUI Layout

                        return;
                    }

                    EditorGUILayout.EndHorizontal();
                }
            }

            // Push to the right
            EditorGUILayout.BeginHorizontal();
            GUILayout.FlexibleSpace();
            if (GUILayout.Button("+", GUILayout.Width(20)))
                windowSettings.Materials.Add(null);

            EditorGUILayout.Space(22);
            EditorGUILayout.EndHorizontal();

            // Apply modifications
            serializedObject.ApplyModifiedProperties();
        }
        private void DrawProperties()
        {
            bool isReadOnly = currentTreeSettings.GetSettingName() == "Default";

            EditorGUI.BeginDisabledGroup(isReadOnly);
            EditorGUILayout.BeginVertical("box");

            SerializedObject serializedObject = new SerializedObject(currentTreeSettings);

            // Display all class properties
            SerializedProperty serializedProperty = serializedObject.GetIterator();
            serializedProperty.Next(true);

            int propertyIndex = 0;
            while (serializedProperty.NextVisible(false))
            {
                if (propertyIndex != 0) // To hide the Script property field
                    EditorGUILayout.PropertyField(serializedProperty, true);

                propertyIndex++;
            }

            // Apply modifications
            serializedObject.ApplyModifiedProperties();

            EditorGUILayout.EndVertical();
            EditorGUI.EndDisabledGroup();
        }
        private void DrawRenameField()
        {
            EditorGUILayout.BeginHorizontal();

            if (!IsDefaultSettings())
            {
                settingRename = EditorGUILayout.TextField("        ", settingRename);

                bool isBtnRenameReadOnly = (settingRename == currentTreeSettings.GetSettingName());
                EditorGUI.BeginDisabledGroup(isBtnRenameReadOnly); // Is setting name modified ?
                Btn_RenameSettings(settingRename);
                EditorGUI.EndDisabledGroup();
            }
            else
            {
                EditorGUILayout.Space(20);
            }

            EditorGUILayout.EndHorizontal();
        }
        #endregion

        #region Buttons
        private bool Btn_GetTreeMaterials()
        {
            EditorGUI.BeginDisabledGroup(selectedObjects.Length == 0);

            if (GUILayout.Button("Fetch 'Tree' Materials from selection", GUILayout.Width(220), GUILayout.Height(25)))
            {
                foreach (var obj in selectedObjects)
                {
                    if (obj.TryGetComponent(out Renderer rend))
                    {
                        foreach (var mat in rend.sharedMaterials)
                        {
                            // Get tree material
                            if (windowSettings.Materials.Contains(mat) == false)
                            {
                                if (mat.HasFloat("_UseTreeBend"))
                                {
                                    // Search for first null reference in the list
                                    int setAtIndex = -1;
                                    for (int i = 0; i < windowSettings.Materials.Count; i++)
                                    {
                                        if (windowSettings.Materials[i] == null)
                                        {
                                            setAtIndex = i;
                                            break;
                                        }
                                    }

                                    // Get the index to replace or add an element
                                    if (setAtIndex == -1)
                                        windowSettings.Materials.Add(mat);
                                    else
                                        windowSettings.Materials[setAtIndex] = mat;
                                }
                            }
                        }
                    }
                }
                EditorGUI.EndDisabledGroup();
                return true;
            }
            EditorGUI.EndDisabledGroup();
            return false;
        }
        private bool Btn_DeleteSettings()
        {
            bool isReadOnly = false;
            if (currentTreeSettings == null || IsDefaultSettings())
                isReadOnly = true;

            EditorGUI.BeginDisabledGroup(isReadOnly);

            // Color
            Color originalColor = GUI.backgroundColor;
            GUI.backgroundColor = new Color(1f, 0.5f, 0.5f);

            if (GUILayout.Button(new GUIContent("X", "Delete this setting."), GUILayout.Width(20)))
            {
                windowSettings.RemoveShaderSettings(currentTreeSettings);
                TreeShaderUtility.DeleteAsset(currentTreeSettings);
                return true;
            }

            GUI.backgroundColor = originalColor;

            EditorGUI.EndDisabledGroup();

            return false;
        }
        private void Btn_RenameSettings(string newName)
        {
            bool isReadOnly = false;
            if (currentTreeSettings == null || IsDefaultSettings())
                isReadOnly = true;

            EditorGUI.BeginDisabledGroup(isReadOnly);

            if (GUILayout.Button("Rename", GUILayout.Width(63)))
            {
                TreeShaderUtility.RenameAsset(currentTreeSettings, newName);
                selectedSettings = newName;
            }

            EditorGUI.EndDisabledGroup();
        }
        private void NewSettings(Material fromMaterial = null)
        {
            currentTreeSettings = CreateNewScriptableObject<TreeBendShaderSettings>();

            if (fromMaterial != null)
            {
                currentTreeSettings.treeBendProperties.MaskDistanceOffset = fromMaterial.GetFloat("_TreeBendMaskDistanceOffset");
                currentTreeSettings.treeBendProperties.MaskFalloff = fromMaterial.GetFloat("_TreeBendMaskFalloff");
                currentTreeSettings.treeBendProperties.MaskFalloff = fromMaterial.GetFloat("_TreeBendFrequency");
                currentTreeSettings.treeBendProperties.MaskFalloff = fromMaterial.GetFloat("_TreeBendFrequencySpeed");
                currentTreeSettings.treeBendProperties.MaskFalloff = fromMaterial.GetFloat("_TreeBendMinAngle");
                currentTreeSettings.treeBendProperties.MaskFalloff = fromMaterial.GetFloat("_TreeBendMaxAngle");
                currentTreeSettings.treeBendProperties.MaskFalloff = fromMaterial.GetFloat("_TreeBendFrequencyOffsetRandom");
            }

            if (currentTreeSettings != null)
            {
                selectedSettingsIndex = FindIndexFromSettingsName(currentTreeSettings.GetSettingName());
                selectedSettings = currentTreeSettings.GetSettingName();
                windowSettings.AddShaderSettings(currentTreeSettings);
            }
        }
        private void Btn_SetDefaultValue()
        {
            GUILayout.BeginVertical();
            GUILayout.FlexibleSpace();

            GUILayout.BeginHorizontal();
            GUILayout.FlexibleSpace();
            if (GUILayout.Button("Set Default Settings", GUILayout.Width(150f)))
            {
                currentTreeSettings = ScriptableObject.CreateInstance<TreeBendShaderSettings>();
            }
            GUILayout.EndHorizontal();

            EditorGUILayout.Space(10);
            GUILayout.EndVertical();
        }
        #endregion
    }
}