extends Node3D
class_name SphereVisualization

var shader_material = ShaderMaterial.new()

func _ready() -> void:
    var sphere = CSGSphere3D.new()
    sphere.radius = 1.0
    sphere.radial_segments = 100
    sphere.rings = 64

    if Globals.is_running_in_visionos:
        # Shaders are not currently available in Godot Vision
        # Use a solid red material
        var material = StandardMaterial3D.new()
        material.albedo_color = Color(1, 0, 0, 1)
        sphere.material = material
    else:
        # Use a shader material
        shader_material.shader = load("res://shaders/rgb.gdshader")
        shader_material.set_shader_parameter("speed", 0.5)
        shader_material.set_shader_parameter("linger", 4.0)
        sphere.material = shader_material

    # Adjust position to match the original TSCN placement
    sphere.transform.origin = Vector3(0, 1.7, 0)
    
    add_child(sphere)
