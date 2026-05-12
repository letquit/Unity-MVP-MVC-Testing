using System;       // 引入 System 命名空间，支持 [Serializable] 特性
using UnityUtils;   // 引入自定义工具库，包含 Observable 类

namespace Architecture
{
    /// <summary>
    /// 模型接口：
    /// 定义了 Model 必须具备的能力：
    /// 1. 提供可观察的金币数据
    /// 2. 能够序列化（保存）
    /// 3. 能够反序列化（读取）
    /// </summary>
    public interface ICoinModel
    {
        Observable<int> Coins { get; } // 获取金币的可观察对象

        CoinData Serialize();          // 将当前状态转换为可保存的数据结构
        void Deserialize(CoinData savedData); // 从保存的数据结构中恢复状态
    }
    
    /// <summary>
    /// 硬币模型（实现类）：
    /// 系统的“单一数据源”（Single Source of Truth）。
    /// 它不关心 UI 怎么显示，也不关心数据存在哪，只关心数据本身的状态。
    /// </summary>
    public class CoinModel : ICoinModel
    {
        /// <summary>
        /// 金币数量：
        /// 使用 Observable<int> 包装，使其具备“发布-订阅”功能。
        /// 初始值为 0。
        /// </summary>
        public Observable<int> Coins { get; } = new Observable<int>(0);

        /// <summary>
        /// 序列化：
        /// 将当前的内存数据（Coins.Value）提取出来，打包成 CoinData 结构体。
        /// 这个结构体随后会被 Service 层写入磁盘。
        /// </summary>
        /// <returns>包含当前金币数的数据结构</returns>
        public CoinData Serialize()
        {
            return new CoinData { coins = Coins.Value };
        }

        /// <summary>
        /// 反序列化：
        /// 当游戏启动或读取存档时，Service 层会读取数据并调用此方法。
        /// 它会将外部数据加载回 Model，并触发 Coins 的变更通知（通过 Set 方法）。
        /// </summary>
        /// <param name="savedData">从磁盘读取的存档数据</param>
        public void Deserialize(CoinData savedData)
        {
            // 使用 Set 而不是直接赋值，是为了触发 Observable 的事件通知
            Coins.Set(savedData.coins);
        }
    }

    /// <summary>
    /// 硬币数据结构：
    /// 这是一个纯数据类（POCO），用于 JSON 序列化或二进制存储。
    /// 使用 struct 是为了轻量级和值类型传递。
    /// [Serializable] 特性告诉 Unity/系统：这个类可以被序列化（保存）。
    /// </summary>
    [Serializable]
    public struct CoinData
    {
        public int coins; // 对应 Model 中的金币数量
    }
}