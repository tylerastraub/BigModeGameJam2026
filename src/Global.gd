extends Node

enum PlayerState {
    NOVAL = -1,
    GROUNDED,
    AERIAL,
    HALF_PIPE,
    GRINDING,
    SHOCKED,
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

var debug : bool = false
