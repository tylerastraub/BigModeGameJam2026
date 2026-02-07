extends Control

func _ready() -> void:
    Global.levelSelectButtonHovered.connect(_on_hover)
    $Benchmarks.visible = false
    $PersonalBest.visible = false

func _on_hover(is_hovering: bool, rank_reqs: Dictionary[String, int], _high_score: int, _high_rank: String) -> void:
    if is_hovering:
        $Benchmarks.text = ""
        var ordered_ranks : Array[String] = ["S","A","B","C","D"]
        for rank in ordered_ranks:
            var extra_text : String = ""
            if rank == "S": extra_text = " + all S.L.I.C.K. coins"
            $Benchmarks.text += rank + ": " + str(rank_reqs[rank]) + extra_text + "\n"
        # todo: personal best saving + retrieving
        #$PersonalBest.text = "Personal Best: " + str(high_score) + " (" + high_rank + ")"
        $Benchmarks.visible = true
        #$PersonalBest.visible = true
    else:
        $Benchmarks.visible = false
        $PersonalBest.visible = false
