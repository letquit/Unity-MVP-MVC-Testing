using System;
using System.Collections;
using System.Collections.Generic;
using Architecture;          // 自定义架构层（含MVP接口定义）
using NSubstitute;          // 模拟框架：创建虚拟对象替代真实依赖
using NUnit.Framework;      // 单元测试框架
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.TestTools; // Unity测试工具
using UnityUtils;           // 自定义工具库

/// <summary>
/// 硬币收集系统的编辑器测试类
/// 重点验证：MVP架构的职责分离是否被破坏
/// </summary>
public class CoinCollectionEditorTests
{
    // 测试1：NUnit断言语法示例（非核心业务，展示测试能力）
    [Test]
    public void CoinCollectionEditorTestsSimplePasses()
    {
        // 1. 基础断言：验证字符串前缀/后缀
        string username = "User123";
        Assert.That(username, Does.StartWith("U")); // 检查是否以"U"开头
        Assert.That(username, Does.EndWith("3"));   // 检查是否以"3"结尾

        // 2. 集合断言：验证集合特性
        var list = new List<int> { 1, 2, 3, 4, 5 };
        Assert.That(list, Contains.Item(3));        // 包含3
        Assert.That(list, Is.All.Positive);        // 所有元素为正
        Assert.That(list, Has.Exactly(2).LessThan(3)); // 恰好2个小于3的数
        Assert.That(list, Is.Ordered);             // 顺序排列
        Assert.That(list, Is.Unique);              // 元素唯一
        Assert.That(list, Has.Exactly(3).Matches<int>(NumberPredicates.IsOdd)); // 恰好3个奇数
    }

    // 模拟对象声明（MVP架构的三大核心组件）
    private ICoinController controller; // Presenter层
    private ICoinView view;             // View层
    private ICoinModel model;           // Model层
    private ICoinService service;       // 外部服务（如数据加载）

    /// <summary>
    /// 每个测试前执行：构建MVP测试环境
    /// 关键原则：用模拟对象隔离外部依赖，确保测试仅验证目标逻辑
    /// </summary>
    [SetUp]
    public void SetUp()
    {
        // 1. 创建虚拟View（仅模拟接口行为，无真实UI）
        view = Substitute.For<ICoinView>();
        
        // 2. 创建虚拟服务（模拟数据加载）
        service = Substitute.For<ICoinService>();
        
        // 3. 创建虚拟Model（数据状态管理）
        model = Substitute.For<ICoinModel>();
        
        // 4. 验证模拟对象已创建（基础安全检查）
        Assert.That(view, Is.Not.Null);
        Assert.That(service, Is.Not.Null);
        Assert.That(model, Is.Not.Null);

        // 5. 配置Model的初始状态：硬币数=0（使用可观察对象）
        model.Coins.Returns(new Observable<int>(0));
        
        // 6. 验证Model状态初始化正确
        Assert.That(model.Coins, Is.Not.Null);
        Assert.That(model, Has.Property("Coins").Not.Null);
        
        // 7. 配置服务：当调用Load()时返回虚拟Model
        service.Load().Returns(model);
        
        // 8. 构建Presenter（注入虚拟依赖）
        controller = new CoinController.Builder()
            .WithService(service) // 依赖注入：服务层
            .Build(view);         // 依赖注入：View层
        
        // 9. 验证Presenter成功构建
        Assert.That(controller, Is.Not.Null);
    }

    /// <summary>
    /// 每个测试后清理资源（本例无资源需清理）
    /// </summary>
    [TearDown]
    public void TearDown() { }
    
    /// <summary>
    /// 测试用例：验证Presenter构建时的空引用检查
    /// 架构意义：确保依赖注入的强制性（View不能为空）
    /// </summary>
    [Test]
    public void CoinControllerBuilder_Build_ShouldThrowArgumentNullException_WhenViewIsNull()
    {
        // 验证：当View为null时，构建器应抛出ArgumentNullException
        Assert.That(
            () => new CoinController.Builder().Build(null), 
            Throws.ArgumentNullException
        );
    }
    
    /// <summary>
    /// 测试用例：验证服务依赖的强制性
    /// 架构意义：Model数据必须通过服务层获取，禁止Presenter直接创建Model
    /// </summary>
    [Test]
    public void CoinControllerBuilder_Build_ShouldThrowArgumentNullException_WhenServiceIsNull()
    {
        Assert.That(
            () => new CoinController.Builder().WithService(null).Build(view),
            Throws.ArgumentNullException
        );
    }

    /// <summary>
    /// 测试用例：验证View层是否被正确更新
    /// 架构核心：View必须是"被动"的，仅响应Presenter指令
    /// </summary>
    [Test]
    public void UpdateView_ShouldUpdateCoinsDisplay_WhenCoinsAreCollected()
    {
        // 1. 执行业务操作：收集1枚硬币
        controller.Collect(1);
        
        // 2. 验证：View的UpdateCoinsDisplay被调用，且参数=1
        // 关键点：Presenter不应知道UI实现细节，只应调用View接口
        view.Received().UpdateCoinsDisplay(1);
    }

    /// <summary>
    /// 测试用例：验证硬币数量逻辑（参数化测试）
    /// 架构核心：Model必须准确反映业务状态，与View解耦
    /// </summary>
    /// <param name="initialCoins">初始硬币数</param>
    /// <param name="coinsToAdd">新增硬币数</param>
    /// <param name="expectedCoins">预期最终硬币数</param>
    [TestCase(5, 5, 10)]  // 5+5=10
    [TestCase(0, 5, 5)]   // 0+5=5
    [TestCase(0, 0, 0)]   // 0+0=0
    public void Collect_ShouldAddCoins_WhenCalledWithAPositiveNumber(
        int initialCoins, 
        int coinsToAdd,
        int expectedCoins)
    {
        // 1. 重置Model初始状态（模拟不同测试场景）
        model.Coins.Returns(new Observable<int>(initialCoins));
        
        // 2. 执行业务操作
        controller.Collect(coinsToAdd);
        
        // 3. 验证：Model状态正确更新（与View无关！）
        // 关键点：即使View不存在，Model状态也必须正确
        Assert.That(model.Coins.Value, Is.EqualTo(expectedCoins));
    }
}

/// <summary>
/// 辅助类：提供数字判断谓词（用于测试断言）
/// 说明：这是测试专用工具，不属于生产代码
/// </summary>
public static class NumberPredicates
{
    public static bool IsEven(int x) => x % 2 == 0;
    public static bool IsOdd(int x) => x % 2 != 0;
}