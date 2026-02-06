extends Node3D

var _level_path : String = ""
var player_scene : PackedScene = load("res://src/Player/player.tscn")
var hud_scene : PackedScene = load("res://src/UI/HUD.tscn")
var end_screen_scene : PackedScene = load("res://src/UI/level_end_screen.tscn")
var level_select_scene : PackedScene = load("res://src/Menus/level_select.tscn")
var skybox_scene : PackedScene = load("res://src/Level/Scenes/skybox.tscn")

var _player : Player = null

func _ready() -> void:
    Global.levelSelected.connect(_on_level_selected)
    Global.levelStarted.connect(_on_level_started)
    Global.returnToMainMenu.connect(_on_return_to_main_menu)

func _input(_event: InputEvent) -> void:
    if Input.is_action_just_released("restart") and $game.get_children().size() > 0:
        for child in $CanvasLayer.get_children():
            $CanvasLayer.remove_child(child)
            child.queue_free()
        for child in $game.get_children():
            $game.remove_child(child)
            child.queue_free()
        for child in $menus.get_children():
            $menus.remove_child(child)
            child.queue_free()
        _player = player_scene.instantiate()
        $game.add_child(_player)
        $game.add_child(skybox_scene.instantiate())
        $game.add_child(load(_level_path).instantiate())
        # todo: this won't have right level reqs

func _on_level_selected(level_path: String, rank_reqs: Dictionary[String, int]) -> void:
    _level_path = level_path
    var level_scene := load(_level_path)
    for child in $menus.get_children():
        $menus.remove_child(child)
        child.queue_free()
    _player = player_scene.instantiate()
    $game.add_child(_player)
    $game.add_child(skybox_scene.instantiate())
    var level : Level = level_scene.instantiate()
    level._rank_reqs = rank_reqs
    $game.add_child(level)

func _on_level_started(_level: Level, _level_timer: float, _total_drums: int) -> void:
    $CanvasLayer.add_child(end_screen_scene.instantiate())
    var hud_temp := hud_scene.instantiate()
    $CanvasLayer.add_child(hud_temp)
    hud_temp._physics_process(get_physics_process_delta_time())

func _on_return_to_main_menu(goto_level_select: bool) -> void:
    if goto_level_select:
        for child in $CanvasLayer.get_children():
            $CanvasLayer.remove_child(child)
            child.queue_free()
        for child in $game.get_children():
            $game.remove_child(child)
            child.queue_free()
        $menus.add_child(level_select_scene.instantiate())
