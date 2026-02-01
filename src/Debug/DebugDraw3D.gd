extends Node2D

class Vector:
    var object  # The node to follow
    var property  # The property to draw
    var scale  # Scale factor
    var width  # Line width
    var color  # Draw color
    var follow

    func _init(_object, _property, _scale, _width, _color, _follow):
        object = _object
        property = _property
        scale = _scale
        width = _width
        color = _color
        follow = _follow

    func draw(node, camera):
        var start = camera.unproject_position(follow.global_transform.origin)
        var end = camera.unproject_position(follow.global_transform.origin + object.get(property) * scale)
        node.draw_line(start, end, color, width)
        #node.draw_triangle(end, start.direction_to(end), width*2, color)

var vectors = []  # Array to hold all registered values.

func _process(_delta):
    if not visible:
        return
    queue_redraw()

func _draw():
    var camera = get_viewport().get_camera_3d()
    for vector in vectors:
        vector.draw(self, camera)

func add_vector(object, property, vec_scale, width, color, follow):
    vectors.append(Vector.new(object, property, vec_scale, width, color, follow))
