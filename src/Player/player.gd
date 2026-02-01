extends Node3D

const ROTATION_SPEED : float = 4.0
const XFORM_SPEED : float = 10.0
const CAMERA_MOVE_LERP : float = 20.0
const CAMERA_ROTATE_LERP : float = 0.5

@onready var _rb : RigidBody3D = $RigidBody3D
@onready var _visuals : Node3D = $PlayerVisuals
@onready var _pivot : Node3D = $CameraPivot
@onready var _spring_arm : SpringArm3D = $CameraPivot/SpringArm
@onready var _raycasts : Node3D = $RigidBody3D/Raycasts

# Movement Vars
var _accel : float = 700.0
var _air_accel : float = 50.0
var _max_velocity : float = 10.0
var _min_velocity : float = 3.0

# States
var _state : Global.PlayerState = Global.PlayerState.NOVAL
var _last_state : Global.PlayerState = Global.PlayerState.NOVAL

# Grinding
var _grind_rail : GrindRail = null
var _grind_speed : float = 1.0
var _min_grind_speed : float = 7.0

# Aerial
var _starting_aerial_angle : float = 0.0
var _total_aerial_rotation : float = 0.0
var _aerial_rotate_speed : float = 7.0

# Misc
var _input_dir : Vector3 = Vector3.ZERO

# Debug
var forward_dir : Vector3 = Vector3.ZERO
var up_dir : Vector3 = Vector3.ZERO
var debug : bool = true

func _ready() -> void:
    $RigidBody3D/BodyArea.area_entered.connect(_on_area_3d_area_entered)
    $RigidBody3D/BodyArea.area_exited.connect(_on_area_3d_area_exited)
    _rb._max_velocity = _max_velocity
    _rb._min_velocity = _min_velocity
    if debug:
        $Debug.draw.add_vector(self, "forward_dir", 1, 4, Color.RED, $PlayerVisuals)
        $Debug.draw.add_vector(self, "up_dir", 1, 4, Color.BLUE, $PlayerVisuals)

func _physics_process(delta: float) -> void:
    _pivot.global_position = _pivot.global_position.move_toward(_rb.global_position + Vector3(0.0, 0.8, 0.0), delta * CAMERA_MOVE_LERP)
    _visuals.global_position = _rb.global_position
    _raycasts.global_position = _rb.global_position
    
    _handle_orientation(delta)
    _handle_states()
    _grind(delta)
    _aerial(delta)
    _move(delta)
    var relative_velocity : float = 1.0
    if _state != Global.PlayerState.GRINDING:
        relative_velocity = _rb.linear_velocity.length() / _rb._max_velocity
    _spring_arm._update(delta, is_player_actionable(), relative_velocity)
    print(_visuals.rotation.y)

func _move(delta: float) -> void:
    _input_dir = Vector3.ZERO
    _input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    _input_dir.z = (Input.get_action_strength("move_backward") * 0.6) - Input.get_action_strength("move_forward")
    _input_dir = _input_dir.rotated(Vector3.UP, _pivot.rotation.y)
    if _input_dir.length() > 1.0: _input_dir = _input_dir.normalized()
    if is_player_actionable() == false:
            return
    var accel : float = _air_accel if _state == Global.PlayerState.AERIAL else _accel
    _rb.apply_central_force(_input_dir * delta * accel)

func _handle_states() -> void:
    if _check_raycasts().size() > 0:
        if (_state == Global.PlayerState.HALF_PIPE and _rb.linear_velocity.y < 0.0) or _state == Global.PlayerState.AERIAL:
            set_state(Global.PlayerState.GROUNDED)
    elif _state != Global.PlayerState.HALF_PIPE and _state != Global.PlayerState.GRINDING:
        set_state(Global.PlayerState.AERIAL)

func _handle_orientation(delta: float) -> void:
    var move_dir : float = atan2(-_rb.linear_velocity.normalized().x, -_rb.linear_velocity.normalized().z)
    if(_state == Global.PlayerState.GRINDING):
        _pivot.rotation.y = lerp_angle(_pivot.rotation.y, 0.0, delta * 10.0 * CAMERA_ROTATE_LERP)
        _visuals.rotation.y = lerp_angle(_visuals.rotation.y, 0.0, delta * 10.0 * ROTATION_SPEED)
    elif(!is_equal_approx(_rb.linear_velocity.x, 0.0) or !is_equal_approx(_rb.linear_velocity.z, 0.0)):
        _pivot.rotation.y = lerp_angle(_pivot.rotation.y, move_dir, delta * _rb.linear_velocity.length() * CAMERA_ROTATE_LERP)
        if(_state != Global.PlayerState.AERIAL):
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
        # idk
        _visuals.look_at((_visuals.global_position + _rb.linear_velocity.normalized() + target_offset).rotated(_visuals.basis.y, _total_aerial_rotation))
    forward_dir = _rb.linear_velocity.normalized()
    up_dir = _visuals.basis.y

func _check_raycasts() -> Array[RayCast3D]:
    var result : Array[RayCast3D] = []
    for child in _raycasts.get_children():
        var raycast := child as RayCast3D
        if raycast.is_colliding():
            result.push_back(raycast)
    return result

func _grind(delta: float) -> void:
    if _state != Global.PlayerState.GRINDING:
        return
    if _grind_rail == null:
        set_state(Global.PlayerState.AERIAL)
        return
    _grind_rail.move_grind_pos(_grind_speed * delta)
    _rb.global_position = _grind_rail.get_grind_pos()
    if _grind_rail.get_grind_ratio() > 0.98:
        _stop_grind()

func _start_grind(rail: GrindRail) -> void:
    set_state(Global.PlayerState.GRINDING)
    _grind_rail = rail
    _grind_speed = max(_rb.linear_velocity.length(), _min_grind_speed)
    _grind_rail.set_grind_pos(_grind_rail.find_nearest_start_ratio(_rb.global_position))
    _rb.global_position = _grind_rail.get_grind_pos()

func _stop_grind() -> void:
    set_state(Global.PlayerState.AERIAL)
    _grind_rail = null
    var exit_vel : Vector3 = Vector3((Input.get_action_strength("move_right") - Input.get_action_strength("move_left")) * 0.4, 0.2, -1.0)
    _rb.apply_central_impulse(exit_vel.normalized() * _max_velocity)

func _aerial(delta: float) -> void:
    if _state != Global.PlayerState.AERIAL:
        return
    var val : float = (Input.get_action_strength("move_left") - Input.get_action_strength("move_right")) * delta * _aerial_rotate_speed
    _total_aerial_rotation += val

func align_with_y(xform: Transform3D, new_y: Vector3) -> Transform3D:
    xform.basis.y = new_y
    xform.basis.x = -xform.basis.z.cross(new_y)
    xform.basis = xform.basis.orthonormalized()
    return xform

func set_state(state: Global.PlayerState) -> void:
    if _state == state: return
    _last_state = _state
    _state = state
    _rb._player_state = _state
    
    if state == Global.PlayerState.AERIAL:
        _starting_aerial_angle = _visuals.rotation.y
        _total_aerial_rotation = 0.0

func is_player_actionable() -> bool:
    return _state != Global.PlayerState.HALF_PIPE and _state != Global.PlayerState.GRINDING and _state != Global.PlayerState.AERIAL

func _on_area_3d_area_entered(area: Area3D) -> void:
    var mask := String.num_int64(area.collision_layer, 2)
    var coefficient : float = 1.0 if area.global_position.x < _rb.global_position.x else -1.0
    if mask[mask.length() - 3] == "1":
        _rb._half_pipe_direction = coefficient
        set_state(Global.PlayerState.HALF_PIPE)
    elif mask[mask.length() - 4] == "1":
        _start_grind(area as GrindRail)

func _on_area_3d_area_exited(area: Area3D) -> void:
    var mask := String.num_int64(area.collision_layer, 2)
    if mask[mask.length() - 3] == "1":
        _rb.apply_central_impulse(Vector3(0.2 * _rb._half_pipe_direction, _rb.linear_velocity.y, _rb.linear_velocity.z * 0.5))
    
