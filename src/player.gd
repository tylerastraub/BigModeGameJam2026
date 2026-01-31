extends Node3D

enum State {
    NOVAL = -1,
    GROUNDED,
    AERIAL,
    HALF_PIPE,
}

const ROTATION_SPEED : float = 4.0
const XFORM_SPEED : float = 20.0
const CAMERA_MOVE_LERP : float = 10.0
const CAMERA_ROTATE_LERP : float = 0.5

@onready var _rb : RigidBody3D = $RigidBody3D
@onready var _visuals : Node3D = $Smoothing/PlayerVisuals
@onready var _pivot : Node3D = $Smoothing/CameraPivot
@onready var _spring_arm : SpringArm3D = $Smoothing/CameraPivot/SpringArm
@onready var _raycasts : Node3D = $RigidBody3D/Raycasts

var _accel : float = 700.0
var _air_accel : float = 50.0
var _max_velocity : float = 10.0
var _min_velocity : float = 2.0

var _input_dir : Vector3 = Vector3.ZERO

var _state : State = State.NOVAL
var _last_state : State = State.NOVAL

func _ready() -> void:
    $RigidBody3D/BodyArea.area_entered.connect(_on_area_3d_area_entered)
    $RigidBody3D/BodyArea.area_exited.connect(_on_area_3d_area_exited)
    _rb._max_velocity = _max_velocity
    _rb._min_velocity = _min_velocity

func _physics_process(delta: float) -> void:
    var move_dir : float = atan2(-_rb.linear_velocity.normalized().x, -_rb.linear_velocity.normalized().z)
    _pivot.global_position = _pivot.global_position.move_toward(_rb.global_position + Vector3(0.0, 0.8, 0.0), delta * CAMERA_MOVE_LERP)
    _visuals.global_position = _rb.global_position
    _raycasts.global_position = _rb.global_position
    if(!is_equal_approx(_rb.linear_velocity.x, 0.0) or !is_equal_approx(_rb.linear_velocity.z, 0.0)):
        _pivot.rotation.y = lerp_angle(_pivot.rotation.y, move_dir, delta * _rb.linear_velocity.length() * CAMERA_ROTATE_LERP)
    _visuals.rotation.y = lerp_angle(_visuals.rotation.y, move_dir, delta * _rb.linear_velocity.length() * ROTATION_SPEED)
    var raycast_result := _check_raycasts()
    if raycast_result.size() > 0:
        var avg_normal : Vector3 = Vector3.ZERO
        for res in raycast_result:
            avg_normal += res.get_collision_normal()
        avg_normal /= raycast_result.size()
        var xform := align_with_y(_visuals.global_transform, avg_normal)
        _visuals.global_transform = _visuals.global_transform.interpolate_with(xform, delta * XFORM_SPEED)
    elif _rb.linear_velocity != Vector3.ZERO:
        var target_offset : Vector3 = Vector3.ZERO
        if abs(Vector3.UP.dot(_rb.linear_velocity.normalized())) > 0.98:
            target_offset.z = -0.01
        _visuals.look_at(_visuals.global_position + _rb.linear_velocity.normalized() + target_offset)
    
    _handle_states()
    _move(delta)
    _spring_arm._update(delta, _rb.linear_velocity.length() / _rb._max_velocity)

func _move(delta: float) -> void:
    if _state == State.HALF_PIPE:
            return
    _input_dir = Vector3.ZERO
    _input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    _input_dir.z = (Input.get_action_strength("move_backward") * 0.8) - Input.get_action_strength("move_forward")
    _input_dir = _input_dir.rotated(Vector3.UP, _pivot.rotation.y)
    if _input_dir.length() > 1.0: _input_dir = _input_dir.normalized()
    var accel : float = _air_accel if _state == State.AERIAL else _accel
    _rb.apply_central_force(_input_dir * delta * accel)

func _handle_states() -> void:
    if _check_raycasts().size() > 0:
        if (_state == State.HALF_PIPE and _rb.linear_velocity.y < 0.0) or _state == State.AERIAL:
            set_state(State.GROUNDED)
    elif _state != State.HALF_PIPE:
        set_state(State.AERIAL)

func _check_raycasts() -> Array[RayCast3D]:
    var result : Array[RayCast3D] = []
    for child in _raycasts.get_children():
        var raycast := child as RayCast3D
        if raycast.is_colliding():
            result.push_back(raycast)
    return result

func align_with_y(xform: Transform3D, new_y: Vector3) -> Transform3D:
    xform.basis.y = new_y
    xform.basis.x = -xform.basis.z.cross(new_y)
    xform.basis = xform.basis.orthonormalized()
    return xform

func set_state(state: State) -> void:
    if _state == state: return
    _last_state = _state
    _state = state
    _rb._player_state = _state

func _on_area_3d_area_entered(area: Area3D) -> void:
    var mask := String.num_int64(area.collision_layer, 2)
    var coefficient : float = 1.0 if area.global_position.x < _rb.global_position.x else -1.0
    if mask[mask.length() - 3] == "1":
        _rb._half_pipe_direction = coefficient
        set_state(State.HALF_PIPE)

func _on_area_3d_area_exited(area: Area3D) -> void:
    var mask := String.num_int64(area.collision_layer, 2)
    if mask[mask.length() - 3] == "1":
        _rb.apply_central_impulse(Vector3(0.2 * _rb._half_pipe_direction, _rb.linear_velocity.y, _rb.linear_velocity.z * 0.5))
    
