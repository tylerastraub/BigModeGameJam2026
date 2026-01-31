extends Node3D

@export var _camera_pivot : Node3D = null
@export var _player : Node3D = null

const TILT_SPEED : float = 1.0
var _max_tilt : float = 30.0 # angle of max tilt in deg

func _physics_process(_delta: float) -> void:
    $Pivot.global_position = _player._rb.global_position - Vector3(0.0, 0.6, 0.0)
    $Pivot/Level.position = $Pivot.global_position * -1
    #_tilt(delta)

func _tilt(delta: float) -> void:
    var move_direction : Vector3 = Vector3.ZERO
    move_direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    move_direction.z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
    move_direction = move_direction.rotated(Vector3.UP, _camera_pivot.rotation.y + deg_to_rad(90))
    if move_direction.length() > 1.0: move_direction = move_direction.normalized()
    var target_rotation := move_direction * deg_to_rad(_max_tilt)
    $Pivot.rotation = $Pivot.rotation.move_toward(target_rotation, delta * TILT_SPEED)
    print(str(target_rotation) + ", " + str(move_direction))
    # todo fix the rotation calculation on line 21 it's bunk
