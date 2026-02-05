extends Area3D

class_name BoostRing

const BASE_COLOR : Color = Color(0.46, 0.68, 1.0, 1.0)
const BOOST_COLOR : Color = Color(0.84, 0.9, 1.0, 1.0)

func _ready() -> void:
    area_entered.connect(_on_area_entered)
    
func _physics_process(_delta: float) -> void:
    pass

func _on_area_entered(_area: Area3D) -> void:
    pass
