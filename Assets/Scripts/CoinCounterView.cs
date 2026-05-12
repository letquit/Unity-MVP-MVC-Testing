using Architecture;   // 引入架构层，获取 ICoinView 接口
using TMPro;          // 引入 TextMeshPro 命名空间，用于高性能文本渲染
using UnityEngine;

/// <summary>
/// 金币计数视图：
/// 实现了 ICoinView 接口，充当 MVP 架构中的“V”。
/// 它的唯一职责是更新 UI 文本，不包含任何业务逻辑。
/// </summary>
public class CoinCounterView : MonoBehaviour, ICoinView
{
    // --- UI 引用 ---

    /// <summary>
    /// 文本标签引用：
    /// 在 Unity 编辑器中，将场景里的 TextMeshPro 物体拖拽赋值给这个字段。
    /// </summary>
    public TextMeshProUGUI label;

    // --- 接口实现 ---

    /// <summary>
    /// 更新金币显示：
    /// 由控制器（CoinController）调用，用于同步数据到 UI。
    /// 
    /// 特点：
    /// 1. 被动：它不会自己决定什么时候更新，只能等控制器调用。
    /// 2. 简单：只做字符串拼接和赋值。
    /// </summary>
    /// <param name="coins">当前的金币数量</param>
    public void UpdateCoinsDisplay(int coins)
    {
        // 安全检查：确保 UI 组件已正确赋值
        if (label != null)
        {
            // 更新文本内容
            // 格式："Coins: 10"
            label.text = "Coins:" + coins.ToString();
        }
    }
}