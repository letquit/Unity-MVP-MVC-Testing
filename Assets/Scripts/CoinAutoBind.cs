using Architecture;
using UnityEngine;

/// <summary>
/// 硬币系统自动绑定器：
/// 系统的“组合根”。
/// 负责在启动时组装 MVP 架构，并将控制器注入到场景中的所有硬币中。
/// </summary>
public class CoinAutoBind : MonoBehaviour
{
    // --- 依赖注入点 ---

    /// <summary>
    /// 视图引用：
    /// 在编辑器中将 UI 组件（CoinCounterView）拖入这里。
    /// 这是连接“游戏逻辑”与“UI 显示”的桥梁。
    /// </summary>
    public CoinCounterView view;

    /// <summary>
    /// 初始化阶段：
    /// 在游戏开始前，完成架构的组装和连接。
    /// </summary>
    private void Awake()
    {
        // 1. 构建控制器（Presenter）
        // 使用 Builder 模式，链式注入依赖：
        var controller = new CoinController.Builder()
            // 注入数据服务：这里使用的是内存服务（真实数据），而非测试用的模拟服务
            .WithService(new CoinServiceMemory())
            // 注入视图：绑定 UI
            .Build(view);

        // 2. 自动发现并注入场景对象
        // 查找场景中所有的 CoinComponent（即所有的硬币物体）
        foreach (var coin in FindObjectsOfType<CoinComponent>())
        {
            // 将构建好的控制器“注入”给每一个硬币
            // 这样，当玩家碰到任意一个硬币时，硬币都能通知到同一个控制器
            coin.controller = controller;
        }
    }
}