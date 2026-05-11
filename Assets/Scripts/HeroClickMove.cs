using UnityEngine;

[RequireComponent(typeof(CharacterController))]
public class HeroClickMove : MonoBehaviour
{
    public LayerMask groundMask;
    public float moveSpeed = 4f;
    public float gravity = -9.81f;

    private CharacterController controller;
    private Vector3 targetPos;
    private bool hasTarget;
    private float verticalVelocity;

    private void Awake()
    {
        controller = GetComponent<CharacterController>();
        targetPos = transform.position;
    }

    private void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            if (TryGetGroundPoint(out var point))
            {
                targetPos = point;
                hasTarget = true;
            }
        }

        var move = Vector3.zero;

        if (hasTarget)
        {
            var dir = (targetPos - transform.position);
            dir.y = 0f;
            if (dir.magnitude < 0.1f)
            {
                hasTarget = false;
            }
            else
            {
                move += dir.normalized * moveSpeed;
            }
        }

        // gravity
        if (controller.isGrounded && verticalVelocity < 0f)
            verticalVelocity = -2f;

        verticalVelocity += gravity * Time.deltaTime;
        move.y = verticalVelocity;

        controller.Move(move * Time.deltaTime);
    }

    private bool TryGetGroundPoint(out Vector3 point)
    {
        var ray = Camera.main.ScreenPointToRay(Input.mousePosition);
        if (Physics.Raycast(ray, out var hit, 1000f, groundMask))
        {
            point = hit.point;
            return true;
        }
        point = default;
        return false;
    }
}