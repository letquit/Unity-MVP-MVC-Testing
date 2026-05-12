using UnityUtils; // 引入自定义工具库，用于参数检查

namespace Architecture
{
    /// <summary>
    /// 控制器接口：
    /// 定义了外部（如 CoinComponent）可以调用的公共行为。
    /// </summary>
    public interface ICoinController
    {
        void Collect(int coins); // 收集金币
        void UpdateView(int coins); // 强制刷新视图（通常由内部调用）
        void Save(); // 保存数据
        ICoinModel Load(); // 加载数据
    }

    /// <summary>
    /// 硬币控制器（Presenter）：
    /// MVP 架构的核心，负责连接 Model、View 和 Service。
    /// </summary>
    public class CoinController : ICoinController
    {
        private readonly ICoinModel model;
        private readonly ICoinView view;
        private readonly ICoinService service;

        /// <summary>
        /// 构造函数：
        /// 负责初始化依赖，并建立数据与视图的自动绑定。
        /// </summary>
        public CoinController(ICoinView view, ICoinService service)
        {
            // 1. 依赖检查：确保关键组件不为空
            Preconditions.CheckNotNull(view, "CoinView cannot be null");
            Preconditions.CheckNotNull(service, "CoinService cannot be null");
            
            this.view = view;
            this.service = service;

            // 2. 加载数据：从服务层获取初始 Model
            model = Load();

            // 3. 建立响应式绑定：
            // 当 model.Coins 的值发生变化时，自动调用 UpdateView 方法
            model.Coins.AddListener(UpdateView);
            
            // 4. 初始化视图：
            // 立即触发一次更新，确保 UI 显示初始值（而不是 0）
            model.Coins.Invoke();
        }

        /// <summary>
        /// 收集金币逻辑：
        /// 纯粹的逻辑操作，不涉及 UI 代码。
        /// 只需修改 Model，UI 会通过监听器自动更新。
        /// </summary>
        /// <param name="coins">本次收集的金币数量</param>
        public void Collect(int coins) 
        {
            // 更新 Model 的值
            // 注意：这里不需要手动调用 view.Update...，因为 AddListener 已经处理了
            model.Coins.Set(model.Coins.Value + coins);
        }

        /// <summary>
        /// 视图更新逻辑：
        /// 将 Model 的数据同步给 View。
        /// </summary>
        public void UpdateView(int coins) => view.UpdateCoinsDisplay(coins);

        /// <summary>
        /// 保存逻辑：
        /// 委托给 Service 层处理具体的存储实现（如写入文件）。
        /// </summary>
        public void Save() => service.Save(model);

        /// <summary>
        /// 加载逻辑：
        /// 委托给 Service 层获取数据。
        /// </summary>
        public ICoinModel Load() => service.Load();

        #region Builder
        /// <summary>
        /// 建造者模式：
        /// 用于链式构建 Controller，确保依赖注入的完整性和安全性。
        /// 使用示例：
        /// var controller = new CoinController.Builder()
        ///     .WithService(new CoinServiceMemory())
        ///     .Build(view);
        /// </summary>
        public class Builder
        {
            private ICoinService service;

            /// <summary>
            /// 注入服务层依赖
            /// </summary>
            public Builder WithService(ICoinService service)
            {
                this.service = Preconditions.CheckNotNull(service, "CoinService cannot be null");
                return this;
            }

            /// <summary>
            /// 构建最终对象
            /// </summary>
            public ICoinController Build(ICoinView view)
            {
                // 构建前最后一次检查所有依赖
                Preconditions.CheckNotNull(view, "CoinView cannot be null");
                Preconditions.CheckNotNull(service, "CoinService cannot be null");
                return new CoinController(view, service);
            }
        }
        #endregion
    }
}