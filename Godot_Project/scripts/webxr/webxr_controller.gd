extends Node

signal joystick_moved(controller, axis, value)
signal button_pressed(controller, button)
signal button_released(controller, button)

var left_controller: XRController3D
var right_controller: XRController3D
var xr_interface

var left_joystick = Vector2.ZERO
var right_joystick = Vector2.ZERO

# Button mapping constants
const THUMBSTICK = 4
const X_BUTTON = 7
const Y_BUTTON = 15
const A_BUTTON = 7
const B_BUTTON = 1

func _ready():
    # Wait a frame to let controllers initialize
    await get_tree().process_frame
    
    xr_interface = XRServer.find_interface("WebXR")
    if !xr_interface:
        print("WebXR interface not found")
        queue_free()
        return
        
    # Find the controllers
    var origin = get_parent()
    for child in origin.get_children():
        if child is XRController3D:
            if child.tracker == "left_hand":
                left_controller = child
            elif child.tracker == "right_hand":
                right_controller = child
    
    if left_controller:
        left_controller.button_pressed.connect(_on_left_controller_button_pressed)
        left_controller.button_released.connect(_on_left_controller_button_released)
        left_controller.input_float_changed.connect(_on_left_controller_input_float_changed)
    
    if right_controller:
        right_controller.button_pressed.connect(_on_right_controller_button_pressed)
        right_controller.button_released.connect(_on_right_controller_button_released)
        right_controller.input_float_changed.connect(_on_right_controller_input_float_changed)

func _on_left_controller_button_pressed(button):
    emit_signal("button_pressed", "left", button)
    
func _on_left_controller_button_released(button):
    emit_signal("button_released", "left", button)
    
func _on_right_controller_button_pressed(button):
    emit_signal("button_pressed", "right", button)
    
func _on_right_controller_button_released(button):
    emit_signal("button_released", "right", button)

func _on_left_controller_input_float_changed(name, value):
    if name == "trigger":
        pass # Handle trigger if needed
    elif name == "grip":
        pass # Handle grip if needed
    elif name == "thumbstick_x":
        left_joystick.x = value
        emit_signal("joystick_moved", "left", "x", value)
    elif name == "thumbstick_y":
        left_joystick.y = value
        emit_signal("joystick_moved", "left", "y", value)

func _on_right_controller_input_float_changed(name, value):
    if name == "trigger":
        pass # Handle trigger if needed
    elif name == "grip":
        pass # Handle grip if needed
    elif name == "thumbstick_x":
        # Invert X-axis for turning
        right_joystick.x = -value
        emit_signal("joystick_moved", "right", "x", -value)
    elif name == "thumbstick_y":
        right_joystick.y = value
        emit_signal("joystick_moved", "right", "y", value)

func _process(_delta):
    # Simulate input events based on joystick positions
    _apply_movement_from_joysticks()
    
func _apply_movement_from_joysticks():
    # Apply left joystick to movement
    if abs(left_joystick.y) > 0.1:
        if left_joystick.y > 0:
            Input.action_press("move_forward", left_joystick.y)
            Input.action_release("move_back")
        else:
            Input.action_press("move_back", -left_joystick.y)
            Input.action_release("move_forward")
    else:
        Input.action_release("move_forward")
        Input.action_release("move_back")
    
    if abs(left_joystick.x) > 0.1:
        if left_joystick.x > 0:
            Input.action_press("move_right", left_joystick.x)
            Input.action_release("move_left")
        else:
            Input.action_press("move_left", -left_joystick.x)
            Input.action_release("move_right")
    else:
        Input.action_release("move_right")
        Input.action_release("move_left")
    
    # Apply right joystick to rotation/camera control
    if abs(right_joystick.x) > 0.5:
        if right_joystick.x > 0:
            Input.action_press("camera_right")
            Input.action_release("camera_left")
        else:
            Input.action_press("camera_left")
            Input.action_release("camera_right")
    else:
        Input.action_release("camera_right")
        Input.action_release("camera_left")
