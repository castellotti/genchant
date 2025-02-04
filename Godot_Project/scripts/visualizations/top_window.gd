extends VisualizationWindow
class_name TopWindow

func _ready() -> void:
    # Set properties before calling `setup_window()`
    window_position = Vector3(0, 5, 2)  # Move up
    #window_position = Vector3(0, 2.5, 6.5)  # Move forward
    window_rotation = Vector3(30, 0, 0) # Rotate down
    window_size = Vector2(5, 5)

    # Set the same shader and texture
    shader_path = "res://assets/shaders/digital_matrix_rain.gdshader"

    setup_window()
