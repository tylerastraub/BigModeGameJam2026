extends Node3D

class_name Player

const ROTATION_SPEED : float = 20.0
const XFORM_SPEED : float = 20.0
const CAMERA_MOVE_LERP : float = 50.0
const CAMERA_ROTATE_LERP : float = 0.5

const AERIAL_180_LEEWAY : float = 50.0
const COYOTE_TIME : int = 4

# Resources
var _stream_drum_collected : String = "res://res/audio/drum_collected.wav"
var _stream_shock : String = "res://res/audio/shock.wav"
var _stream_grinding : String = "res://res/audio/grinding.wav"
var _stream_jump : String = "res://res/audio/slime_jump.wav"
var _stream_boost_pad : String = "res://res/audio/boost_pad.wav"
var _stream_boost_ring : String = "res://res/audio/boost_ring.wav"
var _stream_level_complete : String = "res://res/audio/level_finish.wav"
var _stream_trick_landed : String = "res://res/audio/trick_landed.wav"

# Children
@onready var _rb : RigidBody3D = $RigidBody3D
@onready var _visuals : Node3D = $PlayerVisuals
@onready var _pivot : Node3D = $CameraPivot
@onready var _spring_arm : SpringArm3D = $CameraPivot/SpringArm
@onready var _raycasts : Node3D = $RigidBody3D/Raycasts

# Movement Vars
var _accel : float = 700.0
var _air_accel : float = 50.0
var _max_velocity : float = 10.0
var _min_velocity : float = 3.0

# States
var _state : Global.PlayerState = Global.PlayerState.STARTING
var _last_state : Global.PlayerState = Global.PlayerState.NOVAL

# Grinding
var _grind_rail : GrindRail = null
var _last_grind_rail : GrindRail = null

# Aerial
var _starting_aerial_angle : float = 0.0
var _total_aerial_rotation : float = 0.0
var _aerial_rotate_max_speed : float = 7.0
var _aerial_rotate_accel : float = 1.5
var _aerial_rotate_velocity : float = 0.0
var _turned_180 : bool = true

# Boost
var _boost_on_land : bool = false
var _boost_ring_active : bool = false
var _boost_factor : float = 2.0 # multiplicative factor for top speed when boosting
var _boost_power : float = 15.0 # initial boost
var _boost_timer : float = 1.0
var _boost_time : float = 0.25

# Tricks
var _current_trick : Trick = null
const HALF_PIPE_TRICK_RATE : int = 3
const GRIND_TRICK_RATE : int = 6
const BOOST_RING_TRICK_VALUE : int = 400
const BOOST_PAD_TRICK_VALUE : int = 250
const SPIN_TRICK_RATE : int = 180

# Shock
var _shock_timer : float = 10.0
const SHOCK_TIME : float = 1.0

# Level stats
var _level : Level = null
var _drums_collected : int = 0
var _total_drums : int = 0
@onready var _level_timer : Timer = $LevelTimer

# Sound IDs
var _grind_sound_id : int = -1

# Misc
var _score : int = 0
var _input_dir : Vector3 = Vector3.ZERO
var _ticks_since_touching_ground : int = 0
var _coins : Dictionary[SlickCoin.Letter, bool] = {
    SlickCoin.Letter.S : false,
    SlickCoin.Letter.L : false,
    SlickCoin.Letter.I : false,
    SlickCoin.Letter.C : false,
    SlickCoin.Letter.K : false,
}

# Debug
var move_vec : Vector3 = Vector3.ZERO

## ========== GODOT METHODS ==========

func _ready() -> void:
    $PlayerVisuals/Mesh/BodyArea.area_entered.connect(_on_area_3d_area_entered)
    Global.trickScored.connect(_on_trick_scored)
    Global.levelStarted.connect(_on_level_started)
    _rb._max_velocity = _max_velocity
    _rb._min_forward_velocity = _min_velocity
    _rb._player_state = _state
    if Global.debug:
        $Debug.draw.add_vector(self, "move_vec", 1, 4, Color.RED, $PlayerVisuals)
    
    _level_timer.one_shot = true
    _level_timer.stop()
    _drums_collected = 0

func _physics_process(delta: float) -> void:
    if Global.pause: return
    Global.levelTimerUpdate.emit(_level_timer.time_left)
    _raycasts.global_position = _rb.global_position
    
    _handle_orientation(delta)
    _handle_states()
    _shock()
    _trick()
    _grind(delta)
    _aerial(delta)
    _move(delta)
    _boost()
    if Input.is_action_just_pressed("jump"): _jump()
    var relative_velocity : float = 1.0
    if _state != Global.PlayerState.GRINDING:
        relative_velocity = min(_rb.linear_velocity.length() / _max_velocity, 1.8)
    
    if _state == Global.PlayerState.FINISHED:
        _spring_arm.rotation.y = lerp_angle(_spring_arm.rotation.y, deg_to_rad(170), delta * 2.0)
        _spring_arm._default_camera_tilt = 10
        _spring_arm.position.x = lerpf(_spring_arm.position.x, 0.4, delta * 2.0)
        _spring_arm.position.y = lerpf(_spring_arm.position.y, -0.8, delta * 2.0)
        _spring_arm.spring_length = lerpf(_spring_arm.spring_length, 1.5, delta * 2.0)
        _spring_arm._update(delta * 0.5, is_player_actionable(), relative_velocity)
    else:
        _spring_arm._update(delta, is_player_actionable(), relative_velocity)
    
    if _state != Global.PlayerState.AERIAL and _state != Global.PlayerState.SHOCKED:
        if _turned_180:
            $PlayerVisuals/Mesh.rotation.y = lerp_angle($PlayerVisuals/Mesh.rotation.y, deg_to_rad(180.0), delta * 10.0)
        else:
            $PlayerVisuals/Mesh.rotation.y = lerp_angle($PlayerVisuals/Mesh.rotation.y, 0.0, delta * 10.0)
    
    _pivot.global_position = _pivot.global_position.move_toward(_rb.global_position + Vector3(0.0, 0.8, 0.0), delta * CAMERA_MOVE_LERP)
    _visuals.global_position = _rb.global_position
    
    _ticks_since_touching_ground += 1
    if _rb.get_contact_count() > 0 or _state == Global.PlayerState.GRINDING:
        _ticks_since_touching_ground = 0
    _boost_timer += delta
    _shock_timer += delta
    
    _animate(delta)

## ========== PUBLIC METHODS ==========

func set_state(state: Global.PlayerState) -> void:
    if _state == state: return
    _last_state = _state
    _state = state
    _rb._player_state = _state
    
    if _last_state == Global.PlayerState.AERIAL:
        if _state != Global.PlayerState.SHOCKED:
            _check_for_180()
    
    if state == Global.PlayerState.GRINDING:
        if _current_trick == null:
            _current_trick = Trick.new("GRIND", 0, Trick.Type.GRIND)
            Global.trickStarted.emit(_current_trick)
        elif _last_grind_rail != _grind_rail:
            _current_trick.trick_level += 1
            _current_trick.trick_name = str(_current_trick.trick_level + 1) + "x GRIND"
    elif state == Global.PlayerState.HALF_PIPE:
        _current_trick = Trick.new("HALF PIPE", 0, Trick.Type.HALF_PIPE)
        Global.trickStarted.emit(_current_trick)
    elif state == Global.PlayerState.AERIAL:
        _starting_aerial_angle = _visuals.rotation.y
        _total_aerial_rotation = 0.0
    elif state == Global.PlayerState.GROUNDED:
        if _current_trick:
            Global.trickScored.emit(_current_trick)
            _current_trick = null

func is_player_actionable() -> bool:
    return _state == Global.PlayerState.GROUNDED

## ========== PRIVATE METHODS ==========

func _move(delta: float) -> void:
    _input_dir = Vector3.ZERO
    _input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    _input_dir.z = (Input.get_action_strength("move_backward") * 0.6) - Input.get_action_strength("move_forward")
    _input_dir = _input_dir.rotated(Vector3.UP, _pivot.rotation.y)
    if _input_dir.length() > 1.0: _input_dir = _input_dir.normalized()
    if is_player_actionable() == false:
            return
    var accel : float = _air_accel if _state == Global.PlayerState.AERIAL else _accel
    var move_dir : Vector3 = _input_dir - _visuals.transform.basis.y * _input_dir.dot(_visuals.transform.basis.y)
    move_vec = move_dir
    _rb.apply_central_force(move_dir * delta * accel)

func _handle_states() -> void:
    if _state == Global.PlayerState.SHOCKED or _state == Global.PlayerState.FINISHED or _state == Global.PlayerState.STARTING:
        return
    if _ticks_since_touching_ground < COYOTE_TIME: # 4 frames of buffer time
        if (_state == Global.PlayerState.HALF_PIPE and _rb.linear_velocity.y < 0.0) or _state == Global.PlayerState.AERIAL:
            if _state == Global.PlayerState.HALF_PIPE:
                _rb.apply_central_impulse(Vector3(0.2 * _rb._half_pipe_direction, _rb.linear_velocity.y, _rb.linear_velocity.z))
            set_state(Global.PlayerState.GROUNDED)
            if _boost_ring_active:
                _boost_ring_active = false
            if _boost_on_land:
                _boost_on_land = false
                if _boost_timer > _boost_time:
                    _boost_timer = 0.0
                    _boost_time = 0.25
                else:
                    _boost_time += 0.25
                _rb.apply_central_impulse(_rb.linear_velocity.normalized() * _boost_power)
    elif _state != Global.PlayerState.HALF_PIPE and _state != Global.PlayerState.GRINDING:
        set_state(Global.PlayerState.AERIAL)

func _handle_orientation(delta: float) -> void:
    var move_dir : float = atan2(-_rb.linear_velocity.normalized().x, -_rb.linear_velocity.normalized().z)
    if(_state == Global.PlayerState.GRINDING):
        _pivot.rotation.y = lerp_angle(_pivot.rotation.y, 0.0, delta * 10.0 * CAMERA_ROTATE_LERP)
        _visuals.rotation.y = lerp_angle(_visuals.rotation.y, 0.0, delta * 10.0 * ROTATION_SPEED)
    elif(!is_equal_approx(_rb.linear_velocity.x, 0.0) or !is_equal_approx(_rb.linear_velocity.z, 0.0) and _state != Global.PlayerState.FINISHED):
        _pivot.rotation.y = lerp_angle(_pivot.rotation.y, move_dir, delta * _rb.linear_velocity.length() * CAMERA_ROTATE_LERP)
        if(_state != Global.PlayerState.AERIAL):
            _visuals.rotation.y = lerp_angle(_visuals.rotation.y, move_dir, delta * ROTATION_SPEED)
    else:
        _pivot.rotation.y = lerp_angle(_pivot.rotation.y, 0.0, delta * 10.0 * CAMERA_ROTATE_LERP)
    var raycast_result := _check_raycasts()
    if _state == Global.PlayerState.SHOCKED:
        if raycast_result.size() > 0:
            var avg_normal : Vector3 = Vector3.ZERO
            for res in raycast_result:
                avg_normal += res.get_collision_normal()
            avg_normal /= raycast_result.size()
            _visuals.global_transform = _align_with_y(_visuals.global_transform, avg_normal) 
        else:
            _visuals.global_transform = _align_with_y(_visuals.global_transform, Vector3.UP)
        _visuals.rotation.y = 0.0
        $PlayerVisuals/Mesh.rotation.y = deg_to_rad(180.0) if _turned_180 else 0.0
    elif raycast_result.size() > 0:
        var avg_normal : Vector3 = Vector3.ZERO
        for res in raycast_result:
            avg_normal += res.get_collision_normal()
        avg_normal /= raycast_result.size()
        var xform := _align_with_y(_visuals.global_transform, avg_normal)
        _visuals.global_transform = _visuals.global_transform.interpolate_with(xform, delta * XFORM_SPEED)
    elif _rb.linear_velocity != Vector3.ZERO:
        var target_offset : Vector3 = Vector3.ZERO
        if abs(Vector3.UP.dot(_rb.linear_velocity.normalized())) > 0.98:
            target_offset.z = -0.01
        _visuals.look_at(_visuals.global_position + _rb.linear_velocity.normalized() + target_offset, _visuals.basis.y)
    elif _state == Global.PlayerState.GRINDING:
        _visuals.global_rotation = _grind_rail.get_follow_rotation()

func _check_raycasts() -> Array[RayCast3D]:
    var result : Array[RayCast3D] = []
    for child in _raycasts.get_children():
        if child is not RayCast3D: continue
        var raycast := child as RayCast3D
        if raycast.is_colliding():
            result.push_back(raycast)
    return result

func _trick() -> void:
    if _current_trick:
        if _state == Global.PlayerState.GRINDING:
            _current_trick.trick_value += GRIND_TRICK_RATE + (_current_trick.trick_level * 2)
            Global.currentTrickUpdated.emit(_current_trick)
        elif _state == Global.PlayerState.HALF_PIPE:
            _current_trick.trick_value += HALF_PIPE_TRICK_RATE
            Global.currentTrickUpdated.emit(_current_trick)

func _grind(delta: float) -> void:
    if _state != Global.PlayerState.GRINDING:
        return
    if _grind_rail == null:
        set_state(Global.PlayerState.AERIAL)
        return
    _grind_rail.move_grind_pos(delta)
    _rb.global_position = _grind_rail.get_grind_pos()
    if _grind_rail.get_grind_ratio() > 0.98:
        _stop_grind()

func _start_grind(rail: GrindRail) -> void:
    _grind_rail = rail
    set_state(Global.PlayerState.GRINDING)
    _grind_rail.set_grind_pos(_grind_rail.find_nearest_start_ratio(_rb.global_position))
    _rb.global_position = _grind_rail.get_grind_pos()
    _grind_sound_id = Audio.play(_stream_grinding, 1.1)

func _stop_grind() -> void:
    set_state(Global.PlayerState.AERIAL)
    _ticks_since_touching_ground = COYOTE_TIME
    _last_grind_rail = _grind_rail
    _grind_rail = null
    var exit_vel : Vector3 = Vector3((Input.get_action_strength("move_right") - Input.get_action_strength("move_left")) * 0.3, 0.2, -1.0)
    _rb.apply_central_impulse(exit_vel.normalized() * _max_velocity)
    _boost_on_land = true
    Audio.stop(_grind_sound_id)
    Audio.play(_stream_jump, 0.2)

func _aerial(delta: float) -> void:
    if _state != Global.PlayerState.AERIAL:
        _aerial_rotate_velocity = 0
        return
    var input_val : float = Input.get_action_strength("move_left") - Input.get_action_strength("move_right")
    if input_val == 0.0:
        _aerial_rotate_velocity = move_toward(_aerial_rotate_velocity, 0.0, _aerial_rotate_accel)
    else:
        _aerial_rotate_velocity += _aerial_rotate_accel * (Input.get_action_strength("move_left") - Input.get_action_strength("move_right"))
    _aerial_rotate_velocity = clampf(_aerial_rotate_velocity, _aerial_rotate_max_speed * -1.0, _aerial_rotate_max_speed)
    _total_aerial_rotation += _aerial_rotate_velocity * delta
    $PlayerVisuals/Mesh.rotate_y(_aerial_rotate_velocity * delta)

func _jump() -> void:
    if _state == Global.PlayerState.GRINDING and _grind_rail:
        if _grind_rail._can_jump_off: _stop_grind()

func _boost() -> void:
    if _boost_timer < _boost_time:
        _rb._max_velocity = _max_velocity * _boost_factor
    else:
        _rb._max_velocity = _max_velocity

func _align_with_y(xform: Transform3D, new_y: Vector3) -> Transform3D:
    xform.basis.y = new_y
    xform.basis.x = -xform.basis.z.cross(new_y)
    xform.basis = xform.basis.orthonormalized()
    return xform

func _check_for_180() -> void:
    var rot_deg : int = abs(int(rad_to_deg(_total_aerial_rotation)))
    var spins : int = roundi(rot_deg / 180.0)
    var spin_error : int = min(abs(rot_deg % 180), abs(rot_deg % 180 - 180))
    if spin_error < AERIAL_180_LEEWAY and spins > 0:
        if roundi(rot_deg / 180.0) % 2 == 1:
            _turned_180 = !_turned_180
        Global.trickScored.emit(Trick.new(str(spins * 180) + "° SPIN", spins * SPIN_TRICK_RATE, Trick.Type.SPIN))

func _collect_coin(coin: SlickCoin) -> void:
    _coins[coin._letter] = true

func _shock() -> void:
    if _state != Global.PlayerState.SHOCKED:
        $PlayerVisuals/Mesh/Armature.visible = true
        return
    if _shock_timer >= SHOCK_TIME:
        set_state(Global.PlayerState.GROUNDED)
        $PlayerVisuals/Mesh.position.x = 0.0
    else:
        $PlayerVisuals/Mesh/Armature.visible = roundi(_shock_timer / get_physics_process_delta_time()) % 3 != 0
        var coefficient : float = 1.0 if randi() % 2 else -1.0
        $PlayerVisuals/Mesh.position.x = 0.1 * (SHOCK_TIME - _shock_timer) * coefficient

func _get_level_grade(score: int) -> String:
    var all_coins_collected = true
    for letter in _coins:
        if _coins[letter] == false:
            all_coins_collected = false
    return _level.calculate_rank(score, all_coins_collected)

func _animate(_delta: float) -> void:
    if _state == Global.PlayerState.SHOCKED:
        $AnimationTree.set("parameters/conditions/shocked", true)
    else:
        $AnimationTree.set("parameters/conditions/shocked", false)
        $AnimationTree.get("parameters/playback").travel("Sliding")

## ========== SIGNAL CALLBACKS ==========

func _on_area_3d_area_entered(area: Area3D) -> void:
    if _state == Global.PlayerState.SHOCKED:
        return
    var mask := String.num_int64(area.collision_layer, 2)
    if mask[mask.length() - 3] == "1":
        # half pipe zone
        _rb._half_pipe_direction = 1.0 if _rb.global_position.x < 0 else -1.0
        if _current_trick:
            Global.trickScored.emit(_current_trick)
        set_state(Global.PlayerState.HALF_PIPE)
    elif mask[mask.length() - 4] == "1":
        # grind rail
        _start_grind(area as GrindRail)
    elif mask[mask.length() - 5] == "1":
        # boost ring
        if _boost_ring_active == false:
            _boost_ring_active = true
            _boost_timer = 0.0
            _boost_time = 1.0
            _rb.apply_central_impulse(Vector3(0.0, 0.0, _boost_power * -1).rotated(Vector3.RIGHT, deg_to_rad(-15)))
            Global.trickScored.emit(Trick.new("BOOST RING", BOOST_RING_TRICK_VALUE, Trick.Type.BOOST_RING))
            Audio.play(_stream_boost_ring, 0.5)
    elif mask[mask.length() - 7] == "1":
        # slick coin
        var coin := area as SlickCoin
        _collect_coin(coin)
        Global.slickCoinCollected.emit(coin)
    elif mask[mask.length() - 9] == "1":
        # electric ball
        _current_trick = null
        set_state(Global.PlayerState.SHOCKED)
        _shock_timer = 0.0
        Global.scorePenalty.emit(Global.ELECTRIC_BALL_PENALTY)
        _score = max(_score - Global.ELECTRIC_BALL_PENALTY, 0)
        area.set_deferred("monitorable", false)
        area.set_deferred("monitoring", false)
        var pos_diff : float = 1.0 if area.global_position.x < _rb.global_position.x else -1.0
        _rb.apply_central_impulse(Vector3(pos_diff * 4.0, 0.0, _rb.linear_velocity.length() * 1.2))
        Audio.stop(_grind_sound_id)
        Audio.play(_stream_shock)
    elif mask[mask.length() - 10] == "1":
        # finish line
        _rb._auto_move = false
        set_state(Global.PlayerState.FINISHED)
        var final_score : int = _score + ceili(_level_timer.time_left) * Global.TIME_SCORE_VALUE + _drums_collected * Global.DRUM_SCORE_VALUE
        Global.levelFinished.emit(_score, _level_timer.time_left, _drums_collected, _total_drums, _get_level_grade(final_score))
        _score = final_score
        Global.checkForPlayerHighScore.emit(_level._level_number, _score, _get_level_grade(final_score))
        Audio.play(_stream_level_complete)
    elif mask[mask.length() - 11] == "1":
        # boost pad
        _boost_timer = 0.0
        _boost_time = 1.0
        _rb.apply_central_impulse(_rb.linear_velocity.normalized() * _boost_power)
        Global.trickScored.emit(Trick.new("BOOST PAD", BOOST_PAD_TRICK_VALUE, Trick.Type.BOOST_PAD))
        Audio.play(_stream_boost_pad)
    elif mask[mask.length() - 12] == "1":
        # grease drum
        _drums_collected += 1
        Audio.play(_stream_drum_collected)

func _on_trick_scored(trick: Trick) -> void:
    _score += trick.trick_value
    Audio.play(_stream_trick_landed, 0.2)

func _on_level_started(level: Level, level_timer: float, total_drums: int) -> void:
    _total_aerial_rotation = 0.0
    _level = level
    _level_timer.start(level_timer)
    _total_drums = total_drums
    _rb.freeze = false
    set_state(Global.PlayerState.GROUNDED)
    Global.levelTimerUpdate.emit(level_timer)
    
