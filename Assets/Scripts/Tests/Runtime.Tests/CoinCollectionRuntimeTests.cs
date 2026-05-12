using System.Collections;          // 协程支持
using Architecture;               // 自定义架构层（含IVisitor等接口）
using NSubstitute;               // 模拟框架（仍用于隔离业务逻辑）
using NUnit.Framework;           // 测试框架
using NUnit.Framework.Interfaces; // 自定义测试属性接口
#if UNITY_EDITOR
using UnityEditor.SceneManagement; // 编辑器场景操作
#endif
using UnityEngine;
using UnityEngine.SceneManagement; // 运行时场景管理
using UnityEngine.TestTools;       // Unity测试工具

/// <summary>
/// 硬币收集系统的运行时测试类
/// 重点验证：MonoBehaviour组件在真实游戏环境中的行为
/// </summary>
public class CoinCollectionRuntimeTests
{
    /// <summary>
    /// 验证测试在Unity播放模式下执行
    /// 关键意义：运行时测试必须在Application.isPlaying=true时运行
    /// </summary>
    [Test]
    public void VerifyApplicationPlaying()
    {
        // 运行时测试的核心前提：必须在Unity播放模式下
        Assert.That(Application.isPlaying, Is.True);
    }

    /// <summary>
    /// 验证指定场景是否正确加载
    /// 关键点：使用自定义[LoadScene]属性自动加载场景
    /// </summary>
    [Test]
    #if UNITY_EDITOR
    [LoadScene("Assets/Scenes/URP_EoleExample_Sea.unity")] // 编辑器下自动加载场景
    #endif
    public void VerifyScene()
    {
        // 1. 查找场景中的Hero对象（真实场景交互）
        var go = GameObject.Find("Hero");
        
        // 2. 输出调试信息（实际测试中应避免，此处仅演示）
        Debug.Log(go);
        Debug.Log(SceneManager.GetActiveScene().path);
        
        // 3. 验证关键对象存在
        // 注意：错误消息包含场景路径，便于定位问题
        Assert.That(
            go, 
            Is.Not.Null, 
            "Hero not found in {0}", 
            SceneManager.GetActiveScene().path
        );
    }

    /// <summary>
    /// 测试用例：验证访问者模式在Unity组件中的正确实现
    /// 关键意义：验证需要多帧完成的交互逻辑（如碰撞检测）
    /// </summary>
    [UnityTest]
    public IEnumerator Accept_ShouldExecuteVisit_WhenCalledWithVisitor()
    {
        // 1. 场景搭建（Given）
        var obj = new GameObject(); // 创建测试对象
        var coinComponent = obj.AddComponent<CoinComponent>(); // 添加硬币组件
        
        // 模拟Controller（隔离业务逻辑，仍用NSubstitute）
        coinComponent.controller = Substitute.For<ICoinController>();
        
        // 创建访问者对象
        var pickup = new GameObject();
        var visitor = pickup.AddComponent<TestVisitor>();
        
        // 2. 等待1帧：让Unity完成组件初始化（关键！）
        yield return null; 
        
        // 3. 执行交互（When）
        coinComponent.Accept(visitor);
        
        // 4. 等待1帧：让Unity处理Visit逻辑（关键时序点）
        yield return null; 
        
        // 5. 验证结果（Then）
        Assert.That(visitor.Visited, Is.True);
    }

    /// <summary>
    /// 测试专用访问者实现
    /// 说明：必须继承MonoBehaviour以验证Unity组件交互
    /// </summary>
    public class TestVisitor : MonoBehaviour, IVisitor
    {
        public bool Visited { get; private set; }

        public void Visit<T>(T visitable) where T : Component, IVisitable
        {
            Visited = true;
        }
    }
}

/// <summary>
/// 自定义属性：在测试前加载Unity场景（仅编辑器可用）
/// 关键原理：实现IOuterUnityTestAction接口控制测试流程
/// </summary>
#if UNITY_EDITOR
public class LoadSceneAttribute : NUnitAttribute, IOuterUnityTestAction 
{
    readonly string scene;
    
    public LoadSceneAttribute(string scene) => this.scene = scene;

    /// <summary>
    /// 在测试执行前加载场景
    /// </summary>
    public IEnumerator BeforeTest(ITest test) 
    {
        Debug.Assert(scene.EndsWith(".unity"), "Scene must end with .unity");
        
        // 使用编辑器API在播放模式下加载场景（保留Hierarchy）
        yield return EditorSceneManager.LoadSceneInPlayMode(
            scene, 
            new LoadSceneParameters(LoadSceneMode.Single)
        );
    }

    /// <summary>
    /// 测试后清理（本例无操作）
    /// </summary>
    public IEnumerator AfterTest(ITest test) 
    {
        yield return null;
    }
}
#endif