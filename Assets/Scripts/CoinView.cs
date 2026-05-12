namespace Architecture
{
    /// <summary>
    /// 硬币视图接口：
    /// 定义了 UI 显示的标准操作。
    /// 它是架构中的“表现层”抽象，负责隔离业务逻辑与具体的 UI 技术（如 Unity UI, NGUI, 控制台等）。
    /// </summary>
    public interface ICoinView
    {
        /// <summary>
        /// 更新金币显示：
        /// 接收最新的金币数量，并刷新界面。
        /// 
        /// 特点：
        /// - 被动：由 Controller 调用，View 不主动请求更新。
        /// - 单向：只接收数据，不返回结果。
        /// - 简单：参数只有一个 int，不包含任何 UI 控件引用。
        /// </summary>
        /// <param name="coins">当前的金币数量</param>
        void UpdateCoinsDisplay(int coins);
    }
}