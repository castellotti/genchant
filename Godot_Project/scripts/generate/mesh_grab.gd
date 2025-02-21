@tool
extends Node3D
class_name GrabPointManager

# Constants for grab point positioning
const GRAB_POINT_OFFSET = 0.05  # Offset from mesh surface
const CENTER_GRAB_ENABLED = true
const EXTREMITY_GRAB_ENABLED = true

# References to grab point scenes
var _grab_point_left_scene = preload("res://addons/godot-xr-tools/objects/grab_points/grab_point_hand_left.tscn")
var _grab_point_right_scene = preload("res://addons/godot-xr-tools/objects/grab_points/grab_point_hand_right.tscn")

# Array to store all grab points for cleanup
var _grab_points: Array[Node3D] = []

# Reference to the parent RigidBody3D
var _rigid_body: RigidBody3D

func _init(rigid_body: RigidBody3D) -> void:
    _rigid_body = rigid_body

func setup_grab_points(bounds: AABB, scale_factor: float) -> void:
    # Clear any existing grab points
    clear_grab_points()
    
    var scaled_bounds = AABB(
        bounds.position * scale_factor,
        bounds.size * scale_factor
    )
    
    if CENTER_GRAB_ENABLED:
        _add_center_grab_points(scaled_bounds)
    
    if EXTREMITY_GRAB_ENABLED:
        _add_extremity_grab_points(scaled_bounds)

func _add_center_grab_points(bounds: AABB) -> void:
    var center = bounds.get_center()
    
    # Add center grab points for both hands
    _add_grab_point_pair(
        center,
        Vector3.UP,  # Default orientation
        1  # Center grab mode
    )

func _add_extremity_grab_points(bounds: AABB) -> void:
    var min_point = bounds.position
    var max_point = bounds.position + bounds.size
    
    # Add grab points at key extremities
    var extremity_points = [
        # Top center
        [Vector3(bounds.get_center().x, max_point.y, bounds.get_center().z), Vector3.UP],
        # Bottom center
        [Vector3(bounds.get_center().x, min_point.y, bounds.get_center().z), Vector3.DOWN],
        # Front center
        [Vector3(bounds.get_center().x, bounds.get_center().y, max_point.z), Vector3.FORWARD],
        # Back center
        [Vector3(bounds.get_center().x, bounds.get_center().y, min_point.z), Vector3.BACK],
        # Left center
        [Vector3(min_point.x, bounds.get_center().y, bounds.get_center().z), Vector3.LEFT],
        # Right center
        [Vector3(max_point.x, bounds.get_center().y, bounds.get_center().z), Vector3.RIGHT]
    ]
    
    # Add grab points at each extremity
    for point in extremity_points:
        _add_grab_point_pair(
            point[0],  # Position
            point[1],  # Orientation
            2  # Extremity grab mode
        )

func _add_grab_point_pair(origin_position: Vector3, orientation: Vector3, mode: int) -> void:
    # Create left hand grab point
    var left_grab = _grab_point_left_scene.instantiate()
    left_grab.mode = mode
    left_grab.transform.origin = origin_position
    _orient_grab_point(left_grab, orientation)
    _rigid_body.add_child(left_grab)
    _grab_points.append(left_grab)
    
    # Create right hand grab point
    var right_grab = _grab_point_right_scene.instantiate()
    right_grab.mode = mode
    right_grab.transform.origin = origin_position
    _orient_grab_point(right_grab, orientation)
    _rigid_body.add_child(right_grab)
    _grab_points.append(right_grab)

func _orient_grab_point(grab_point: Node3D, direction: Vector3) -> void:
    # Create a basis that orients the grab point along the given direction
    var up = direction
    var forward = Vector3.FORWARD
    if up.is_equal_approx(Vector3.FORWARD) or up.is_equal_approx(Vector3.BACK):
        forward = Vector3.UP
    var right = forward.cross(up).normalized()
    forward = up.cross(right).normalized()
    
    grab_point.transform.basis = Basis(right, up, forward)

func clear_grab_points() -> void:
    for point in _grab_points:
        if is_instance_valid(point):
            point.queue_free()
    _grab_points.clear()
