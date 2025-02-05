extends VisualizationWindow
class_name MatrixWindow

func _ready() -> void:
    window_position = Vector3(0, 1, 6.5)  # Move forward
    window_size = Vector2(5, 5)

    shader_path = "res://assets/shaders/digital_matrix_rain.gdshader"

    shader_parameters = {
        "resolution": Vector2(1024, 1024),
        "render_speed": 0.36,
        "rain_speed": 0.5,
    }

    setup_window()
