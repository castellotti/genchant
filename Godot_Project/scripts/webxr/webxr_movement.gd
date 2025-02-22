extends Node3D

@export var movement_speed: float = 2.0
@export var turning_speed: float = 30.0 # Degrees per second
@export var snap_turn_angle: float = 30.0 # Degrees per snap turn
@export var use_snap_turning: bool = true

var xr_origin: XROrigin3D
var camera: XRCamera3D
var last_snap_time: float = 0.0
var snap_cooldown: float = 0.3 # Seconds

func _ready():
    # Find XR origin (should be parent)
    xr_origin = get_parent() as XROrigin3D
    if !xr_origin:
        print("WebXR Movement must be a child of an XROrigin3D node")
        queue_free()
        return

    # Get reference to the camera
    camera = xr_origin.get_node("XRCamera3D") as XRCamera3D
    if !camera:
        print("XRCamera3D not found under XROrigin3D")
        queue_free()

func _process(delta):
    var forward_backward = Input.get_axis("move_back", "move_forward")
    var left_right = Input.get_axis("move_left", "move_right")

    if forward_backward != 0 or left_right != 0:
        # Get XR camera basis for proper movement direction
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
                # Apply snap turning without position drift
                rotate_origin_in_place(snap_turn_angle * sign(camera_turn))
                last_snap_time = current_time
        else:
            # Apply smooth turning without position drift
            rotate_origin_in_place(-camera_turn * turning_speed * delta)

# Function to rotate the XR origin around the camera's vertical axis
# This prevents positional drift during rotation
func rotate_origin_in_place(angle_degrees: float) -> void:
    if !xr_origin or !camera:
        return

    # Convert angle to radians
    var angle_radians = deg_to_rad(angle_degrees)

    # Get the current position of the camera (in global space)
    var camera_global_pos = camera.global_transform.origin

    # Create a rotation transform around the Y axis
    var rotation_transform = Transform3D(Basis().rotated(Vector3.UP, angle_radians), Vector3.ZERO)

    # Calculate the offset from camera to origin
    var origin_to_camera = xr_origin.global_transform.origin - camera_global_pos

    # Rotate the offset
    var rotated_offset = rotation_transform.basis * origin_to_camera

    # Calculate new origin position to keep camera in the same place
    var new_origin_pos = camera_global_pos + rotated_offset

    # Create the new transform for the origin
    var new_transform = xr_origin.global_transform
    new_transform.basis = rotation_transform.basis * xr_origin.global_transform.basis
    new_transform.origin = new_origin_pos

    # Apply the new transform
    xr_origin.global_transform = new_transform

    # Optional: Apply slight correction to ensure exact vertical-only rotation
    # This helps prevent any small floating-point errors from accumulating
    var current_origin = xr_origin.global_transform.origin
    current_origin.y = new_origin_pos.y  # Maintain exact Y position
    xr_origin.global_transform.origin = current_origin
