using UnityEngine;
using UnityUtils;

namespace Architecture
{
    public class CoinComponent : MonoBehaviour, IVisitable
    {
        public ICoinController controller;
        public int coinValue = 1;

        public void Accept(IVisitor visitor)
        {
            Preconditions.CheckNotNull(visitor, "Visitor cannot be null");
            visitor.Visit(this);
        }

        private void OnTriggerEnter(Collider other)
        {
            // Debug.Log($"Trigger: {other.name}, tag={other.tag}");

            if (!other.CompareTag("Player"))
                return;

            if (controller == null)
            {
                Debug.LogWarning("CoinComponent.controller is NULL");
                return;
            }

            controller.Collect(coinValue);
            Destroy(gameObject);
        }
    }
}