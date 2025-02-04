extends VisualizationWindow
class_name RightWindow

func _ready() -> void:
    # Set properties before calling `setup_window()`
    window_position = Vector3(2, 1.5, 2)  # Move to the right
    window_rotation = Vector3(0, -45, 0)    # Rotate left
    window_size = Vector2(2, 2)

    # Set the same shader and texture
    shader_path = "res://assets/shaders/matrix_hologram.gdshader"
    texture_path = "res://assets/textures/matrix_hologram.png"

    setup_window()
