extends VisualizationWindow
class_name LeftWindow

func _ready() -> void:
    window_position = Vector3(-2, 1.5, 2)  # Move to the left
    window_rotation = Vector3(0, 45, 0)    # Rotate right
    window_size = Vector2(2, 2)

    shader_path = "res://shaders/matrix/matrix_hologram.gdshader"
    texture_path = "res://assets/textures/matrix_hologram.png"
    shader_parameters = {
        "x_scale": 10.0,
        "y_scale": 10.0,
        "time": 0.5
    }

    setup_window()
