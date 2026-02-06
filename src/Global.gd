extends Node

enum PlayerState {
    NOVAL = -1,
    GROUNDED,
    AERIAL,
    HALF_PIPE,
    GRINDING,
    SHOCKED,
    FINISHED,
    STARTING,
}

@warning_ignore("unused_signal")
signal trickStarted(trick: Trick)
@warning_ignore("unused_signal")
signal trickScored(trick: Trick)
@warning_ignore("unused_signal")
signal currentTrickUpdated(trick: Trick)
@warning_ignore("unused_signal")
signal slickCoinCollected(coin: SlickCoin)
@warning_ignore("unused_signal")
signal scorePenalty(value: int)

@warning_ignore("unused_signal")
signal levelFinished(player_score: int, time_left: float, drums_collected: int, drums_total: int, rank: String)
@warning_ignore("unused_signal")
signal levelTimerUpdate(level_timer: float)
@warning_ignore("unused_signal")
signal levelStarted(level: Level, level_timer: float, total_drums: int)

@warning_ignore("unused_signal")
signal returnToMainMenu(goto_level_select: bool)
@warning_ignore("unused_signal")
signal levelSelected(level_path: String, rank_reqs: Dictionary[String, int])
@warning_ignore("unused_signal")
signal levelSelectButtonHovered(is_hovering: bool, rank_reqs: Dictionary[String, int])
@warning_ignore("unused_signal")
signal restartLevel()
@warning_ignore("unused_signal")
signal pauseSet(_pause: bool)

@warning_ignore("unused_signal")
signal cameraUpdate(pos: Vector3)

const TIME_SCORE_VALUE : int = 20
const DRUM_SCORE_VALUE : int = 150
const ELECTRIC_BALL_PENALTY : int = 1000

var pause : bool = false
var debug : bool = false
var quick_restart : bool = false
