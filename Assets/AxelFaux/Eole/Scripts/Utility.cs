//Eole
//Copyright protected under Unity Asset Store EULA

using UnityEngine;

namespace Eole
{
    public class Utility
    {
        public static T FindObject<T>() where T : UnityEngine.Object
        {
#if UNITY_2023_1_OR_NEWER
            var result = Object.FindFirstObjectByType(typeof(T));
#else // Unity 2022 and earlier
            var result = Object.FindObjectOfType<T>();
#endif
            if (result == null)
                return null;
            else
                return (T)result;
        }

        public static T[] FindObjects<T>() where T : UnityEngine.Object
        {
#if UNITY_2023_1_OR_NEWER
            var result = Object.FindObjectsByType(typeof(T), FindObjectsSortMode.None);
#else // Unity 2022 and earlier
            var result = Object.FindObjectsOfType<T>();
#endif
            if (result == null)
                return null;
            else
                return (T[])result;
        }

        /// <summary>
        /// Return false if the selected object is not in a valid scene. Used to avoid any prefab to execute script if it's open or displayed in the editor / project.
        /// </summary>
        /// <param name="obj"></param>
        /// <returns></returns>
        public static bool IsSceneValid(GameObject obj)
        {
            if (obj.scene.IsValid())
            {
                if (obj.scene.name != obj.transform.root.name) // is not in the prefab scene mode
                    return true;
            }

            return false;
        }
    }
}