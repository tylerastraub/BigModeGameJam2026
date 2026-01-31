extends RigidBody3D

enum State {
    NOVAL = -1,
    GROUNDED,
    AERIAL,
    HALF_PIPE,
}

var _max_velocity : float = 1.0
var _min_velocity : float = 1.0
var _player_state : State = State.NOVAL
var _half_pipe_direction : float = 0.0

func _integrate_forces(_state: PhysicsDirectBodyState3D) -> void:
    if _player_state == State.HALF_PIPE:
        linear_velocity.x = 0.05 * _half_pipe_direction
    if linear_velocity.length() > _max_velocity:
        linear_velocity = linear_velocity.normalized() * _max_velocity
    elif abs(linear_velocity.z) < _min_velocity and _player_state == State.GROUNDED:
        apply_central_force(Vector3(0.0, 0.0, -10.0))
