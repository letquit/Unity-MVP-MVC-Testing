//Eole
//Copyright protected under Unity Asset Store EULA

using UnityEngine;

namespace Eole.Examples
{
    [ExecuteAlways]
    public class AutoMove : MonoBehaviour
    {
        public Transform[] pathPositions;
        public float waitTime = 0.5f;
        public float moveSpeed = 2f;

        private int currentTarget = 0;

        void Update()
        {
            if (pathPositions.Length == 0)
                return;

            Move();
        }

        void Move()
        {
            if (pathPositions[currentTarget] == null)
            {
                Debug.LogWarning("Object is freezed as the current target is invalid.", this);
                return;
            }
            else
            {
                Vector3 newPosition = Vector3.Slerp(transform.position, pathPositions[currentTarget].position, Time.deltaTime * moveSpeed);
                newPosition.y = transform.position.y; // override y position
                transform.position = newPosition;
                RequestTargetReached();
            }
        }

        void RequestTargetReached()
        {
            float distance = Vector3.Distance(transform.position, pathPositions[currentTarget].position);

            if (distance <= 1.5f)
            {
                currentTarget++;
                if (currentTarget >= pathPositions.Length)
                    currentTarget = 0;
            }
        }
    }
}