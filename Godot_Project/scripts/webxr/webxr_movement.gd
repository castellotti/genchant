extends Node

@export var movement_speed: float = 2.0
@export var turning_speed: float = 30.0 # Degrees per second
@export var snap_turn_angle: float = 30.0 # Degrees per snap turn
@export var use_snap_turning: bool = true

var xr_origin: XROrigin3D
var last_snap_time: float = 0.0
var snap_cooldown: float = 0.3 # Seconds

func _ready():
    xr_origin = get_parent() as XROrigin3D
    if !xr_origin:
        print("WebXR Movement must be a child of an XROrigin3D node")
        queue_free()

func _process(delta):
    var forward_backward = Input.get_axis("move_back", "move_forward")
    var left_right = Input.get_axis("move_left", "move_right")

    if forward_backward != 0 or left_right != 0:
        # Get XR camera basis for proper movement direction
        var camera = xr_origin.get_node("XRCamera3D")
        var camera_basis = camera.global_transform.basis

        # We only want horizontal movement, so zero out the y components
        var forward = -camera_basis.z
        forward.y = 0
        forward = forward.normalized()

        var right = camera_basis.x
        right.y = 0
        right = right.normalized()

        # Calculate movement vector
        var movement = forward * forward_backward + right * left_right
        if movement.length() > 1.0:
            movement = movement.normalized()

        # Apply movement to the XR origin
        xr_origin.global_translate(movement * movement_speed * delta)

    # Handle turning
    var camera_turn = Input.get_axis("camera_left", "camera_right")
    if camera_turn != 0:
        if use_snap_turning:
            var current_time = Time.get_ticks_msec() / 1000.0
            if current_time - last_snap_time > snap_cooldown:
                # Apply snap turning
                var rotation_angle = snap_turn_angle * sign(camera_turn)
                xr_origin.rotate_y(deg_to_rad(rotation_angle))
                last_snap_time = current_time
        else:
            # Apply smooth turning
            xr_origin.rotate_y(deg_to_rad(-camera_turn * turning_speed * delta))
