using UnityEngine;

namespace Architecture
{
    public interface IVisitor
    {
        void Visit<T>(T visitable) where T : Component, IVisitable;
    }

    public interface IVisitable
    {
    }
}