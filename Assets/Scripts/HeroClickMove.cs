using UnityEngine;

/// <summary>
/// 英雄点击移动脚本：
/// 实现类似MOBA游戏的鼠标点击移动功能。
/// 依赖 CharacterController 组件进行移动控制。
/// </summary>
[RequireComponent(typeof(CharacterController))]
public class HeroClickMove : MonoBehaviour
{
    // --- 配置参数 ---

    /// <summary>
    /// 地面层级掩码：
    /// 用于射线检测，确保只检测地面，忽略其他物体。
    /// 在Inspector中设置对应的Layer（如 "Ground"）。
    /// </summary>
    public LayerMask groundMask;

    /// <summary>
    /// 移动速度：每秒移动的米数。
    /// </summary>
    public float moveSpeed = 4f;

    /// <summary>
    /// 重力加速度：模拟真实世界的重力（-9.81 m/s²）。
    /// </summary>
    public float gravity = -9.81f;

    // --- 私有变量 ---

    private CharacterController controller;
    private Vector3 targetPos; // 目标位置
    private bool hasTarget;    // 是否拥有有效目标
    private float verticalVelocity; // 垂直速度（用于重力）

    private void Awake()
    {
        // 获取组件引用
        controller = GetComponent<CharacterController>();
        // 初始化目标位置为当前位置，防止一开始就乱飞
        targetPos = transform.position;
    }

    private void Update()
    {
        // 1. 输入检测：鼠标左键点击
        if (Input.GetMouseButtonDown(0))
        {
            // 尝试获取地面上的点击点
            if (TryGetGroundPoint(out var point))
            {
                targetPos = point;
                hasTarget = true;
            }
        }

        // 2. 移动逻辑计算
        var move = Vector3.zero;

        if (hasTarget)
        {
            // 计算朝向目标的向量
            var dir = (targetPos - transform.position);
            dir.y = 0f; // 锁定Y轴，防止角色飞起来或钻地

            // 到达检测：如果距离足够近，停止移动
            if (dir.magnitude < 0.1f)
            {
                hasTarget = false;
            }
            else
            {
                // 计算目标旋转
                Quaternion targetRotation = Quaternion.LookRotation(dir);
                // 平滑旋转角色朝向
                transform.rotation = Quaternion.RotateTowards(transform.rotation, targetRotation, 100f * Time.deltaTime);
                // 计算水平移动向量
                move += dir.normalized * moveSpeed;
            }
        }

        // 3. 重力与垂直逻辑
        // 如果在地面且垂直速度向下，则重置为微小负值（确保贴地）
        if (controller.isGrounded && verticalVelocity < 0f)
            verticalVelocity = -2f;

        // 应用重力加速度
        verticalVelocity += gravity * Time.deltaTime;
        move.y = verticalVelocity; // 将垂直速度应用到移动向量中

        // 4. 执行移动
        // CharacterController.Move 需要乘以 Time.deltaTime 以保证帧率无关
        controller.Move(move * Time.deltaTime);
    }

    /// <summary>
    /// 射线检测辅助方法：
    /// 从摄像机发射射线，检测鼠标点击位置的地面坐标。
    /// </summary>
    /// <param name="point">输出的地面坐标</param>
    /// <returns>是否检测到了地面</returns>
    private bool TryGetGroundPoint(out Vector3 point)
    {
        // 创建从摄像机到鼠标的射线
        var ray = Camera.main.ScreenPointToRay(Input.mousePosition);
        
        // 执行射线检测
        // 1000f: 最大检测距离
        // groundMask: 只检测指定层级的物体
        if (Physics.Raycast(ray, out var hit, 1000f, groundMask))
        {
            point = hit.point;
            return true;
        }
        
        point = default;
        return false;
    }
}