//Eole
//Copyright protected under Unity Asset Store EULA

using UnityEngine;
using UnityEngine.VFX;

namespace Eole.VFX
{
    [ExecuteAlways]
    public class VFXSetWindProperties : MonoBehaviour
    {
        public enum FXType
        {
            ParticleSystem,
            VisualEffect
        }

        public WindManager windManager;
        [Space(10)]
        public FXType fXType;
        public VisualEffect visualEffect;
        public new ParticleSystem particleSystem;
        
        // VISUAL EFFECT
        [Space(10)]
        [Header("Property Names")]
        public string windAmplitude = "_WindAmplitude";
        public string windSpeed = "_WindSpeed";
        public string windDirection = "_WindDirection";

        // PARTICLE SYSTEM
        [Space(10)]
        [Header("Particle Effect")]
        [Tooltip("Multiply the value of WindAmplitude, to set the Start Speed value.")] 
        public float startSpeed = 0.5f;
        public Vector2 rateOverTime = new Vector2(1, 5);

        [Space(10)]
        [Header("Fore Field")]
        public ParticleSystemForceField particleSystemForceField;
        public float forceFieldMultiplier = 1;
        [Space(10)]
        public bool isUpdatedEachFrame;


        private void OnEnable()
        {
            windManager ??= Utility.FindObject<WindManager>();
            visualEffect ??= GetComponent<VisualEffect>();
        }

        private void Awake()
        {
            // System Force Field oriented in the negative Y rotation of the tree
            if (fXType == FXType.ParticleSystem && particleSystemForceField != null)
            {
                Vector3 newEuler = particleSystemForceField.transform.parent.eulerAngles;
                newEuler.y = -transform.eulerAngles.y;

                particleSystemForceField.transform.rotation = Quaternion.LookRotation(Vector3.forward, Vector3.up);
            }
        }

        void Update()
        {
            if (isUpdatedEachFrame == false || windManager == null)
                return;

            if (fXType == FXType.VisualEffect && visualEffect == null ||
                fXType == FXType.ParticleSystem && particleSystem == null && particleSystemForceField == null)
                return;

            SetWindData();
        }

        public void SetWindData()
        {
            switch (fXType)
            {
                case FXType.ParticleSystem:
                    // Particle system start speed
                    var main = particleSystem.main;
                    main.startSpeed = startSpeed * windManager.GetAmplitude();

                    // Particle system rate over time
                    var emission = particleSystem.emission;
                    emission.rateOverTime = Mathf.Lerp(rateOverTime.x, rateOverTime.y, windManager.GetAmplitude());

                    // Particle system rotation
                    // Interpolate between two direction : Point down when amplitude = 0 and point in wind direction when amplitude = 1
                    float alpha = Mathf.Clamp(windManager.GetAmplitude(), 0.01f, 1); // Clamp with a little minimum value (not to zero) to avoid a glitchy orientation
                    Vector3 lerpDir = Vector3.Lerp(Vector3.down, windManager.GetDirection(), alpha);
                    particleSystem.transform.LookAt(particleSystem.transform.position + lerpDir);

                    // Force Field direction
                    Vector3 windDir = windManager.GetDirection() * windManager.GetAmplitude() * forceFieldMultiplier;
                    particleSystemForceField.directionX = windDir.x;
                    particleSystemForceField.directionY = windDir.y;
                    particleSystemForceField.directionZ = windDir.z;
                    break;

                case FXType.VisualEffect:
                    if (visualEffect.HasFloat(windAmplitude))
                        visualEffect.SetFloat(windAmplitude, windManager.GetAmplitude()); //* windManager.GetSpeed());
                    if (visualEffect.HasFloat(windSpeed))
                        visualEffect.SetFloat(windSpeed, windManager.GetSpeed());
                    if (visualEffect.HasVector3(windDirection))
                        visualEffect.SetVector3(windDirection, windManager.GetDirection()); //Debug.Log(windManager.GetDirection());
                    break;

                default:
                    break;

            }
        }
    }
}