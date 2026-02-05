extends Area3D

class_name GrindRail

@warning_ignore("unused_private_class_variable")
@export var _can_jump_off : bool = true
@export var _grind_speed : float = 10.0

@onready var _follow : PathFollow3D = $GrindRailPath/GrindRailPathFollow

var _rail_length : float = 0.0

func _ready() -> void:
    _rail_length = $GrindRailPath.curve.get_baked_length()

func find_nearest_start_ratio(player_pos: Vector3) -> float:
    var step : float = 0.01
    var no_y_vec : Vector3 = Vector3(1.0, 0.0, 1.0)
    var closest_ratio : float = 0.0
    var closest_distance : float = (player_pos * no_y_vec).distance_to(_follow.global_position * no_y_vec)
    var i : float = 0.0
    while i < 1.0:
        _follow.progress_ratio = i
        var distance : float = (player_pos * no_y_vec).distance_to(_follow.global_position * no_y_vec)
        if distance < closest_distance:
            closest_ratio = i
            closest_distance = distance
        i += step
    return closest_ratio

func set_grind_pos(progress_ratio: float) -> void:
    if progress_ratio < 0.0: progress_ratio = 0.0
    if progress_ratio > 1.0: progress_ratio = 1.0
    _follow.progress_ratio = progress_ratio

func move_grind_pos(delta: float) -> void:
    _follow.progress_ratio += (_grind_speed * delta) / _rail_length

func get_grind_pos() -> Vector3:
    return _follow.global_position

func get_grind_ratio() -> float:
    return _follow.progress_ratio

func get_follow_rotation() -> Vector3:
    return _follow.global_rotation
