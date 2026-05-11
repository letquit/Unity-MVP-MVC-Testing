//Eole
//Copyright protected under Unity Asset Store EULA

using System;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace EoleEditor.TreeBend
{
    [CreateAssetMenu(fileName = "NewTreeShaderSettings", menuName = "Eole/Create TreeBendShaderSettings")]
    public class TreeBendShaderSettings : ScriptableObject
    {
        public TreeBendShaderProperties treeBendProperties;


        public string GetSettingName()
        {
            string assetPath = AssetDatabase.GetAssetPath(this);

            if (string.IsNullOrEmpty(assetPath))
            {
                return null;
            }

            string fileNameWithoutExtension = Path.GetFileNameWithoutExtension(assetPath);
            return fileNameWithoutExtension;
        }
    }

    [System.Serializable]
    public class TreeBendShaderProperties
    {
        [Header("Mask")]
        public float MaskDistanceOffset = 0.3f;
        [Range(0, 20)] public float MaskFalloff = 3f;

        [Header("Frequency")]
        public float Frequency = 0.15f;
        public float FrequencySpeed = 10f;
        public float FrequencyRandom = 0.5f;

        [Header("Angle")]
        [Range(0, 90)] public float BendMaxAngle = 10f; // In degrees, then it will be converted in radians.
        [Range(-90, 90)] public float BendMinAngle = -10f; // In degrees, then it will be converted in radians.
    }
}