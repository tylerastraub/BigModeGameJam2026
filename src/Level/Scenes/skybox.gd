extends Node3D

func _ready() -> void:
    Global.cameraUpdate.connect(_on_camera_update)

func _on_camera_update(pos: Vector3) -> void:
    global_position = pos
