//Eole
//Copyright protected under Unity Asset Store EULA

using System.Collections.Generic;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.Rendering;

namespace EoleEditor.Build
{
    class ShaderDebugBuildProcessor : IPreprocessShaders
    {
        List<ShaderKeyword> m_shaderKeywords = new();

        public ShaderDebugBuildProcessor()
        {
            m_shaderKeywords = new();

            m_shaderKeywords.Add(new ShaderKeyword("_DEBUGWIND_ON"));
            m_shaderKeywords.Add(new ShaderKeyword("_DEBUGDISABLEWINDWPO_ON"));
        }

        // Multiple callback may be implemented.
        // The first one executed is the one where callbackOrder is returning the smallest number.
        public int callbackOrder { get { return 0; } }

        public void OnProcessShader(
            Shader shader, ShaderSnippetData snippet, IList<ShaderCompilerData> shaderCompilerData)
        {
            // Don't strip in development build
            if (EditorUserBuildSettings.development)
                return;

            int stripCount = 0;

            for (int i = 0; i < shaderCompilerData.Count; ++i)
            {
                foreach (var keyword in m_shaderKeywords)
                {
                    if (shaderCompilerData[i].shaderKeywordSet.IsEnabled(keyword))
                    {
                        shaderCompilerData.RemoveAt(i);
                        --i;
                        stripCount++;
                        break; // break foreach loop
                    }
                }
            }

            Debug.Log(stripCount + " Eole shaders variant have been stripped.");
        }
    }
}