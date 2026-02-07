extends Node3D

const _stream_main_menu_theme : String = "res://res/audio/music/main_menu_theme.mp3"

func _ready() -> void:
    $grease_man/AnimationPlayer.play("Sliding")
    $Control/Button.pressed.connect(_on_play_pressed)
    $Control/Logo/Sprite2D.play("default")
    Audio.play(_stream_main_menu_theme, 0.2)

func _physics_process(delta: float) -> void:
    $main_menu_track.rotate_y(deg_to_rad(30) * delta)
    
func _on_play_pressed() -> void:
    Global.returnToMainMenu.emit(true)
    queue_free()
