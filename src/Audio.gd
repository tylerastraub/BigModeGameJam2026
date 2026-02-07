extends Node

class SoundInfo:
    var id: int
    var path: String
    var volume: float
    var player : AudioStreamPlayer
    
    func _init(_id: int, _path: String, _volume: float) -> void:
        id = _id
        path = _path
        volume = _volume

static var SOUND_ID : int = 0

var num_players = 8
var bus = "master"

var available : Array[AudioStreamPlayer] = []  # The available players.
var queue : Array[SoundInfo] = []  # The queue of sounds to play.
var playing : Array[SoundInfo] = []

func _ready():
    # Create the pool of AudioStreamPlayer nodes.
    for i in num_players:
        var player = AudioStreamPlayer.new()
        add_child(player)
        available.append(player)
        player.finished.connect(_on_stream_finished.bind(player))
        player.bus = bus

func _on_stream_finished(stream: AudioStreamPlayer):
    # When finished playing a stream, make the player available again.
    available.append(stream)
    for info in playing:
        if info.player == stream:
            playing.erase(info)
            return

func play(sound_path: String, volume: float = 1.0) -> int:
    var id := SOUND_ID
    queue.append(SoundInfo.new(SOUND_ID, sound_path, volume))
    SOUND_ID += 1
    return id

func stop(sound_id: int) -> void:
    for info in playing:
        if info.id == sound_id:
            info.player.stop()
            info.player.finished.emit()

func is_playing(sound_id: int) -> bool:
    for info in playing:
        if info.id == sound_id:
            return true
    return false

func stop_all_sounds() -> void:
    for info in playing:
        info.player.stop()
        info.player.finished.emit()

func _process(_delta):
    # Play a queued sound if any players are available.
    if not queue.is_empty() and not available.is_empty():
        var info : SoundInfo = queue.pop_front()
        info.player = available[0]
        available[0].stream = load(info.path)
        available[0].volume_linear = info.volume
        available[0].play()
        available.pop_front()
        playing.push_back(info)
