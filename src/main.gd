extends Node3D

var player_scene : PackedScene = load("res://src/Player/player.tscn")
var hud_scene : PackedScene = load("res://src/UI/HUD.tscn")
var end_screen_scene : PackedScene = load("res://src/UI/level_end_screen.tscn")
var level_select_scene : PackedScene = load("res://src/Menus/level_select.tscn")
var skybox_scene : PackedScene = load("res://src/Level/Scenes/skybox.tscn")
var loading_screen_scene : PackedScene = load("res://src/Menus/loading_screen.tscn")

var _player : Player = null
var _level_select : LevelSelect = null
var _level_path : String = ""
var _rank_reqs : Dictionary[String, int] = {}
var _level_scores : ScoreDatabase = null

var _load_level_tick_counter : int = 2

func _ready() -> void:
    Global.levelSelected.connect(_on_level_selected)
    Global.levelStarted.connect(_on_level_started)
    Global.returnToMainMenu.connect(_on_return_to_main_menu)
    Global.restartLevel.connect(_restart_level)

func _input(_event: InputEvent) -> void:
    if Input.is_action_just_pressed("pause") and _player != null:
        if _player._state != Global.PlayerState.FINISHED and _player._state != Global.PlayerState.STARTING:
            Global.pause = !Global.pause
            Global.pauseSet.emit(Global.pause)
    if Input.is_action_just_released("restart") and Global.quick_restart:
        _restart_level()

func _physics_process(_delta: float) -> void:
    if _load_level_tick_counter < 1:
        call_deferred("_load_level", _level_path, _rank_reqs)
        _load_level_tick_counter = 2
    elif _load_level_tick_counter < 2:
        _load_level_tick_counter -= 1

func _restart_level() -> void:
    if $game.get_children().size() > 0:
        Audio.stop_all_sounds()
        for child in $CanvasLayer.get_children():
            $CanvasLayer.remove_child(child)
            child.queue_free()
        for child in $game.get_children():
            $game.remove_child(child)
            child.queue_free()
        _load_level(_level_path, _rank_reqs)
        Global.pause = false
        Global.pauseSet.emit(false)

func _load_level(level_path: String, rank_reqs: Dictionary[String, int]) -> void:
    _level_path = level_path
    _rank_reqs = rank_reqs
    var level_scene := load(_level_path)
    for child in $menus.get_children():
        $menus.remove_child(child)
        child.queue_free()
    _level_select = null
    _player = player_scene.instantiate()
    $game.add_child(_player)
    $game.add_child(skybox_scene.instantiate())
    var level : Level = level_scene.instantiate()
    level._rank_reqs = rank_reqs
    $game.add_child(level)

func _on_level_selected(level_path: String, rank_reqs: Dictionary[String, int]) -> void:
    $menus.add_child(loading_screen_scene.instantiate())
    _level_path = level_path
    _rank_reqs = rank_reqs
    _load_level_tick_counter = 1 # do this so loading screen has time to become visible

func _on_level_started(_level: Level, _level_timer: float, _total_drums: int) -> void:
    $CanvasLayer.add_child(end_screen_scene.instantiate())
    var hud_temp := hud_scene.instantiate()
    $CanvasLayer.add_child(hud_temp)
    hud_temp._physics_process(get_physics_process_delta_time())

func _on_return_to_main_menu(goto_level_select: bool) -> void:
    Audio.stop_all_sounds()
    if goto_level_select:
        for child in $CanvasLayer.get_children():
            $CanvasLayer.remove_child(child)
            child.queue_free()
        for child in $game.get_children():
            $game.remove_child(child)
            child.queue_free()
        _level_select = level_select_scene.instantiate()
        $menus.add_child(_level_select)
        _player = null
        #_level_scores = ScoreLoader.load_scores()
        #_level_select.set_level_scores(_level_scores)

func _on_check_for_player_high_score(level: int, score: int, rank: String) -> void:
    if _level_scores.scores.has(level):
        if _level_scores.scores[level].score < score:
            ScoreLoader.save_score(level, score, rank)
    else:
        ScoreLoader.save_score(level, score, rank)
