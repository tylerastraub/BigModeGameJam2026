extends Control

class_name LevelSelect

const _stream_level_select_theme : String = "res://res/audio/music/level_select_theme.mp3"

func _ready() -> void:
    Audio.play(_stream_level_select_theme, 0.1)

func set_level_scores(db: ScoreDatabase) -> void:
    for level in db.scores:
        if level == 1:
            $Levels/button_1_1.high_score = db.scores[level].high_score
            $Levels/button_1_1.high_rank = db.scores[level].rank
