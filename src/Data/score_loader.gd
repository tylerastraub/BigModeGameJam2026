extends Node

class_name ScoreLoader

const SCORE_PATH : String = "user://data/level_scores.tres"

static func load_scores() -> ScoreDatabase:
    if ResourceLoader.exists(SCORE_PATH) == false:
        return ScoreDatabase.new()
    var db : ScoreDatabase = ResourceLoader.load(SCORE_PATH) as ScoreDatabase
    if db == null:
        db = ScoreDatabase.new()
    return db

static func save_score(level: int, score: int, rank: String) -> void:
    var db : ScoreDatabase
    if ResourceLoader.exists(SCORE_PATH) == false:
        db = ScoreDatabase.new()
    else:
        db = ResourceLoader.load(SCORE_PATH) as ScoreDatabase
    if db == null:
        db = ScoreDatabase.new()
    db.scores[level] = HighScore.new(score, rank)
    ResourceSaver.save(db, SCORE_PATH)
