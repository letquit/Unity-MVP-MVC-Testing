//Eole
//Copyright protected under Unity Asset Store EULA

using System.Collections.Generic;
using UnityEngine;

namespace EoleEditor.TreeBend
{
    [CreateAssetMenu(fileName = "NewTreeBendWindowSettings", menuName = "Eole/Create TreeBendWindowSettings")]
    public class TreeBendWindowSettings : ScriptableObject
    {
        public List<DictionnarySettings> DictionnarySettings;
        public List<Material> Materials = new();

        /// <summary>
        /// Remove element of DictionnarySetting if a reference is missing.
        /// </summary>
        public void Refresh()
        {
            // Remove elements with missing reference
            for (int i = 0; i < DictionnarySettings.Count; i++)
            {
                if (DictionnarySettings[i].shaderSetting == null)
                {
                    DictionnarySettings.RemoveAt(i);
                    i = Mathf.Clamp(i--, 0, i);
                }
            }
        }

        /// <summary>
        /// Return -1 if null or not found.
        /// </summary>
        /// <param name="shaderSettings"></param>
        /// <returns></returns>
        public int GetShaderSettingsGuid(TreeBendShaderSettings shaderSettings)
        {
            foreach (var dic in DictionnarySettings)
            {
                if (dic.shaderSetting == shaderSettings)
                    return dic.guid;
            }

            return -1;
        }

        /// <summary>
        /// Return empty if not found
        /// </summary>
        /// <param name="guid"></param>
        /// <returns></returns>
        public string FindShaderSettingNameFromGuid(int guid)
        {
            foreach (var s in DictionnarySettings)
            {
                if (s.guid == guid)
                {
                    return s.shaderSetting.GetSettingName();
                }
            }

            return string.Empty;
        }

        /// <summary>
        /// If return -1, it means that all materials don't share the same tree bend settings
        /// </summary>
        /// <returns></returns>
        public int GetCommonMaterialsGuid()
        {
            int lastGuid = -1;

            foreach (var mat in Materials)
            {
                if (mat != null)
                {
                    int guid = (int)mat.GetFloat("_UseTreeBend"); // the guid is stored in this property
                    
                    if (lastGuid == -1)
                        lastGuid = guid; // Init
                    else
                    {
                        if (lastGuid != guid)
                        {
                            return -1;
                        }
                    }
                }
            }

            return lastGuid;
        }

        private int GetAvailableGUID()
        {
            List<int> usedId = new();

            foreach (var id in DictionnarySettings)
            {
                usedId.Add(id.guid);
            }

            int availableId = 1; // start at 1, as 0 means not init

            while (usedId.Contains(availableId))
            {
                availableId++;
            }

            return availableId;
        }

        public void Init(TreeBendShaderSettings[] shaderSettings)
        {
            foreach (var s in shaderSettings)
            {
                AddShaderSettings(s);
            }
        }

        public void AddShaderSettings(TreeBendShaderSettings shaderSettings)
        {
            DictionnarySettings.Add(new DictionnarySettings(GetAvailableGUID(), shaderSettings));
        }

        public void RemoveShaderSettings(TreeBendShaderSettings shaderSettings)
        {
            foreach (var d in DictionnarySettings)
            {
                if (d.shaderSetting == shaderSettings)
                {
                    DictionnarySettings.Remove(d);
                    break;
                }
            }

        }
    }

    [System.Serializable]
    public class DictionnarySettings
    {
        public int guid;
        public TreeBendShaderSettings shaderSetting;

        public DictionnarySettings(int guid, TreeBendShaderSettings shaderSetting)
        {
            this.guid = guid;
            this.shaderSetting = shaderSetting;
        }
    }
}