extends Control

class_name SlickCoinProgress

const FLASH_INTERVAL : int = 25
const COINS_DISPLAY_TIME_INCOMPLETE : int = 175
const COINS_DISPLAY_TIME_COMPLETE : int = 250

var _timer : int = 0
var _delta_timer : float = 0.0
var _last_letter : SlickCoin.Letter
var _all_coins_found : bool = false

var _coins : Dictionary[SlickCoin.Letter, bool] = {
    SlickCoin.Letter.S : false,
    SlickCoin.Letter.L : false,
    SlickCoin.Letter.I : false,
    SlickCoin.Letter.C : false,
    SlickCoin.Letter.K : false,
}

func _ready() -> void:
    Global.slickCoinCollected.connect(_on_slick_coin_collected)
    visible = false

func _physics_process(delta: float) -> void:
    if _timer % FLASH_INTERVAL == 0 and _timer != 0 and _all_coins_found == false:
        get_coin_child(_last_letter).visible = !get_coin_child(_last_letter).visible
    
    var limit = COINS_DISPLAY_TIME_COMPLETE if _all_coins_found else COINS_DISPLAY_TIME_INCOMPLETE
    if _timer >= limit:
        visible = false
    
    if _all_coins_found:
        var counter := 0.0
        for key in SlickCoin.Letter.values():
            get_coin_child(key).position.y = max(sin(2 * PI * _delta_timer - counter) * 48.0, 0.0) * -1.0
            counter += 0.5
        
    _timer += 1
    _delta_timer += delta

func get_coin_child(letter: SlickCoin.Letter) -> Node2D:
    if letter == SlickCoin.Letter.S:
        return $CanvasModulate/S
    elif letter == SlickCoin.Letter.L:
        return $CanvasModulate/L
    elif letter == SlickCoin.Letter.I:
        return $CanvasModulate/I
    elif letter == SlickCoin.Letter.C:
        return $CanvasModulate/C
    else:
        return $CanvasModulate/K

func new_coin_found() -> void:
    for key in SlickCoin.Letter.values():
        get_coin_child(key).visible = _coins[key]

func all_coins_found() -> void:
    _all_coins_found = true
    for key in SlickCoin.Letter.values():
        get_coin_child(key).visible = true

func _on_slick_coin_collected(coin: SlickCoin) -> void:
    _coins[coin._letter] = true
    _last_letter = coin._letter
    _timer = 0
    _delta_timer = 0.0
    visible = true
    for key in SlickCoin.Letter.values():
        if _coins[key] == false:
            new_coin_found()
            Global.trickScored.emit(Trick.new(str(SlickCoin.Letter.keys()[coin._letter]) + " COIN", 500, Trick.Type.SLICK_COIN_SINGLE))
            return
    all_coins_found()
    Global.trickScored.emit(Trick.new("ALL S.L.I.C.K. COINS", 2500, Trick.Type.SLICK_COIN_ALL))
