//Eole
//Copyright protected under Unity Asset Store EULA

using UnityEngine;

namespace Eole
{
    //[ExecuteAlways]
    public class CameraCrush : MonoBehaviour
    {
        private Camera m_camera;
        private Color gammaColor = new Color(0.5f, 0.5f, 0);
        private Color linearColor = new Color(0.7225f, 0.7225f, 0);

        private void Start()
        {
            SetBackgroundColor();
        }

        public void SetBackgroundColor()
        {
            if (m_camera == null)
            {
                if (TryGetComponent(out Camera cam))
                    m_camera = cam;
                else
                    return;
            }

            // Set the right background color, depending on the color space
            if (IsColorSpaceGamma())
                m_camera.backgroundColor = gammaColor;
            else
                m_camera.backgroundColor = linearColor;
        }

        public static bool IsColorSpaceGamma()
        {
            return (QualitySettings.activeColorSpace == ColorSpace.Gamma);
        }
    }
}
