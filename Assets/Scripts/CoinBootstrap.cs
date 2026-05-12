using Architecture;
using UnityEngine;

/// <summary>
/// 硬币系统启动器：
/// 系统的“组合根”。
/// 负责在 Awake 阶段构建整个 MVP 架构，并提供控制器的全局访问点。
/// </summary>
public class CoinBootstrap : MonoBehaviour
{
    // --- 依赖注入点 ---

    /// <summary>
    /// 视图引用：
    /// 在编辑器中将 UI 组件（CoinCounterView）拖入这里。
    /// 这是连接“游戏逻辑”与“UI 显示”的桥梁。
    /// </summary>
    public CoinCounterView view;

    // --- 核心组件 ---

    /// <summary>
    /// 控制器实例：
    /// 这是一个私有字段，意味着外部不能直接修改它。
    /// 它通常通过公共方法（如 GetController）暴露给 CoinComponent。
    /// </summary>
    private ICoinController controller;

    /// <summary>
    /// 初始化阶段：
    /// 在游戏开始前，完成架构的组装。
    /// </summary>
    private void Awake()
    {
        // 1. 创建数据服务
        // 这里硬编码了内存服务，但在大型项目中，这通常由配置决定
        var service = new CoinServiceMemory();

        // 2. 构建控制器（Presenter）
        // 使用 Builder 模式，链式注入依赖：
        controller = new CoinController.Builder()
            .WithService(service) // 注入数据服务
            .Build(view);         // 注入视图
    }
}