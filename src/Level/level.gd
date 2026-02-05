extends Node3D

class_name Level

@export var _rank_reqs : Dictionary[String, int] = {
    "S" : 10000,
    "A" : 8000,
    "B" : 5000,
    "C" : 3000,
    "D" : 1000,
}
@export var _timer : float = 180.0
@export var _total_drums : int = 0

var countdown_scene : PackedScene = load("res://src/Level/countdown.tscn")
var _countdown_text : RichTextLabel = null
var _countdown : CanvasLayer = null
var _countdown_timer : Timer = Timer.new()

func _ready() -> void:
    rotation.x = deg_to_rad(-15)
    var countdown := countdown_scene.instantiate()
    _countdown_text = countdown.get_child(0)
    _countdown_text.text = "3"
    _countdown = countdown
    add_child(countdown)
    add_child(_countdown_timer)
    _countdown_timer.start(0.5)
    _countdown_timer.timeout.connect(_on_countdown_timer)

func calculate_rank(score: int, all_coins_collected: bool) -> String:
    if score >= _rank_reqs["S"] and all_coins_collected:
        return "S"
    elif score >= _rank_reqs["A"]:
        return "A"
    elif score >= _rank_reqs["B"]:
        return "B"
    elif score >= _rank_reqs["C"]:
        return "C"
    elif score >= _rank_reqs["D"]:
        return "D"
    
    return "F"

func _on_countdown_timer() -> void:
    if _countdown_text.text == "3":
        _countdown_text.text = "2"
    elif _countdown_text.text == "2":
        _countdown_text.text = "1"
    elif _countdown_text.text == "1":
        _countdown_text.text = "GO"
        Global.levelStarted.emit(self, _timer, _total_drums)
    elif _countdown_text.text == "GO":
        remove_child(_countdown)
        _countdown_timer.stop()
