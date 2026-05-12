namespace Architecture
{
    /// <summary>
    /// 硬币服务接口：
    /// 定义了数据持久化的标准操作。
    /// 它是架构中的“基础设施层”抽象，负责隔离业务逻辑与具体的存储技术。
    /// </summary>
    public interface ICoinService
    {
        /// <summary>
        /// 保存数据：
        /// 接收当前的 Model 状态，将其持久化到磁盘、数据库或云端。
        /// 
        /// 特点：
        /// - 单向操作：数据从内存 -> 外部存储
        /// - 无返回值：通常不需要返回结果，除非需要处理保存失败的异常
        /// </summary>
        /// <param name="model">包含当前金币数据的模型接口</param>
        void Save(ICoinModel model);

        /// <summary>
        /// 加载数据：
        /// 从外部存储读取数据，并构建/还原一个 Model 对象。
        /// 
        /// 特点：
        /// - 单向操作：数据从外部存储 -> 内存
        /// - 返回模型：返回一个填充好数据的 ICoinModel，供 Controller 使用
        /// </summary>
        /// <returns>加载后的硬币模型</returns>
        ICoinModel Load();
    }
}