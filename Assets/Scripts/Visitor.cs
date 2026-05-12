using UnityEngine;

namespace Architecture
{
    /// <summary>
    /// 访问者接口：
    /// 定义了“访问”的标准行为。
    /// 使用泛型设计，使得一个访问者可以处理多种不同类型的 IVisitable 对象。
    /// </summary>
    public interface IVisitor
    {
        /// <summary>
        /// 访问方法：
        /// 对特定的可访问对象执行操作。
        /// 
        /// 泛型约束解释：
        /// - T : Component  => T 必须是 Unity 组件（如 MonoBehaviour）
        /// - IVisitable   => T 必须实现了 IVisitable 接口
        /// 
        /// 这种设计允许我们在同一个访问者中实现 Visit(CoinComponent) 和 Visit(EnemyComponent)。
        /// </summary>
        /// <typeparam name="T">被访问组件的具体类型</typeparam>
        /// <param name="visitable">被访问的组件实例</param>
        void Visit<T>(T visitable) where T : Component, IVisitable;
    }

    /// <summary>
    /// 可访问者接口：
    /// 这是一个“标记接口”（Marker Interface）。
    /// 它本身不包含方法，仅用于标识一个组件可以参与访问者模式。
    /// 
    /// 作用：
    /// 配合 IVisitor 的泛型约束，确保只有合法的组件才能被传递。
    /// </summary>
    public interface IVisitable
    {
        // 空接口，仅作为类型标识
    }
}