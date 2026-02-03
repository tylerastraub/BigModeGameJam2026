extends Area3D

class_name SlickCoin

var s_tex : Texture2D = preload("res://res/textures/coin_s_tex.png")
var l_tex : Texture2D = preload("res://res/textures/coin_l_tex.png")
var i_tex : Texture2D = preload("res://res/textures/coin_i_tex.png")
var c_tex : Texture2D = preload("res://res/textures/coin_c_tex.png")
var k_tex : Texture2D = preload("res://res/textures/coin_k_tex.png")

enum Letter {
    S,
    L,
    I,
    C,
    K
}

const ROTATE_SPEED : float = PI / 2
const COLLECTED_ROTATE_SPEED : float = PI * 16
const HOVER_DISTANCE : float = 0.2

@export var _letter : Letter = Letter.S

var _timer : float = 0.0
var _collected : bool = false

func _ready() -> void:
    Global.slickCoinCollected.connect(_on_slick_coin_collected)
    update_texture()

func _physics_process(delta: float) -> void:
    var rot : float = COLLECTED_ROTATE_SPEED if _collected else ROTATE_SPEED
    $slick_coin.rotate_y(rot * delta)
    $slick_coin.position.y = sin(_timer * 2) * HOVER_DISTANCE + HOVER_DISTANCE
    _timer += delta

func set_letter(letter: Letter) -> void:
    _letter = letter
    update_texture()

func update_texture() -> void:
    var mat : StandardMaterial3D = $slick_coin/Cube.mesh.surface_get_material(0).duplicate()
    if _letter == Letter.S:
        mat.albedo_texture = s_tex
    elif _letter == Letter.L:
        mat.albedo_texture = l_tex
    elif _letter == Letter.I:
        mat.albedo_texture = i_tex
    elif _letter == Letter.C:
        mat.albedo_texture = c_tex
    elif _letter == Letter.K:
        mat.albedo_texture = k_tex
    $slick_coin/Cube.set_surface_override_material(0, mat)

func _on_slick_coin_collected(coin: SlickCoin) -> void:
    if coin == self:
        _collected = true
