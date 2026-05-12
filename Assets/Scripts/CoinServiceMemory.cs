using Architecture;

/// <summary>
/// 内存硬币服务：
/// 一个临时的、基于内存的数据存储服务实现。
/// 数据不会持久化到磁盘，游戏关闭后数据会丢失。
/// 主要用于开发调试、单元测试或临时会话。
/// </summary>
public class CoinServiceMemory : ICoinService
{
    // --- 内部存储 ---

    /// <summary>
    /// 缓存的模型引用：
    /// 用于在内存中暂存数据。
    /// 注意：这是一个强引用，只要服务存在，Model 就不会被垃圾回收。
    /// </summary>
    private ICoinModel cached;

    /// <summary>
    /// 保存数据（内存版）：
    /// 实际上只是保存了 Model 的引用，并没有真正写入磁盘。
    /// </summary>
    /// <param name="model">要保存的模型</param>
    public void Save(ICoinModel model)
    {
        // 将传入的模型引用存储在缓存中
        cached = model;
    }

    /// <summary>
    /// 加载数据（内存版）：
    /// 从缓存中返回之前保存的模型。
    /// 如果缓存为空（例如首次启动），则返回一个新的默认模型。
    /// </summary>
    /// <returns>加载后的模型</returns>
    public ICoinModel Load()
    {
        // 如果缓存中有数据，返回缓存数据；否则返回一个新的 CoinModel（金币为0）
        return cached ?? new CoinModel();
    }
}