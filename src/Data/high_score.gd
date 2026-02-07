extends Node
class_name HighScore

var score : int
var rank : String

func _init(_score: int, _rank: String) -> void:
    score = _score
    rank = _rank
