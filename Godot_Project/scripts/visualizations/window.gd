extends Node3D
class_name VisualizationWindow

# Customize the window’s transform, size, and shader resources:
@export var window_position: Vector3 = Vector3.ZERO
@export var window_rotation: Vector3 = Vector3.ZERO  # in degrees
@export var window_size: Vector2 = Vector2(10, 10)

@export var shader_path: String = ""
@export var texture_path: String = ""

var mesh_instance: MeshInstance3D

func setup_window() -> void:
    # Create the MeshInstance3D programmatically.
    mesh_instance = MeshInstance3D.new()
    add_child(mesh_instance)

    # Create a PlaneMesh to use as our window surface.
    var plane := PlaneMesh.new()
    plane.size = window_size
    plane.orientation = 2  # Face Z
    mesh_instance.mesh = plane
    
    # If a shader is provided, load it and create a ShaderMaterial.
    if shader_path != "":
        var shader = load(shader_path)
        if shader:
            var shader_material := ShaderMaterial.new()
            shader_material.shader = shader
            # Optionally, load and assign a texture.
            if texture_path != "":
                var tex = load(texture_path)
                shader_material.set_shader_parameter("img", tex)
            # Set additional shader parameters
            shader_material.set_shader_parameter("x_scale", 10.0)
            shader_material.set_shader_parameter("y_scale", 10.0)
            shader_material.set_shader_parameter("time", 0.5)
            mesh_instance.material_override = shader_material
    
    # Set position and rotation correctly
    transform.origin = window_position
    transform.basis = Basis(Vector3.RIGHT, deg_to_rad(window_rotation.x)) * \
                      Basis(Vector3.UP, deg_to_rad(window_rotation.y)) * \
                      Basis(Vector3.FORWARD, deg_to_rad(window_rotation.z))
