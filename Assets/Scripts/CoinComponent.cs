using UnityEngine;
using UnityUtils; // 引入自定义工具库（包含 Preconditions 检查）

namespace Architecture
{
    /// <summary>
    /// 硬币组件：
    /// 挂载在场景中的硬币预制体上。
    /// 负责检测玩家碰撞，并通知控制器处理收集逻辑。
    /// 同时支持访问者模式以扩展交互行为。
    /// </summary>
    public class CoinComponent : MonoBehaviour, IVisitable
    {
        // --- 依赖注入 ---

        /// <summary>
        /// 控制器引用：
        /// 由启动器（如 CoinAutoBind）在 Awake 阶段注入。
        /// 它是连接“游戏世界”与“业务逻辑”的桥梁。
        /// </summary>
        public ICoinController controller;

        /// <summary>
        /// 硬币面值：
        /// 可以在编辑器中配置，支持不同价值的硬币（如金币=10，银币=1）。
        /// </summary>
        public int coinValue = 1;

        // --- 访问者模式 ---

        /// <summary>
        /// 接受访问者：
        /// 允许外部逻辑（Visitor）在不修改本类的情况下扩展行为。
        /// 
        /// 安全性：
        /// 使用 Preconditions 检查 visitor 是否为空，防止空引用异常。
        /// </summary>
        /// <param name="visitor">访问者实例</param>
        public void Accept(IVisitor visitor)
        {
            Preconditions.CheckNotNull(visitor, "Visitor cannot be null");
            visitor.Visit(this); // 回调访问者的 Visit 方法，将自身（this）传进去
        }

        // --- 物理交互 ---

        /// <summary>
        /// 触发器进入事件：
        /// 当其他碰撞体进入硬币的触发范围时调用。
        /// 前提：硬币的 Collider 必须勾选 "Is Trigger"。
        /// </summary>
        /// <param name="other">碰撞到的物体</param>
        private void OnTriggerEnter(Collider other)
        {
            // 1. 标签过滤：只响应 "Player" 标签的物体
            // 优化：使用 CompareTag 而不是 string 比较，性能更好
            if (!other.CompareTag("Player"))
                return;

            // 2. 安全检查：确保控制器已注入
            // 如果启动器未正确配置，这里会报警告而不是报错崩溃
            if (controller == null)
            {
                Debug.LogWarning("CoinComponent.controller is NULL");
                return;
            }

            // 3. 执行业务逻辑：
            // 通知控制器“我收集了一个价值为 coinValue 的硬币”
            // 控制器会负责更新 Model 和 View
            controller.Collect(coinValue);

            // 4. 表现层反馈：
            // 销毁硬币物体，实现“拾取消失”的效果
            Destroy(gameObject);
        }
    }
}