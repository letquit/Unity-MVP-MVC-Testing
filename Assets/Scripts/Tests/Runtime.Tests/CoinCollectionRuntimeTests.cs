using System.Collections;
using Architecture;
using NSubstitute;
using NUnit.Framework;
using NUnit.Framework.Interfaces;
#if UNITY_EDITOR
using UnityEditor.SceneManagement;
#endif
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.TestTools;

public class CoinCollectionRuntimeTests
{
    [Test]
    public void VerifyApplicationPlaying()
    {
        Assert.That(Application.isPlaying, Is.True);
    }

    [Test]
#if UNITY_EDITOR
    [LoadScene("Assets/Scenes/URP_EoleExample_Sea.unity")]
#endif
    public void VerifyScene()
    {
        var go = GameObject.Find("Hero");
        Debug.Log(go);
        Debug.Log(SceneManager.GetActiveScene().path);
        Assert.That(go, Is.Not.Null, "Hero not found in {0}", SceneManager.GetActiveScene().path);
    }

    [UnityTest]
    public IEnumerator Accept_ShouldExecuteVisit_WhenCalledWithVisitor()
    {
        // Given
        var obj = new GameObject();
        var coinComponent = obj.AddComponent<CoinComponent>();
        coinComponent.controller = Substitute.For<ICoinController>();
        
        var pickup = new GameObject();
        var visitor = pickup.AddComponent<TestVisitor>();
        yield return null;  // Let the scene setup
        
        // When
        coinComponent.Accept(visitor);
        yield return null;  // Let the scene update
        
        // Then
        Assert.That(visitor.Visited, Is.True);
    }

    public class TestVisitor : MonoBehaviour, IVisitor
    {
        public bool Visited { get; private set; }

        public void Visit<T>(T visitable) where T : Component, IVisitable
        {
            Visited = true;
        }
    }
}

#if UNITY_EDITOR
public class LoadSceneAttribute : NUnitAttribute, IOuterUnityTestAction {
    readonly string scene;
    
    public LoadSceneAttribute(string scene) => this.scene = scene;

    public IEnumerator BeforeTest(ITest test) {
        Debug.Assert(scene.EndsWith(".unity"), "Scene must end with .unity");
        yield return EditorSceneManager.LoadSceneInPlayMode(scene, new LoadSceneParameters(LoadSceneMode.Single));
    }

    public IEnumerator AfterTest(ITest test) {
        yield return null;
    }
}
#endif
