extends VBoxContainer

class_name ScoreInfo

var _name : String = ""
var _value : int = 0

func set_score_name(score_name: String) -> void:
    _name = score_name
    $Name.text = score_name

func set_score_value(value: int) -> void:
    _value = value
    $Value.text = str(value)
