extends Button

@export var level_path : String = ""

# todo: this needs to be in a .json file that everyone can access
@export var rank_reqs : Dictionary[String, int] = {
    "S" : 10000,
    "A" : 8000,
    "B" : 5000,
    "C" : 3000,
    "D" : 1000,
}

var _hovered : bool = false

func _ready() -> void:
    pressed.connect(_on_button_pressed)

func _process(_delta: float) -> void:
    if is_hovered() != _hovered:
        _hovered = is_hovered()
        Global.levelSelectButtonHovered.emit(is_hovered(), rank_reqs)

func _on_button_pressed() -> void:
    Global.levelSelected.emit(level_path, rank_reqs)
