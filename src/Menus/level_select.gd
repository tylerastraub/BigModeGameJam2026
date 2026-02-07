extends Control

class_name LevelSelect

func set_level_scores(db: ScoreDatabase) -> void:
    for level in db.scores:
        if level == 1:
            $Levels/button_1_1.high_score = db.scores[level].high_score
            $Levels/button_1_1.high_rank = db.scores[level].rank
