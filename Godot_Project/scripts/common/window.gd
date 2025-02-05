extends Node3D
class_name VisualizationWindow

@export var window_position: Vector3 = Vector3.ZERO
@export var window_rotation: Vector3 = Vector3.ZERO  # in degrees
@export var window_size: Vector2 = Vector2(10, 10)

@export var shader_path: String = ""
@export var texture_path: String = ""
@export var shader_parameters: Dictionary = {}  # Allows subclasses to define parameters

var mesh_instance: MeshInstance3D

func setup_window() -> void:
    mesh_instance = MeshInstance3D.new()
    add_child(mesh_instance)

    var plane := PlaneMesh.new()
    plane.size = window_size
    plane.orientation = PlaneMesh.Orientation.FACE_Z
    mesh_instance.mesh = plane

    # Load shader if not provided by subclass
    var shader_material = create_shader_material()

    if shader_material:
        mesh_instance.material_override = shader_material

    # Set position and rotation
    transform.origin = window_position
    transform.basis = Basis(Vector3.RIGHT, deg_to_rad(window_rotation.x)) * \
                      Basis(Vector3.UP, deg_to_rad(window_rotation.y)) * \
                      Basis(Vector3.FORWARD, deg_to_rad(window_rotation.z))

func create_shader_material() -> ShaderMaterial:
    if shader_path == "":
        return null

    var shader = load(shader_path)
    if shader:
        var shader_material := ShaderMaterial.new()
        shader_material.shader = shader

        # Optionally load texture
        if texture_path != "":
            var tex = load(texture_path)
            shader_material.set_shader_parameter("img", tex)

        # Apply shader parameters from dictionary
        for key in shader_parameters.keys():
            shader_material.set_shader_parameter(key, shader_parameters[key])

        return shader_material

    return null
