extends Control

func _ready() -> void:
    $VBoxContainer/ResumeButon.pressed.connect(_on_resume_pressed)
    $VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)
    $VBoxContainer/QuickRestartToggle.toggled.connect(_on_quick_restart_toggled)
    $VBoxContainer/ExitButton.pressed.connect(_on_exit_pressed)

func _physics_process(_delta: float) -> void:
    visible = Global.pause

func _on_resume_pressed() -> void:
    Global.pause = false
    Global.pauseSet.emit(Global.pause)

func _on_restart_pressed() -> void:
    Global.restartLevel.emit()

func _on_quick_restart_toggled(toggled_on: bool) -> void:
    Global.quick_restart = toggled_on
    
func _on_exit_pressed() -> void:
    Global.pause = false
    Global.returnToMainMenu.emit(true)
