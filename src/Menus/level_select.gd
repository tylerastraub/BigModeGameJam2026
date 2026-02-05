extends Button

@export var level_path : String = ""

func _ready() -> void:
    pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
    Global.levelSelected.emit(level_path)
