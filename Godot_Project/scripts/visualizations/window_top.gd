extends VisualizationWindow
class_name TopWindow

func _ready() -> void:
    window_position = Vector3(0, 5, 2)  # Move up
    window_rotation = Vector3(30, 0, 0) # Rotate down
    window_size = Vector2(5, 5)

    shader_path = "res://shaders/matrix/matrix_background.gdshader"

    shader_parameters = {
        "resolution": Vector2(1024, 1024),
        "render_speed": 0.36,
        "rain_speed": 0.5,
    }

    setup_window()
