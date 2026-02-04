extends Node3D

class_name Level

var _rank_reqs : Dictionary[String, int] = {
    "S" : 10000,
    "A" : 8000,
    "B" : 5000,
    "C" : 3000,
    "D" : 1000,
}
var _timer : float = 180.0
var _total_drums : int = 30

func _ready() -> void:
    rotation.x = deg_to_rad(-15)
    Global.levelStarted.emit(self, _timer, _total_drums)

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
