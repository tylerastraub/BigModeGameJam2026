extends Control

class_name HUD

class Score:
    var trick : Trick
    var local_value : int = 0
    var info_node : ScoreInfo
    
    var timer : float = 0.0
    var timer_enabled : bool = true
    
    var rainbow_effect : bool = false
    var text_color : Color = Color.WHITE
    
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

var _penalty : int = 0
var _penalty_timer : float = 0.0

func _ready() -> void:
    Global.trickStarted.connect(_on_trick_started)
    Global.trickScored.connect(_on_trick_scored)
    Global.currentTrickUpdated.connect(_on_current_trick_updated)
    Global.scorePenalty.connect(_on_score_penalty)
    Global.levelFinished.connect(_on_level_finished)
    Global.levelTimerUpdate.connect(_on_level_timer_update)

func _physics_process(delta: float) -> void:
    if visible == false: return
    
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
    
    if _penalty > 0:
        $Penalty.text = "-" + str(_penalty)
        $Penalty.visible = true
        if _penalty_timer > _score_add_delay:
            var rem := _penalty
            _penalty -= int(_score_add_speed * delta * 2)
            if _penalty <= 0:
                _penalty = 0
                _score -= rem
            else:
                _score -= int(_score_add_speed * delta * 2)
            if _score < 0:
                _score = 0
        _penalty_timer += delta
    else:
        $Penalty.visible = false
    
    update_score_infos()
    
    #if Input.is_action_just_pressed("test_button"):
        #add_score(Trick.new("test", randi_range(500, 2000), Trick.Type.NOVAL), true)
    $Score.text = "%06d" % _score

func add_score(trick: Trick, timer_enabled: bool) -> void:
    var score : Score = Score.new(trick)
    score.timer_enabled = timer_enabled
    if score.trick.trick_type == Trick.Type.SLICK_COIN_ALL:
        score.rainbow_effect = true
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
        if _last_score.rainbow_effect:
            $LastScore.add_theme_color_override("default_color", _get_rainbow_color(_last_score.timer))
        else:
            $LastScore.add_theme_color_override("default_color", _last_score.text_color)
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
        if info.rainbow_effect:
            info.info_node.set_text_color(_get_rainbow_color(info.timer))
        else:
            info.info_node.set_text_color(info.text_color)
    var h := $ScoreInfoHistory.get_children().size() * 46
    $ScoreInfoHistory.size.y = h
    $ScoreInfoHistory.position.y = 285 - h

# returns color from rainbow spectrum based on value between 0 and 1
func _get_rainbow_color(index: float) -> Color:
    var res : Color
    index -= int(index) # get 0.0-1.0 value
    # red
    if index <= 1.0/6.0 or index > 5.0/6.0:
        res.r = 1.0
    elif index > 2.0/6.0 and index <= 4.0/6.0:
        res.r = 0.0
    elif index > 1.0/6.0 and index <= 2.0/6.0:
        res.r = 1.0 - ((index - 1.0/6.0) / (1.0/6.0))
    else:
        res.r = (index - 4.0/6.0) / (1.0/6.0)
    # green
    if index <= 1.0/6.0:
        res.g = index / (1.0/6.0)
    elif index > 1.0/6.0 and index <= 3.0/6.0:
        res.g = 1.0
    elif index > 3.0/6.0 and index <= 4.0/6.0:
        res.g = 1.0 - ((index - 3.0/6.0) / (1.0/6.0))
    else:
        res.g = 0.0
    # blue
    if index <= 2.0/6.0:
        res.b = 0.0
    elif index > 2.0/6.0 and index <= 3.0/6.0:
        res.b = (index - 2.0/6.0) / (1.0/6.0)
    elif index > 3.0/6.0 and index <= 5.0/6.0:
        res.b = 1.0
    else:
        res.b = 1.0 - ((index - 5.0/6.0) / (1.0/6.0))
    
    return res

func _on_trick_started(trick: Trick) -> void:
    add_score(trick, false)

func _on_trick_scored(trick: Trick) -> void:
    add_score(trick, true)

func _on_current_trick_updated(trick: Trick) -> void:
    if _last_score:
        if _last_score.trick == trick:
            _last_score.local_value = trick.trick_value

func _on_score_penalty(value: int) -> void:
    if _last_score:
        if _last_score.timer_enabled == false:
            _last_score.timer_enabled = true
            _last_score.local_value = 0
            _last_score.text_color = Color.RED
    _penalty_timer = 0.0
    _penalty = value

func _on_level_finished(_player_score: int, _time: int, _drums_collected: int, _drums_total: int, _rank: String) -> void:
    visible = false

func _on_level_timer_update(_level_timer: float) -> void:
    @warning_ignore("integer_division")
    $Timer.text = str((int(_level_timer) / 60) % 60) + ":%.2f" % [float(int(_level_timer) % 60) + (_level_timer - floorf(_level_timer))]
