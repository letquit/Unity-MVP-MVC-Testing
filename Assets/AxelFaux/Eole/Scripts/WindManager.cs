//Eole
//Copyright protected under Unity Asset Store EULA

using UnityEngine;

namespace Eole
{
    [ExecuteAlways]
    public class WindManager : MonoBehaviour
    {
        public WindZone windZone;

        #region WindZone (Source) Properties
        public WindSource windSource = WindSource.Custom;
        [Tooltip("Calculates wind \"Amplitude\" by multiplying WindZone's \"Main\" parameter.")]
        public float windStrengthMultiplier = 1f; // Multiply the WindZone's "Main" value
        [Tooltip("Calculates wind \"Speed\" by multiplying WindZone's \"Turbulence\" parameter.")]
        public float windSpeedMultiplier = 1f; // Multiply the WindZone's "Turbulence" value
        #endregion

        [Range(0, 1)] public float amplitude = 1;
        public float speed = 4;

        private GlobalShaderWind m_globalShaderWind;

        private void Awake()
        {
            m_globalShaderWind ??= GetComponent<GlobalShaderWind>();
        }

        public void ApplyModification()
        { 
            if (m_globalShaderWind == null) return;

            m_globalShaderWind.ApplyGlobalPropertiesWind();
        }

        public float GetAmplitude()
        {
            if (windSource == WindSource.WindZone)
            {
                // Return another Amplitude calculated from windZone and return it
                if (windZone != null)
                    return Mathf.Clamp(windZone.windMain * windStrengthMultiplier, 0, 1);
            }

            return amplitude;
        }
        public float GetSpeed()
        {
            if (windSource == WindSource.WindZone)
            {
                // Return another Speed calculated from windZone and return it
                if (windZone != null)
                    return windZone.windTurbulence * windSpeedMultiplier;
            }

            return speed;
        }
        public Vector3 GetDirection() 
        {
            if (windSource == WindSource.WindZone)
            {
                if (windZone != null)
                    return windZone.transform.forward;
            }

            return transform.forward;
        }
        public float GetAngleInRadian()
        {
            var forwardTransform = transform; //.forward;

            if (windSource == WindSource.WindZone && windZone != null)
                forwardTransform = windZone.transform; //.forward;

            return (forwardTransform.eulerAngles.y % 360) * Mathf.Deg2Rad; //Mathf.Acos(Vector3.Dot(new Vector3(0,0,1), forwardTransform));
        }

        #region Gizmos
#if UNITY_EDITOR
        private Mesh arrowMesh;

        private void OnDrawGizmos()
        {

            if (TryGetArrowMesh(out Mesh mesh))
            {
                Gizmos.color = new Color(1, 1, 1, 0.5f);
                Gizmos.DrawMesh(mesh, transform.position, Quaternion.FromToRotation(new Vector3(0,0,1), transform.forward), Vector3.one);
                Gizmos.color = new Color(1, 1, 1, 0.3f);
                Gizmos.DrawWireMesh(mesh, transform.position, Quaternion.FromToRotation(new Vector3(0, 0, 1), transform.forward), Vector3.one);
            }
            else
                Gizmos.DrawCube(transform.transform.position, Vector3.one);

        }
        private void OnDrawGizmosSelected()
        {
            if (TryGetArrowMesh(out Mesh mesh))
            {
                Gizmos.color = new Color(1, 0.5f, 0, 1);
                Gizmos.DrawWireMesh(mesh, transform.position, Quaternion.FromToRotation(new Vector3(0, 0, 1), transform.forward), Vector3.one);
            }
        }

        private bool TryGetArrowMesh(out Mesh mesh)
        {
            mesh = arrowMesh;

            if (arrowMesh == null)
            {
                mesh = arrowMesh = Resources.Load<Mesh>("Meshes/SM_Arrow");
            }

            if (arrowMesh == null)
                return false;
            else
                return true;
        }
#endif
#endregion

    }
    public enum WindSource
    {
        Custom,
        WindZone
    }
}
