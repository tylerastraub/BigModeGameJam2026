extends SpringArm3D

@onready var _camera : Camera3D = $Camera

const CAMERA_TILT_SPEED : float = 1.0
var _max_camera_tilt : float = 5.0
var _default_camera_tilt : float = -15.0

const FOV_ZOOM_SPEED : float = 5.0
var _fov_default : float = 54
var _fov_speed_mod : float = 20
var _fov_accel_mod : float = 16

func _update(delta: float, player_actionable: bool, vel_scale: float) -> void:
    var no_rotate_input : Vector3 = Vector3.ZERO
    if player_actionable:
        no_rotate_input.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
        no_rotate_input.z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
    rotation.x = move_toward(rotation.x, deg_to_rad(_default_camera_tilt) + deg_to_rad(_max_camera_tilt) * no_rotate_input.z, delta * CAMERA_TILT_SPEED)
    rotation.z = move_toward(rotation.z, deg_to_rad(_max_camera_tilt) * no_rotate_input.x * -1, delta * CAMERA_TILT_SPEED)
    
    var fov_target : float = _fov_default + _fov_accel_mod * max(no_rotate_input.z * -1, 0.0) + _fov_speed_mod * vel_scale
    _camera.fov = lerpf(_camera.fov, fov_target, delta * FOV_ZOOM_SPEED)
