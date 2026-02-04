extends Node

class_name Trick

enum Type {
    NOVAL = -1,
    SPIN,
    GRIND,
    HALF_PIPE,
    BOOST_RING,
    BOOST_PAD,
    SLICK_COIN_SINGLE,
    SLICK_COIN_ALL,
}

var trick_name : String
var trick_value : int
var trick_type : Type
var trick_level : int = 0

func _init(_name: String, _value: int, _type: Type) -> void:
    trick_name = _name
    trick_value = _value
    trick_type = _type
