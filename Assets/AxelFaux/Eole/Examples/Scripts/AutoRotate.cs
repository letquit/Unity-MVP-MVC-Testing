//Eole
//Copyright protected under Unity Asset Store EULA

using UnityEngine;

namespace Eole.Examples
{
    [ExecuteAlways]
    public class AutoRotate : MonoBehaviour
    {
        public Vector3 speed = new Vector3(0, 30, 0);

        // Update is called once per frame
        void Update()
        {
            transform.Rotate(speed * Time.deltaTime);
        }
    }
}