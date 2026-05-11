//Eole
//Copyright protected under Unity Asset Store EULA

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Eole.Examples
{
    [System.Serializable]
    public class VectorFieldRenderer
    {
        public GameObject gameObject;
        public Renderer renderer;
        public float lifeTime = 1;

        public VectorFieldRenderer(GameObject gameObject, Renderer renderer)
        {
            this.gameObject = gameObject;
            this.renderer = renderer;

            //Set an instance to allow to use it in Editor
            if (renderer != null)
            {
                renderer.material = new Material(this.renderer.sharedMaterial);
            }
        }

        public void DecreaseLifetimeValue(float value)
        {
            if (renderer == null || gameObject == null)
                lifeTime = 0; // trigger minimum value to destroy the gameObject
            else
            {
                lifeTime -= value;
            }
        }

        public void SetAlphaValue(float value)
        {
#if UNITY_EDITOR
            if (renderer.sharedMaterial != null)
                renderer.sharedMaterial.SetFloat("_Alpha", value);
#else
        if (renderer.material != null)
            renderer.material.SetFloat("_Alpha", value);
#endif
        }
    }

    [ExecuteAlways]
    public class VectorFieldScattering : MonoBehaviour
    {
        public GameObject vectorFieldPrefab;
        public float spawnDelay = 1.5f;
        public float circleAreaRadius = 2;
        // Instance properties
        public float prefabLifetime = 2;
        public float prefabSizeMultiplier = 1;
        public AnimationCurve alphaOverlife = new();
        public AnimationCurve sizeOverlife = new();

        [SerializeField] private List<VectorFieldRenderer> renderers = new();

        private void OnEnable()
        {
            ClearSystem();
            StartCoroutine(InstantiateInCircleArea());
        }

        private void OnDisable()
        {
            ClearSystem();
        }

        private void Update()
        {
            if (renderers.Count <= 0)
                return;

            List<VectorFieldRenderer> renderersToRemove = new List<VectorFieldRenderer>();

            // Decrease alpha value
            for (int i = 0; i < renderers.Count; i++)
            {
                var rend = renderers[i];
                if (rend.lifeTime <= 0)
                {
                    if (rend.gameObject != null)
                        DestroyInstance(rend.gameObject);

                    // This renderer will be removed from list
                    renderersToRemove.Add(rend);
                }
                else
                {
                    // Alpha from animation curve
                    rend.DecreaseLifetimeValue(Time.deltaTime / prefabLifetime);
                    rend.SetAlphaValue(alphaOverlife.Evaluate(1 - rend.lifeTime));

                    // Size from animation curve
                    float size = sizeOverlife.Evaluate(1 - rend.lifeTime) * prefabSizeMultiplier;
                    rend.gameObject.transform.localScale = new Vector3(size, 1, size);
                }
            }

            // Remove instances marked for removal
            foreach (var rendToRemove in renderersToRemove)
            {
                renderers.Remove(rendToRemove);
            }
        }

        IEnumerator InstantiateInCircleArea()
        {
            Vector3 randomPos = GetRandomPositionInCircle();
            GameObject instance = Instantiate(vectorFieldPrefab, randomPos, Quaternion.identity);
            instance.transform.parent = transform;
            instance.transform.localScale = Vector3.zero;

            if (instance.TryGetComponent(out Renderer rend))
            {
                renderers.Add(new VectorFieldRenderer(instance, rend));
            }
            else
            {
                Debug.LogWarning("Missing a renderer. This prefab instance is invalid and has been destroyed.", this);
                DestroyInstance(instance);
            }

            yield return new WaitForSeconds(spawnDelay);
            StartCoroutine(InstantiateInCircleArea());
        }


        Vector3 GetRandomPositionInCircle()
        {
            // Random polar coord
            float randomAngle = Random.Range(0f, 2f * Mathf.PI);
            float randomRadius = Mathf.Sqrt(Random.Range(0f, 1f)) * circleAreaRadius;

            // Polar to cartesian
            float x = randomRadius * Mathf.Cos(randomAngle);
            float z = randomRadius * Mathf.Sin(randomAngle);

            float y = transform.position.y;

            Vector3 randomPos = new Vector3(x, y, z);

            // relative to this transform
            randomPos += transform.position;

            return randomPos;
        }

        void DestroyInstance(GameObject objectToDestroy)
        {
#if UNITY_EDITOR
            DestroyImmediate(objectToDestroy);
#else
            Destroy(objectToDestroy);
#endif
        }

        void ClearSystem()
        {
            StopAllCoroutines();

            // Destroy old instances and reset list
            foreach (var rend in renderers)
            {
                if (rend.gameObject != null)
                    DestroyInstance(rend.gameObject);
            }
            renderers.Clear();

            // Destroy remaining clone if list have been reinit
            foreach (Transform child in transform)
            {
                if (child.gameObject.name.Contains("Clone"))
                    DestroyImmediate(child.gameObject);
            }
        }

        private void OnDrawGizmosSelected()
        {
            Gizmos.DrawWireSphere(transform.position, circleAreaRadius);
        }
    }
}