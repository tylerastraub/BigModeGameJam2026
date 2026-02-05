extends RigidBody3D

var _max_velocity : float = 1.0
var _min_forward_velocity : float = 1.0
var _decel : float = 0.8
var _player_state : Global.PlayerState = Global.PlayerState.GROUNDED
var _half_pipe_direction : float = 0.0
var _kill_velocity : bool = false
var _auto_move : bool = true

var counter : int = 0

func _integrate_forces(_state: PhysicsDirectBodyState3D) -> void:
    if _player_state == Global.PlayerState.HALF_PIPE:
        linear_velocity.x = 0.05 * _half_pipe_direction
    elif _player_state == Global.PlayerState.GRINDING:
        linear_velocity = Vector3.ZERO
    
    if (linear_velocity.y < -10.0):
        linear_velocity.y = -10.0
    if (linear_velocity * Vector3(1.0, 0.0, 1.0)).length() > _max_velocity:
        var vel_norm : Vector3 = linear_velocity.normalized()
        var horizontal_max : Vector3 = vel_norm * Vector3(1.0, 0.0, 1.0) * _max_velocity
        linear_velocity.x = move_toward(linear_velocity.x, horizontal_max.x, _decel)
        linear_velocity.z = move_toward(linear_velocity.z, horizontal_max.z, _decel)
    elif linear_velocity.z > _min_forward_velocity * -1 and _player_state == Global.PlayerState.GROUNDED and _auto_move:
        linear_velocity.z = _min_forward_velocity * -1
    elif _auto_move == false:
        linear_velocity = linear_velocity.lerp(Vector3.ZERO, 0.04)
        if linear_velocity.length() < 1.3:
            freeze = true
    
    if _kill_velocity:
        _kill_velocity = false
        linear_velocity = Vector3.ZERO

func _physics_process(_delta: float) -> void:
    if Global.debug:
        if linear_velocity.length() > 10.5:
            counter += 1
            print(str(counter) + ": " + str(linear_velocity.length()))
        else:
            counter = 0

func kill_velocity() -> void:
    _kill_velocity = true
