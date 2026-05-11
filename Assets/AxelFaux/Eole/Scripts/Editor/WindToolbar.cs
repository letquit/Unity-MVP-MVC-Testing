//Eole
//Copyright protected under Unity Asset Store EULA

using Eole.Shaders;
using UnityEngine;
using UnityEditor.Toolbars;
using UnityEditor.Overlays;
using UnityEngine.UIElements;
using UnityEditor;

namespace EoleEditor
{
    [EditorToolbarElement(id, typeof(SceneView))]
    class DebugWind : EditorToolbarToggle
    {
        public const string id = "WindToolbar/DebugWind";
        public DebugWind()
        {
            icon = ToolbarUtility.GetIcon("WindIcon");
            tooltip = "Debug Wind Mask";

            EditorApplication.playModeStateChanged += DisableDebugViewMode;
            this.RegisterValueChangedCallback(OnClick);
        }

        void OnClick(ChangeEvent<bool> evt)
        {
            if (evt.newValue)
                SetDebugViewMode(1);
            else
                SetDebugViewMode(0);
        }

        void DisableDebugViewMode(PlayModeStateChange state)
        {
            if (state == PlayModeStateChange.EnteredPlayMode)
                SetDebugViewMode(0);
        }

        void SetDebugViewMode(int value)
        {
            Shader.SetGlobalInteger(ShaderPropertyID.DebugWind, value);
        }
    }

    [EditorToolbarElement(id, typeof(SceneView))]
    class DebugTurbulence : EditorToolbarToggle
    {
        public const string id = "WindToolbar/DebugTurbulence";

        public DebugTurbulence()
        {
            icon = ToolbarUtility.GetIcon("TurbulenceIcon");
            tooltip = "Debug Turbulence Mask";

            EditorApplication.playModeStateChanged += DisableDebugViewMode;
            this.RegisterValueChangedCallback(OnClick);
        }

        void OnClick(ChangeEvent<bool> evt)
        {
            if (evt.newValue)
                SetDebugViewMode(1);
            else
                SetDebugViewMode(0);
        }

        void DisableDebugViewMode(PlayModeStateChange state)
        {
            if (state == PlayModeStateChange.EnteredPlayMode)
                SetDebugViewMode(0);
        }

        void SetDebugViewMode(int value)
        {
            Shader.SetGlobalInteger(ShaderPropertyID.DebugWindTurbulence, value);
        }
    }

    [EditorToolbarElement(id, typeof(SceneView))]
    class DisableWPO : EditorToolbarToggle, IAccessContainerWindow
    {
        public const string id = "WindToolbar/DisableWPO";

        // This property is specified by IAccessContainerWindow and is used to access the Overlay's EditorWindow.
        public EditorWindow containerWindow { get; set; }

        public DisableWPO()
        {
            icon = ToolbarUtility.GetIcon("NoDisplacementIcon");
            tooltip = "Disable Wind Displacement";

            EditorApplication.playModeStateChanged += DisableDebugViewMode;
            this.RegisterValueChangedCallback(OnClick);

            // Subscribe to the Scene View OnGUI callback so that we can draw our color swatch.
            SceneView.duringSceneGui += DrawColorSwatch;
        }

        void OnClick(ChangeEvent<bool> evt)
        {
            if (evt.newValue)
                SetDebugViewMode(1);
            else
                SetDebugViewMode(0);
        }

        void DisableDebugViewMode(PlayModeStateChange state)
        {
            //if (state == PlayModeStateChange.EnteredPlayMode)
            SetDebugViewMode(0);
        }

        void SetDebugViewMode(int value)
        {
            Shader.SetGlobalInteger(ShaderPropertyID.DebugDisableWPO, value);
        }

        void DrawColorSwatch(SceneView view)
        {
            // Test that this callback is for the Scene View that we're interested in, and also check if the toggle is on
            // or off (value).
            if (view != containerWindow || !value)
                return;

            Handles.BeginGUI();
            GUI.color = new Color(1, 0, 0, 0.8f);

            // Upper middle coordinates
            float rectWidth = 180;
            float rectHeight = 24;
            float x = (view.position.width - rectWidth) / 2; // Centered horizontaly
            float y = 8; // Upper position

            GUI.DrawTexture(new Rect(x, y, rectWidth, rectHeight), Texture2D.whiteTexture);
            GUI.color = Color.white;

            // Text
            string texte = "Windy Displacement : Disabled"; // Le texte que vous souhaitez afficher
            GUIStyle style = new GUIStyle();
            style.alignment = TextAnchor.MiddleCenter; // Centrer le texte
            GUI.Label(new Rect(x, y, rectWidth, rectHeight), texte, style);


            Handles.EndGUI();
        }
    }


    // All Overlays must be tagged with the OverlayAttribute

    [Overlay(typeof(SceneView), "Eole Toolbar")]

    // IconAttribute provides a way to define an icon for when an Overlay is in collapsed form. If not provided, the name initials are used.

    //[Icon("Assets/Eole/Resources/Textures/EoleLogo.png")]

    // Toolbar Overlays must inherit `ToolbarOverlay` and implement a parameter-less constructor. The contents of a toolbar are populated with string IDs, which are passed to the base constructor. IDs are defined by EditorToolbarElementAttribute.

    public class WindToolbar : ToolbarOverlay
    {
        // ToolbarOverlay implements a parameterless constructor, passing the EditorToolbarElementAttribute ID.
        // This is the only code required to implement a toolbar Overlay. Unlike panel Overlays, the contents are defined
        // as standalone pieces that will be collected to form a strip of elements.

        WindToolbar() : base(
            DebugWind.id,
            DebugTurbulence.id,
            DisableWPO.id
            )
        { }
    }
}