extends Control

func _ready() -> void:
    Global.levelSelectButtonHovered.connect(_on_hover)
    $Benchmarks.visible = false
    $PersonalBest.visible = false

func _on_hover(is_hovering: bool, rank_reqs: Dictionary[String, int]) -> void:
    if is_hovering:
        $Benchmarks.text = ""
        var ordered_ranks : Array[String] = ["S","A","B","C","D"]
        for rank in ordered_ranks:
            $Benchmarks.text += rank + ": " + str(rank_reqs[rank]) + "\n"
        # todo: personal best saving + retrieving
        $Benchmarks.visible = true
        $PersonalBest.visible = true
    else:
        $Benchmarks.visible = false
        $PersonalBest.visible = false
