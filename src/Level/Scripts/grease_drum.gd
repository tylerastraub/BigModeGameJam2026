extends Area3D

const ROTATE_SPEED : float = 180.0

func _ready() -> void:
    area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
    $grease_drum.rotate_y(deg_to_rad(ROTATE_SPEED) * delta)

func _on_area_entered(area: Area3D) -> void:
    queue_free()
