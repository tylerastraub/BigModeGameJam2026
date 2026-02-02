extends Control

class_name HUD

class Score:
    var trick : Trick
    var local_value : int = 0
    var info_node : ScoreInfo
    
    var timer : float = 0.0
    var timer_enabled : bool = true
    
    func _init(_trick: Trick) -> void:
        trick = _trick
        local_value = _trick.trick_value
    
    func score_remainder(score: int) -> int:
        var rem := local_value
        local_value = max(local_value - score, 0)
        if info_node != null:
            info_node.set_score_value(local_value)
        if local_value <= 0:
            return rem
        return score

var _score_info_scene : PackedScene = preload("res://src/UI/score_info.tscn")

var _score : int = 0
var _score_add_speed : float = 400.0 # how many score to tack up per second
var _score_add_delay : float = 1.0
var _score_infos : Array[Score] = []
var _last_score : Score = null

func _ready() -> void:
    Global.trickStarted.connect(_on_trick_started)
    Global.trickScored.connect(_on_trick_scored)
    Global.currentTrickUpdated.connect(_on_current_trick_updated)

func _physics_process(delta: float) -> void:
    if _last_score:
        if _last_score.timer_enabled:
            _last_score.timer += delta
        if _last_score.timer >= _score_add_delay:
            var step : int = int(_score_add_speed * delta)
            var rem : int = _last_score.score_remainder(step)
            _score += rem
            if _last_score.local_value <= 0:
                _last_score = null
    
    for info in _score_infos:
        if info.timer > _score_add_delay:
            var step : int = int(_score_add_speed * delta)
            var rem : int = info.score_remainder(step)
            _score += rem
            if info.local_value <= 0:
                if info.info_node:
                    $ScoreInfoHistory.call_deferred("remove_child", info.info_node)
                _score_infos.erase(info)
        if info.timer_enabled:
            info.timer += delta
    update_score_infos()
    if Input.is_action_just_pressed("test_button"):
        add_score(Trick.new("test", randi_range(500, 2000), Trick.Type.NOVAL), true)
    $Score.text = "%06d" % _score

func add_score(trick: Trick, timer_enabled: bool) -> void:
    var score : Score = Score.new(trick)
    score.timer_enabled = timer_enabled
    if _last_score == null:
        _last_score = score
    elif _last_score.trick == trick:
        _last_score.timer_enabled = timer_enabled
    elif _last_score.timer_enabled:
        _score_infos.push_front(_last_score)
        _last_score = score
    else:
        _score_infos.push_front(score)
    
    update_score_infos()

func update_score_infos() -> void:
    if _last_score:
        $LastScore.text = _last_score.trick.trick_name + "\n" + str(_last_score.local_value)
    else:
        $LastScore.text = ""
    for info in _score_infos:
        if info.info_node == null:
            var info_node := _score_info_scene.instantiate()
            info_node.set_score_name(info.trick.trick_name)
            info_node.set_score_value(info.local_value)
            info.info_node = info_node
            $ScoreInfoHistory.add_child(info_node)
            $ScoreInfoHistory.move_child(info_node, 0)
    var h := $ScoreInfoHistory.get_children().size() * 46
    $ScoreInfoHistory.size.y = h
    $ScoreInfoHistory.position.y = 285 - h

func _on_trick_started(trick: Trick) -> void:
    add_score(trick, false)

func _on_trick_scored(trick: Trick) -> void:
    add_score(trick, true)

func _on_current_trick_updated(trick: Trick) -> void:
    if _last_score:
        if _last_score.trick == trick:
            _last_score.local_value = trick.trick_value
