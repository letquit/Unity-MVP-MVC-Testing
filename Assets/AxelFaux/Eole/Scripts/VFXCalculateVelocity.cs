//Eole
//Copyright protected under Unity Asset Store EULA

using UnityEngine.VFX;
using UnityEngine;

namespace Eole.VFX
{
    [ExecuteAlways]
    public class VFXCalculateVelocity : MonoBehaviour
    {
        // This script is an alternative to calculate transform's velocity,
        // as it seems to doesn't work in Visual Effects Graph.

        [Header("Visual Effect component only"), Space(10)]
        public bool executeInEditor = true;

        [SerializeField] private VisualEffect visualEffect;
        [SerializeField] private Vector3 oldPosition;
        [SerializeField] private Vector3 currentVelocity; // also as current euler

        void Awake()
        {
            visualEffect = GetComponent<VisualEffect>();
        }

        private void OnEnable()
        {
            visualEffect = GetComponent<VisualEffect>();
        }

        void Start()
        {
            oldPosition = transform.position;
        }

#if UNITY_EDITOR
        private void Update()
        {
            if (visualEffect == null)
                return;

            if (executeInEditor)
            {
                CalculateVelocity(Time.deltaTime);
                SetVelocity();
            }

            /*ParticleSystem ps = GetComponent<ParticleSystem>();
            ps.customData.SetVector()*/
        }
#else 
    void FixedUpdate()
    {
        CalculateVelocity(Time.fixedDeltaTime);
        SetVelocity();
    }
#endif

        private void CalculateVelocity(float deltaTime)
        {
            currentVelocity = (transform.position - oldPosition) / deltaTime;
            oldPosition = transform.position;
        }

        private void SetVelocity()
        {
            if (visualEffect == null)
                return;

            if (visualEffect.HasVector3("Velocity"))
                visualEffect.SetVector3("Velocity", currentVelocity);
        }
    }
}