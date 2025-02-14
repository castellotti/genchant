extends Node3D
class_name Matrix3DRainVisualization

var shader_material: ShaderMaterial
var background_rect: ColorRect
var canvas_layer: CanvasLayer

func _ready():
    # Load resources
    var matrix_texture = load("res://assets/textures/matrix_3d_rain.png")
    if not matrix_texture:
        push_error("Failed to load matrix texture!")
        return
        
    var shader = load("res://shaders/matrix/matrix_3d_rain.gdshader")
    if not shader:
        push_error("Failed to load shader!")
        return
    
    # Create CanvasLayer to control rendering order
    canvas_layer = CanvasLayer.new()
    canvas_layer.layer = -1
    add_child(canvas_layer)
    
    # Create background ColorRect
    background_rect = ColorRect.new()
    background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
    background_rect.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
    
    # Create and setup shader material
    shader_material = ShaderMaterial.new()
    shader_material.shader = shader
    shader_material.set_shader_parameter("matrix_texture", matrix_texture)
    background_rect.material = shader_material
    
    # Add to canvas layer
    canvas_layer.add_child(background_rect)
    
    # Print debug info
    print("Matrix texture size: ", matrix_texture.get_size() if matrix_texture else "No texture")
    print("ColorRect rect: ", background_rect.get_rect())
    
    set_process(true)

func _process(_delta: float) -> void:
    if shader_material:
        var current_time = Time.get_ticks_msec() / 1000.0
        shader_material.set_shader_parameter("time", current_time)
