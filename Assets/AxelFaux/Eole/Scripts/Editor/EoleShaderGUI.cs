//Eole
//Copyright protected under Unity Asset Store EULA

using EoleEditor.TreeBend;
using EoleEditor.ShaderProperties;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;


namespace EoleEditor
{
    // https://github.com/Unity-Technologies/Graphics/blob/d0473769091ff202422ad13b7b764c7b6a7ef0be/com.unity.render-pipelines.core/Editor/CoreEditorUtils.cs#L298C1-L364C10
    public class EoleShaderGUI : ShaderGUI
    {
        private Dictionary<string /* group name */, bool /* is unfold */> showGroups = new();         // GroupName : FoldoutState
        private MaterialEditor editor;
        private Material material;
        private MaterialProperty[] properties;
        private Dictionary<string /* property name*/, bool /* isDisplayed */> conditionalProperties = new();
        private List<string> propertyPool = new(); // Useful to compare later which properties are not included in a group, so that it draws them in an "Others" group.


        private void InitializeMaterialProperties()
        {
            // Set property pool
            propertyPool = new();
            RegisteredProperties.InitializeAllRegisteredPropertyName();
            propertyPool.AddRange(RegisteredProperties.AllRegisteredPropertiesWithTooltips.Keys);
            propertyPool.AddRange(Keywords.AllKeywordsPropertyName);

            // Conditional display
            SetCondiationProperties();
        }

        public override void OnGUI(MaterialEditor editor, MaterialProperty[] properties)
        {
            // Initialize
            bool isUnfold = true;
            this.material = editor.target as Material;
            this.editor = editor;
            this.properties = properties;
            InitializeMaterialProperties();

            EditorUtils.DrawEoleLabelVersion();

            #region GROUP Color
            string groupColor = "Color";
            isUnfold = BeginFoldout(groupColor);

            if (isUnfold)
            {
                // Base Color
                DrawProperties(RegisteredProperties.propColor);
                EditorGUILayout.Separator();

                // Normal
                bool subNormal = BeginFoldout("Normal (pixel & vertex)", true);
                if (subNormal) DrawProperties(RegisteredProperties.propNormalMap);
                EndFoldout(subNormal);

                // ColorMap
                EditorGUILayout.Separator();

                if (BeginGroupWithKeyword("Color Map (Ground Color)", Keywords.UseColormap, true, true))
                {
                    // Info base color alpha
                    if (EditorUtils.HasKeyword(material, Keywords.UseColormap.name))
                    {
                        GUIContent content = new GUIContent("You can use the Base Color's alpha to control the blending.");
                        EditorGUILayout.HelpBox(content);
                    }
                    DrawProperties(RegisteredProperties.propColorMapBlending);
                    EndGroupWithKeyword(true);
                    EditorGUILayout.Separator();
                }
            }
            EndFoldout(isUnfold);
            #endregion

            #region GROUP Translucency
            isUnfold = BeginGroupWithKeyword("Translucency", Keywords.UseTranslucency, true);
            if (isUnfold)
                DrawProperties(RegisteredProperties.propTranslucency);

            EndGroupWithKeyword(true, isUnfold);
            #endregion

            #region GROUP Wind
            // Try get wind keyword.
            // _Wind (None, Simple or Advanced)
            // _Wind_Simple (None, Simple). Advanced is excluded for reducing shader variant.
            // _Wind_Advanced (None, Advanced). Simple is excluded for reducing shader variant.
            if (EditorUtils.TryGetMaterialProperty("_Wind", properties, out MaterialProperty windProperty)) // None || Simple || Advanced
                DrawWindGroup(windProperty);
            else if (EditorUtils.TryGetMaterialProperty("_Wind_Simple", properties, out MaterialProperty simpleWindProperty)) // None || Simple
                DrawWindGroup(simpleWindProperty);
            else if (EditorUtils.TryGetMaterialProperty("_Wind_Advanced", properties, out MaterialProperty advancedWindProperty)) // None || Advanced
                DrawWindGroup(advancedWindProperty);
            #endregion

            #region GROUP Crush
            isUnfold = BeginGroupWithKeyword("Crush", Keywords.UseCrush, true);
            if (isUnfold)
                DrawProperties(RegisteredProperties.propCrush);

            EndGroupWithKeyword(true, isUnfold);
            #endregion

            #region GROUP Tesselation
            // Make sure that the tesselation is used by searching its main property
            if (EditorUtils.TryGetMaterialProperty("_TessValue", properties, out MaterialProperty tessMatProperty))
            {
                isUnfold = BeginFoldout("Tesselation");
                if (isUnfold)
                    DrawProperties(RegisteredProperties.propTess);

                EndFoldout(isUnfold);
            }
            #endregion

            #region GROUP Tree Bend
            if (material.HasProperty("_TreeBendMaskFalloff")) // Try with another property than "_UseTreeBend" as it's an auto-registered property.
            {
                string groupTreeBend = "Tree Bend";
                isUnfold = BeginFoldout(groupTreeBend);

                if (isUnfold)
                {
                    EditorGUILayout.BeginHorizontal();
                    if (GUILayout.Button("Open TreeBendEditor"))
                    {
                        TreeBendEditor.ShowWindow();
                    }
                    
                    if (material.GetFloat("_UseTreeBend") != 0)
                    {
                        GUIContent buttonContent = new GUIContent("Manual Edit", "If existing for this material, it will override the settings GUID. TreeBendEditor is more user friendly as you can select different setup.");

                        if (GUILayout.Button(buttonContent))
                        {
                            material.SetFloat("_UseTreeBend", 0);
                        }
                    }
                    EditorGUILayout.EndHorizontal();

                    // INFO
                    if (material.GetFloat("_UseTreeBend") != 0)
                    {
                        EditorGUILayout.HelpBox("Properties are hidden as it use a Tree Bend setting.", MessageType.Info);
                    }

                    if (material.GetFloat("_UseTreeBend") == 0)
                    {
                        DrawProperties(RegisteredProperties.propTreeBend);
                    }

                    EditorGUILayout.Separator();
                }
                EndFoldout(isUnfold);
            }
            #endregion

            #region GROUP Others (any public & not registered material properties)
            // RegisteredProperties with the hidden flag are not included in this group.

            // Get propertyPool of properties which were already attributed to a group.
            // So that any of these property will be drawn if they are hidden / not used.
            List<MaterialProperty> remainingProperties = new();

            foreach (var p in properties)
            {
                // not hidden prop
                if ((p.propertyFlags & UnityEngine.Rendering.ShaderPropertyFlags.HideInInspector) == 0)
                {
                    // propertyPool does not contain this property
                    if (!propertyPool.Contains(p.name))
                    {
                        remainingProperties.Add(p);
                    }
                }
            }

            // Draw OTHERS group
            if (remainingProperties.Count > 0)
            {
                isUnfold = BeginFoldout("Others");

                if (isUnfold)
                    DrawProperties(remainingProperties.ToArray());

                EndFoldout(isUnfold);
            }
            #endregion

            #region GROUP Material Rendering Options
            EditorGUILayout.Separator();
            isUnfold = BeginFoldout("Rendering Options", false);

            if (isUnfold)
            {
                editor.EnableInstancingField();
                editor.DoubleSidedGIField();
                editor.RenderQueueField();
            }

            EndFoldout(isUnfold);
            #endregion
        }

        #region GUI Utility
        private bool BeginFoldout(string groupName, bool isSubGroup = false)
        {
            // init group
            if (!showGroups.ContainsKey(groupName))
                showGroups.Add(groupName, true);

            bool isUnfold;

            if (isSubGroup)
                isUnfold = showGroups[groupName] = EditorGUILayout.BeginFoldoutHeaderGroup(showGroups[groupName], groupName);
            else
                isUnfold = showGroups[groupName] = EditorUtils.DrawHeaderFoldout(groupName, showGroups[groupName]);

            /*if (isUnfold)
                EditorGUILayout.BeginVertical(GUI.skin.box);*/ // Begin box background

            return isUnfold;
        }
        private void EndFoldout(bool isUnfold)
        {
            EditorGUILayout.EndFoldoutHeaderGroup();
            if (isUnfold)
            {
                //EditorGUILayout.EndVertical(); // End box background
                EditorGUILayout.Separator();
            }
        }

        private void DrawProperties(string[] propertyNames)
        {
            foreach (var propName in propertyNames)
                DrawProperty(EditorUtils.GetMaterialProperty(propName, properties));
        }
        private void DrawProperties(MaterialProperty[] properties)
        {
            foreach (var prop in properties)
                DrawProperty(prop);
        }
        private void DrawProperty(MaterialProperty property)
        {
            if (property == null)
                return;

            // ignored hidden prop
            if ((property.propertyFlags & UnityEngine.Rendering.ShaderPropertyFlags.HideInInspector) != 0)
                return;

            // Display propertyValue
            if (GetConditionalDisplayValue(property.name))
            {
                // Tooltip
                var tooltip = property.name;
                if (RegisteredProperties.AllRegisteredPropertiesWithTooltips.TryGetValue(property.name, out string value))
                    tooltip += "\n\n" + value;

                GUIContent guiContent = new GUIContent(property.displayName, tooltip);

                // Draw the property
                editor.ShaderProperty(property, guiContent);
            }
        }

        private bool BeginGroupWithKeyword(string groupName, Keywords.KeywordProperty keyword, bool useFold, bool isSubGroup = false)
        {
            if (EditorUtils.GetMaterialProperty(keyword.name, properties) == null) // If keaword exist in the shader
                return false;

            bool isKeywordEnabled = EditorUtils.HasKeyword(material, keyword.keyword);

            if (useFold)
            {
                bool isUnfold = BeginFoldout(groupName, isSubGroup);
                if (isUnfold)
                {
                    // Draw keyword
                    DrawProperty(EditorUtils.GetMaterialProperty(keyword.name, properties)); // Draw keaword

                    if (isKeywordEnabled)
                        return true; // Draw properties used according to this keyword
                    else
                        return false; // Don't draw properties (only keaword will be drawn, if existing in the shader
                }
                else
                    return false;
            }
            else // Not using fold
            {
                BeginHeaderGroup(groupName);
                DrawProperty(EditorUtils.GetMaterialProperty(keyword.name, properties)); // Draw keyword property
                return true; // Draw other properties
            }
        }

        private void EndGroupWithKeyword(bool useFold) { EndGroupWithKeyword(useFold, false); }
        private void EndGroupWithKeyword(bool useFold, bool isUnfold)
        {
            if (useFold)
            {
                EndFoldout(isUnfold);
            }
            else
                EditorGUILayout.EndVertical(); // Close box background
        }

        private void BeginHeaderGroup(string groupName)
        {
            EditorGUILayout.Separator();
            GUILayout.Label(groupName.ToUpper(), EditorStyles.boldLabel); // Add label when not using fold
            EditorGUILayout.BeginVertical(GUI.skin.box); // Box background
        }
        private void EndHeaderGroup()
        {
            EditorGUILayout.EndVertical(); // Box background
        }

        private static void DrawCenteredLabel(string text)
        {
            EditorGUILayout.Separator();
            DrawCustomSeparator();

            EditorGUILayout.BeginHorizontal();
            GUILayout.FlexibleSpace();
            GUILayout.Label(text, EditorStyles.largeLabel);

            GUILayout.FlexibleSpace();
            EditorGUILayout.EndHorizontal();

            DrawCustomSeparator();
            EditorGUILayout.Separator();
        }
        private static void DrawCustomSeparator()
        {
            // Calculate start and end positions for the separation line
            Rect lastRect = GUILayoutUtility.GetLastRect();
            Vector2 start = new Vector2(lastRect.x, lastRect.yMax + 2); // Add an offset for spacing
            Vector2 end = new Vector2(EditorGUIUtility.currentViewWidth - 5, lastRect.yMax + 2); // Use position.width for width

            // Draw a custom separation line using Handles.DrawLine
            Handles.color = Color.grey;
            Handles.DrawLine(start, end);
        }
        #endregion

        #region Conditional Property
        private void SetCondiationProperties()
        {
            #region Init conditional properties
            // Keyword propertyValue ; property to show/hide

            // Colormap == TRUE
            conditionalProperties = new();
            SetConditionalDisplay("_MainBlendOffset", Keywords.UseColormap.keyword);
            SetConditionalDisplay("_MainBlendFadeContrast", Keywords.UseColormap.keyword);

            // Colormap & Variant == TRUE
            SetConditionalDisplay("_VariantBlendOffset", new string[] { Keywords.UseColormap.keyword, Keywords.UseVariant.keyword });
            SetConditionalDisplay("_VariantBlendFadeContrast", new string[] { Keywords.UseColormap.keyword, Keywords.UseVariant.keyword });

            // Wind != NONE
            SetConditionalDisplay("_WindBrightnessAlpha", Keywords.WindNone.keyword, false);
            #endregion
        }

        private void SetConditionalDisplay(string propertyName, string keyword) { SetConditionalDisplay(propertyName, new string[] { keyword }, true); }
        private void SetConditionalDisplay(string propertyName, string keyword, bool mustContainKeyword) { SetConditionalDisplay(propertyName, new string[] { keyword }, mustContainKeyword); }
        private void SetConditionalDisplay(string propertyName, string[] keywords) { SetConditionalDisplay(propertyName, keywords, true); }
        private void SetConditionalDisplay(string propertyName, string[] keywords, bool mustContainKeyword)
        {
            bool boolValue = false;

            // Search each keyword : if one of them is not enable, boolValue is false to do not draw the property
            foreach (var k in keywords)
            {
                if (mustContainKeyword) // "Keywords must be enabled"
                {
                    if (EditorUtils.HasKeyword(material, k))
                        boolValue = true;
                    else
                        boolValue = false;
                }
                else // "Keywords must be disabled"
                {
                    if (EditorUtils.HasKeyword(material, k))
                        boolValue = false;
                    else
                        boolValue = true;
                }
            }

            if (!conditionalProperties.ContainsKey(propertyName))
            {
                conditionalProperties.Add(propertyName, boolValue);
            }
        }

        /// <summary>
        /// Search for a propertyValue value to display this property, if existing. Return true if there is no propertyValue.
        /// </summary>
        /// <param name="property"></param>
        /// <param name="conditionalProperties"></param>
        /// <returns></returns>
        private bool GetConditionalDisplayValue(string property)
        {
            if (conditionalProperties.TryGetValue(property, out bool value))
            {
                return value;
            }

            return true;
        }
        #endregion

        private void DrawWindGroup(MaterialProperty windProperty) // get the property to draw the right enum keyword in the GUI
        {
            int windEnumValue = (int)windProperty.floatValue;
            string windModeInfo;

            // 0 = None ; 1 = Simple ; 2 = Advanced
            // Set wind mode info
            switch (windEnumValue)
            {
                case 0:
                    windModeInfo = "(Disabled)";
                    break;
                case 1:
                    windModeInfo = "(Simple)";

                    if (windProperty.name == "_Wind_Advanced")
                        windModeInfo = "(Advanced)";
                    break;
                case 2:
                    windModeInfo = "(Advanced)";
                    break;
                default:
                    windModeInfo = "(Disabled)";
                    break;
            }

            bool isUnfold = BeginFoldout("Wind " + windModeInfo);
            if (isUnfold)
            {
                // Draw enum keyword
                DrawProperty(windProperty);

                if (windEnumValue != 0)
                {
                    // Main property wind
                    DrawProperties(RegisteredProperties.propWindTint);
                    EditorGUILayout.Separator();

                    bool subWind = true;

                    if (windEnumValue == 1)
                    {
                        if (windProperty.name == "_Wind_Advanced")
                        {
                            subWind = BeginFoldout("B�zier", true);
                            if (subWind) DrawProperties(RegisteredProperties.propWindAdvanced);
                            EndFoldout(subWind);
                        }
                        else
                        {
                            subWind = BeginFoldout("Simple Wind", true);
                            if (subWind) DrawProperties(RegisteredProperties.propWindSimple);
                            EndFoldout(subWind);
                        }
                    }
                    if (windEnumValue == 2)
                    {
                        subWind = BeginFoldout("B�zier", true);
                        if (subWind) DrawProperties(RegisteredProperties.propWindAdvanced);
                        EndFoldout(subWind);
                    }

                    bool subTurbulence = true;
                    subTurbulence = BeginFoldout("Turbulence", true);
                    if (subTurbulence) DrawProperties(RegisteredProperties.propTurbulence);
                    EndFoldout(subTurbulence);

                    bool subAdvancedSettings = false;
                    subAdvancedSettings = BeginFoldout("Advanced Settings", true);
                    if (subAdvancedSettings)
                    {
                        EditorGUILayout.HelpBox("The main wind smoothstep is controlable in the foliage manager.", MessageType.None);
                        DrawProperties(RegisteredProperties.propWind);
                    }
                    EndFoldout(subAdvancedSettings);

                    /*BeginHeaderGroup("Advanced Settings");

                    DrawProperties(propWind);
                    EndHeaderGroup();*/
                }
            }
            EndFoldout(isUnfold);
        }
    }
}

namespace EoleEditor.ShaderProperties
{
    public struct Keywords
    {
        public static List<string> AllKeywordsPropertyName { get; private set; } = new();

        public static KeywordProperty UseVariant { get; private set; } = new KeywordProperty("_UseVariant", "_USEVARIANT_ON");
        public static KeywordProperty UseCrush { get; private set; } = new KeywordProperty("_UseCrush", "_USECRUSH_ON");
        public static KeywordProperty UseColormap { get; private set; } = new KeywordProperty("_UseColormap", "_USECOLORMAP_ON");
        public static KeywordProperty UseTranslucency { get; private set; } = new KeywordProperty("_UseTranslucency", "_USETRANSLUCENCY_ON");
        public static KeywordProperty WindNone { get; private set; } = new KeywordProperty("_Wind", "_WIND_NONE");
        public static KeywordProperty WindSimple { get; private set; } = new KeywordProperty("_Wind_Simple", "_WIND_SIMPLE");
        public static KeywordProperty WindAdvanced { get; private set; } = new KeywordProperty("_Wind_Advanced", "_WIND_ADVANCED");
        public static KeywordProperty UseAirSheen { get; private set; } = new KeywordProperty("_UseAirSheenTint", "_USEAIRSHEENTINT_ON");

        public struct KeywordProperty
        {
            public string name;
            public string keyword;

            public KeywordProperty(string name, string keyword)
            {
                this.name = name;
                this.keyword = keyword;

                AllKeywordsPropertyName.Add(name);
            }
        }
    }

    public struct RegisteredProperties
    { 
        public static Dictionary<string, string> AllRegisteredPropertiesWithTooltips { get; private set; } = new();

        private static bool isInit = false;

        public static void InitializeAllRegisteredPropertyName()
        {
            if (isInit)
                return;

            /*FieldInfo[] fields = typeof(RegisteredProperties).GetFields(BindingFlags.Public | BindingFlags.Static);

            foreach (FieldInfo field in fields)
            {
                if (field.FieldType == typeof(string[]))
                {
                    string[] propertyArray = (string[])field.GetValue(null);
                    AllRegisteredPropertyName.AddRange(propertyArray);
                }
            }*/

            AllRegisteredPropertiesWithTooltips.Add("_BaseMap", "");
            AllRegisteredPropertiesWithTooltips.Add("_MainBaseColor", "Main color blended with the Base Map. Alpha is used to blend between this color and the Color Map.");
            AllRegisteredPropertiesWithTooltips.Add("_VariantBaseColor", "Variant color blended with the Base Map depending on the shader setup. Alpha is used to blend between this color and the Color Map.");
            AllRegisteredPropertiesWithTooltips.Add("_VariantOffset", "Height offset of the variant.");
            AllRegisteredPropertiesWithTooltips.Add("_VariantContrast", "Contrast / hardness of the blending between the Base Color and Variant Color.");
            AllRegisteredPropertiesWithTooltips.Add("_ColorMapBlendOffset", "Offset of the blending.");
            AllRegisteredPropertiesWithTooltips.Add("_ColorMapFadeContrast", "Hardness of the fade.");
            AllRegisteredPropertiesWithTooltips.Add("_NormalMap", "Normal map texture.");
            AllRegisteredPropertiesWithTooltips.Add("_NormalStrength", "Normal map strength");
            AllRegisteredPropertiesWithTooltips.Add("_FlattenVertexNormal", "0 : Default vertex normal (orientation).\n1 : Pointing up for a flatten shaded look.");
            AllRegisteredPropertiesWithTooltips.Add("_AlphaThreshold", "");
            AllRegisteredPropertiesWithTooltips.Add("_TranslucencyDirect", "Translucency strength on not shadowed surfaces (front & back faces).");
            AllRegisteredPropertiesWithTooltips.Add("_TranslucencyShadows", "Translucency strength on shadowed surfaces (front & back faces).");
            AllRegisteredPropertiesWithTooltips.Add("_TranslucencyDotViewPower", "Dot product between space view and directional light.\nLow: diffused.\nHigh: concentrated to a 'point'.");
            AllRegisteredPropertiesWithTooltips.Add("_SecondWindSmoothstep", "This is a second wind smoothstep, based on the main wind mask and smoothstep (global properties). \r\nMostly to give a tiny different behavior from other foliages.\r\n");
            AllRegisteredPropertiesWithTooltips.Add("_SimpleWindDisplacement", "Vertex position offset depending on the wind mask.");
            AllRegisteredPropertiesWithTooltips.Add("_SimpleWindyYOffset", "Vertex position offset in relative Y. You can use it to fake a crushing effect while it's windy (the more it's windy, the more the vertex will diplace in Y axis).");
            AllRegisteredPropertiesWithTooltips.Add("_BezierAlpha", "Alpha amplitude of the idle Bezier curve.");
            AllRegisteredPropertiesWithTooltips.Add("_BezierP1", "Point 1 (middle point) of the idle Bezier curve (X: forward, Y: up).");
            AllRegisteredPropertiesWithTooltips.Add("_BezierP2", "Point 2 (end point) of the idle Bezier curve (X: forward, Y: up).");
            AllRegisteredPropertiesWithTooltips.Add("_BezierOffsetAlpha", "Alpha amplitude of the windy Bezier curve.");
            AllRegisteredPropertiesWithTooltips.Add("_BezierOffsetP1", "Offset applied on Point 1 (middle point), when it is windy. (X: forward, Y: up).");
            AllRegisteredPropertiesWithTooltips.Add("_BezierOffsetP2", "Offset applied on Point 2 (end point), when it is windy. (X: forward, Y: up).");
            AllRegisteredPropertiesWithTooltips.Add("_WindBrightness", "Brightness of the foliage depending on the wind mask.");
            AllRegisteredPropertiesWithTooltips.Add("_UseAirSheenTint", "Use the Air Sheen tint (depends on the wind mask).");
            AllRegisteredPropertiesWithTooltips.Add("_TurbulenceDisplacement", "Additional vertex position offset, the turbulence is a cosine (wave) mask scrolling on the surface. Represents the value at the highest wind mask value (1).");
            //AllRegisteredPropertiesWithTooltips.Add("_TurbulenceThresholdMin", "Wind threshold value as the minimum turbulence.");
            AllRegisteredPropertiesWithTooltips.Add("_TurbulenceSmoothstepMax", "Max smoothstep of Wind mask value used for turbulence. For a lower value, the maximum turbulence will be reached.");
            AllRegisteredPropertiesWithTooltips.Add("_TurbulenceSpeed", "Turbulence offset speed.");
            AllRegisteredPropertiesWithTooltips.Add("_TurbulenceFrequency", "Frequency of the turbulence.");
            AllRegisteredPropertiesWithTooltips.Add("_CrushAngle", "Max angle of the crush/bend.");
            AllRegisteredPropertiesWithTooltips.Add("_CrushHeightOffset", "Relative Y vertex position offset for more control on the bending in addition to the angle.");
            AllRegisteredPropertiesWithTooltips.Add("_CrushFlattenScale", "Flatten the mesh.");
            AllRegisteredPropertiesWithTooltips.Add("_CrushBrightness", "Brightness of the crushed foliage.");
            AllRegisteredPropertiesWithTooltips.Add("_TessValue", "Tessellation Factor which determines the maximum amount tessellation/subdivisions that will be done. This value should be between [1-32].");
            AllRegisteredPropertiesWithTooltips.Add("_TessMin", "Minimum distance in meters to the camera where maximum tessellation should occur. Only visible if the respective input port is not connected.\t");
            AllRegisteredPropertiesWithTooltips.Add("_TessMax", "Maximum distance in meters to the camera where maximum tessellation should occur. Only visible if the respective input port is not connected.\t");
            
            // TREE BEND
            AllRegisteredPropertiesWithTooltips.Add("_UseTreeBend", ""); // AutoRegistered property, it won't be displayed. As there are no keyword for this feature, just check if this one is existing to draw the other properties.
            AllRegisteredPropertiesWithTooltips.Add("_TreeBendMaskDistanceOffset", "Offset the origin pivot from which the distance will be calculated. The more the pixel is far from this pivot, the more the tree will bend.");
            AllRegisteredPropertiesWithTooltips.Add("_TreeBendMaskFalloff", "Hardness/Falloff of the mask calculated from the distance of the pivot.");
            AllRegisteredPropertiesWithTooltips.Add("_TreeBendFrequency", "Frequency of the bending. Frequency goes between -1 and 1.");
            AllRegisteredPropertiesWithTooltips.Add("_TreeBendFrequencySpeed", "The frequency offset speed.");
            AllRegisteredPropertiesWithTooltips.Add("_TreeBendFrequencyOffsetRandomn", "0 means all trees bend in a synchronized manner. Higher value means more randomness (relative to world position).");
            AllRegisteredPropertiesWithTooltips.Add("_TreeBendMaxAngle", "The maximum angle (in radians) at which the tree will bend, relative to the bending mask (in the direction of the wind).\nThis value is in degree (for sake of simplicity), but in the shader/material, it is in radian.");
            AllRegisteredPropertiesWithTooltips.Add("_TreeBendMinAngle", "The minimum angle (in radians) at which the tree will bend, relative to the bending mask. A negative value means that the tree can bend in the opposite wind direction (mostly for stylized behaviour). A positive value will bend in the direction of the wind.");

            isInit = true;
        }



        #region Properties by group
        public static string[] propColor = {
            "_BaseMap",
            "_MainBaseColor",
            "_VariantBaseColor",
            "_VariantOffset",
            "_VariantContrast",
            "_AlphaThreshold"
        };
        public static string[] propColorMapBlending = {
            "_ColorMapBlendOffset",
            "_ColorMapFadeContrast"
        };
        public static string[] propNormalMap = {
            "_NormalMap",
            "_NormalStrength",
            "_FlattenVertexNormal",
        };
        /*public static string[] propOtherColor = {
            "_FlattenVertexNormal",
            "_AlphaThreshold"
        };*/
        public static string[] propTranslucency = {
            "_TranslucencyDirect",
            "_TranslucencyShadows",
            "_TranslucencyDotViewPower"
        };
        public static string[] propWind = {
            "_SecondWindSmoothstep"
        };
        public static string[] propWindSimple =
        {
            "_SimpleWindDisplacement",
            "_SimpleWindyYOffset"
        };
        public static string[] propWindAdvanced = {
            "_BezierAlpha",
            "_BezierP1",
            "_BezierP2",
            "_BezierOffsetAlpha",
            "_BezierOffsetP1",
            "_BezierOffsetP2"
        };
        public static string[] propWindTint = {
            "_WindBrightness",
            "_UseAirSheenTint"
        };
        public static string[] propTurbulence = {
            "_TurbulenceDisplacement",
            "_TurbulenceSmoothstepMax",
            "_TurbulenceSpeed",
            "_TurbulenceFrequency"
        };
        public static string[] propTreeBend = {
            //"_UseTreeBend",
            "_TreeBendMaskDistanceOffset",
            "_TreeBendMaskFalloff",
            "_TreeBendFrequency",
            "_TreeBendFrequencySpeed",
            "_TreeBendFrequencyOffsetRandomn",
            "_TreeBendMinAngle",
            "_TreeBendMaxAngle"
        };
        public static string[] propCrush = {
            "_CrushAngle",
            "_CrushHeightOffset",
            "_CrushFlattenScale",
            "_CrushBrightness"
        };
        public static string[] propTess = {
            "_TessValue",
            "_TessMin",
            "_TessMax"
        };
        #endregion
    }
}