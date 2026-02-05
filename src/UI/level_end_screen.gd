extends Control

#const X_CONTROL_POS : float = 53.0

enum ScreenStage {
    NOVAL = -1,
    LEVEL_COMPLETE,
    SCORE,
    TIME,
    DRUMS,
    RANK_TEXT,
    RANK_LETTER,
    CONTINUE_BUTTON
}

var _score : int = 0
var _time : int = 0 # total seconds
var _drums_collected : int = 0
var _drums_total : int = 0
var _rank : String = ""

var _display_timer : Timer = Timer.new()
var _delay_timer : Timer = Timer.new()
var _screen_stage : ScreenStage = ScreenStage.NOVAL
var _add_to_score : bool = false

const TIME_DRAIN_RATE : float = 60.0
const DRUM_DRAIN_RATE : float = 15.0

func _ready() -> void:
    $Timers.add_child(_display_timer)
    $Timers.add_child(_delay_timer)
    
    Global.levelFinished.connect(_on_level_finished)
    $ContinueButton.pressed.connect(_on_continue_pressed)
    
    _display_timer.timeout.connect(_on_display_timer_timeout)
    _display_timer.one_shot = true
    _display_timer.stop()
    
    _delay_timer.timeout.connect(_on_delay_timer_timeout)
    _delay_timer.one_shot = true
    
    visible = false
    $LevelCompleteLabel.visible = false
    $Score.visible = false
    $Time.visible = false
    $Drums.visible = false
    $RankLabel.visible = false
    $RankLetter.visible = false
    $ContinueButton.visible = false
    $Background.visible = false

func _physics_process(delta: float) -> void:
    if _add_to_score:
        if _screen_stage == ScreenStage.TIME:
            var rem := _time
            _time -= ceili(TIME_DRAIN_RATE * delta)
            if _time < 0:
                _time = 0
                _score += rem * Global.TIME_SCORE_VALUE
                _display_timer.start(0.5)
                _add_to_score = false
            else:
                _score += ceili(TIME_DRAIN_RATE * delta) * Global.TIME_SCORE_VALUE
            $Time.text = "TIME: " + _seconds_to_time(_time)
        elif _screen_stage == ScreenStage.DRUMS:
            var rem := _drums_collected
            _drums_collected -= ceili(DRUM_DRAIN_RATE * delta)
            if _drums_collected < 0:
                _drums_collected = 0
                _score += rem * Global.DRUM_SCORE_VALUE
                _display_timer.start(0.5)
                _add_to_score = false
            else:
                _score += ceili(DRUM_DRAIN_RATE * delta) * Global.DRUM_SCORE_VALUE
            $Drums.text = "GREASE DRUMS: " + str(_drums_collected) + "/" + str(_drums_total)
    
    $Score.text = "SCORE: " + str(_score)

func _increment_screen_stage() -> void:
    if _screen_stage == ScreenStage.NOVAL:
        _screen_stage = ScreenStage.LEVEL_COMPLETE
        $LevelCompleteLabel.visible = true
        $Background.visible = true
        _display_timer.start(0.5)
    elif _screen_stage == ScreenStage.LEVEL_COMPLETE:
        _screen_stage = ScreenStage.SCORE
        $Score.text = "SCORE: " + str(_score)
        $Score.visible = true
        _display_timer.start(0.5)
    elif _screen_stage == ScreenStage.SCORE:
        _screen_stage = ScreenStage.TIME
        $Time.text = "TIME: " + _seconds_to_time(_time)
        $Time.visible = true
        _delay_timer.start(0.5)
    elif _screen_stage == ScreenStage.TIME:
        _screen_stage = ScreenStage.DRUMS
        $Drums.text = "GREASE DRUMS: " + str(_drums_collected) + "/" + str(_drums_total)
        $Drums.visible = true
        _delay_timer.start(0.5)
    elif _screen_stage == ScreenStage.DRUMS:
        _screen_stage = ScreenStage.RANK_TEXT
        $RankLabel.visible = true
        _display_timer.start(1.0)
    elif _screen_stage == ScreenStage.RANK_TEXT:
        _screen_stage = ScreenStage.RANK_LETTER
        $RankLetter.text = _rank
        $RankLetter.visible = true
        # todo: change color based on rank
        _display_timer.start(1.0)
    elif _screen_stage == ScreenStage.RANK_LETTER:
        _screen_stage = ScreenStage.CONTINUE_BUTTON
        $ContinueButton.visible = true

func _seconds_to_time(sec: int) -> String:
    @warning_ignore("integer_division")
    return "%01d:%02d" % [(sec / 60) % 60, sec % 60]

func _on_level_finished(score: int, time_left: float, drums_collected: int, drums_total: int, rank: String) -> void:
    _score = score
    _time = ceili(time_left)
    _drums_collected = drums_collected
    _drums_total = drums_total
    _rank = rank
    
    _display_timer.start(1.0)
    visible = true

func _on_display_timer_timeout() -> void:
    _increment_screen_stage()

func _on_delay_timer_timeout() -> void:
    _add_to_score = true

func _on_continue_pressed() -> void:
    Global.returnToMainMenu.emit(true)
