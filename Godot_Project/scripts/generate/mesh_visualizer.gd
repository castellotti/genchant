extends Node3D
class_name MeshVisualizer

const SPHERE_RADIUS = 0.25  # 25cm radius for vertex spheres
const TARGET_SIZE = 1.0  # Target size in meters for the bounding cube
const INITIAL_HEIGHT = 1.0  # Initial height off the floor in meters

var _mesh_generator: MeshGenerator
var _st := SurfaceTool.new()
var _vertex_spheres: Array[MeshInstance3D] = []
var _final_mesh: MeshInstance3D
var _bounding_box: MeshInstance3D
var _collision_shape: CollisionShape3D
var _rigid_body: RigidBody3D
var _current_vertices := PackedVector3Array()
var _current_indices := PackedInt32Array()
var _current_bounds: AABB
var _scale_factor: float = 1.0
var _total_vertices: int = 0

func _ready() -> void:
    # Create RigidBody3D as parent for final mesh
    _rigid_body = RigidBody3D.new()
    add_child(_rigid_body)

    # Set up collision shape
    _collision_shape = CollisionShape3D.new()
    _rigid_body.add_child(_collision_shape)

    # Configure physics properties
    _rigid_body.mass = 1.0
    _rigid_body.physics_material_override = PhysicsMaterial.new()
    _rigid_body.physics_material_override.bounce = 0.3
    _rigid_body.physics_material_override.friction = 0.8

    # Create final mesh instance
    _final_mesh = MeshInstance3D.new()
    _rigid_body.add_child(_final_mesh)

    var material = StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
    _final_mesh.material_override = material

    # Create bounding box visualization
    _bounding_box = MeshInstance3D.new()
    _rigid_body.add_child(_bounding_box)
    var box_material = StandardMaterial3D.new()
    box_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    box_material.albedo_color = Color(1, 1, 1, 0.25)
    _bounding_box.material_override = box_material

    # Set up mesh generator
    _mesh_generator = MeshGenerator.new()
    add_child(_mesh_generator)
    _mesh_generator.mesh_update.connect(_on_mesh_update)
    _mesh_generator.generation_complete.connect(_on_generation_complete)

func generate(prompt: String) -> void:
    # Clear existing visualization
    _clear_visualization()

    # Reset state
    _current_vertices.clear()
    _current_indices.clear()
    _current_bounds = AABB()
    _scale_factor = 1.0
    _total_vertices = 0

    # Hide rigid body and its children until complete
    _rigid_body.visible = false

    # Start generation
    _mesh_generator.clear()
    _mesh_generator.generate_mesh(prompt)

func _clear_visualization() -> void:
    # Remove all vertex spheres
    for sphere in _vertex_spheres:
        sphere.queue_free()
    _vertex_spheres.clear()

    # Clear final mesh and bounds
    _final_mesh.mesh = null
    _bounding_box.mesh = null
    if _collision_shape.shape:
        _collision_shape.shape = null

func _add_vertex_sphere(new_position: Vector3) -> void:
    var sphere_mesh = SphereMesh.new()
    sphere_mesh.radius = SPHERE_RADIUS
    sphere_mesh.height = SPHERE_RADIUS * 2

    var sphere_instance = MeshInstance3D.new()
    sphere_instance.mesh = sphere_mesh

    var material = StandardMaterial3D.new()
    material.albedo_color = Color.BLACK
    sphere_instance.material_override = material

    sphere_instance.position = new_position
    add_child(sphere_instance)
    _vertex_spheres.append(sphere_instance)

func _update_bounds_and_scale() -> void:
    if _current_vertices.is_empty():
        return

    if _current_bounds.size == Vector3.ZERO:
        _current_bounds = AABB(_current_vertices[0], Vector3.ZERO)

    for vertex in _current_vertices:
        _current_bounds = _current_bounds.expand(vertex)

    var max_dimension = max(_current_bounds.size.x, max(_current_bounds.size.y, _current_bounds.size.z))
    _scale_factor = TARGET_SIZE / max_dimension if max_dimension > 0 else 1.0

func _on_mesh_update(vertices: PackedVector3Array, indices: PackedInt32Array) -> void:
    _current_vertices = vertices
    _current_indices = indices

    # Update vertex spheres
    if vertices.size() > _total_vertices:
        for i in range(_total_vertices, vertices.size()):
            _add_vertex_sphere(vertices[i])
        _total_vertices = vertices.size()

    for i in range(vertices.size()):
        if i < _vertex_spheres.size():
            _vertex_spheres[i].position = vertices[i]

    # Create streaming mesh with faces
    if not vertices.is_empty() and not indices.is_empty():
        _st.clear()
        _st.begin(Mesh.PRIMITIVE_TRIANGLES)
        
        for i in range(vertices.size()):
            var vertex = vertices[i]
            var y_normalized = 0.5  # Use a constant color during streaming
            var color = Color(y_normalized, 0.0, 1.0 - y_normalized, 1.0)
            _st.set_color(color)
            _st.add_vertex(vertex)
        
        for i in range(0, indices.size(), 3):
            _st.add_index(indices[i])
            _st.add_index(indices[i + 1])
            _st.add_index(indices[i + 2])
            
        _st.generate_normals()
        _final_mesh.mesh = _st.commit()

func _update_final_mesh() -> void:
    if _current_vertices.is_empty():
        return

    # Calculate bounds and scale
    _update_bounds_and_scale()

    _st.clear()
    _st.begin(Mesh.PRIMITIVE_TRIANGLES)

    # Add vertices with height-based coloring
    for vertex in _current_vertices:
        var scaled_vertex = vertex * _scale_factor
        var y_normalized = (vertex.y - _current_bounds.position.y) / _current_bounds.size.y if _current_bounds.size.y > 0 else 0.0
        var color = Color(y_normalized, 0.0, 1.0 - y_normalized, 1.0)
        _st.set_color(color)
        _st.add_vertex(scaled_vertex)

    # Add faces
    if not _current_indices.is_empty():
        for i in range(0, _current_indices.size(), 3):
            _st.add_index(_current_indices[i])
            _st.add_index(_current_indices[i + 1])
            _st.add_index(_current_indices[i + 2])

    _st.generate_normals()
    _final_mesh.mesh = _st.commit()

    # Update collision shape and bounding box
    var scaled_bounds = AABB(_current_bounds.position * _scale_factor, _current_bounds.size * _scale_factor)
    _update_collision_shape(scaled_bounds)
    _update_bounding_box(scaled_bounds)

    # Reset position and show final mesh
    _rigid_body.position.y = INITIAL_HEIGHT
    _rigid_body.freeze = false
    _rigid_body.visible = true

func _update_bounding_box(bounds: AABB) -> void:
    var box_mesh = BoxMesh.new()
    box_mesh.size = bounds.size
    _bounding_box.mesh = box_mesh
    _bounding_box.position = bounds.position + bounds.size * 0.5

func _update_collision_shape(bounds: AABB) -> void:
    var box_shape = BoxShape3D.new()
    box_shape.size = bounds.size
    _collision_shape.shape = box_shape
    _collision_shape.position = bounds.position + bounds.size * 0.5

func _on_generation_complete(success: bool) -> void:
    if success:
        print("Mesh generation complete - Creating final mesh")
        _update_final_mesh()
        
        # Only remove vertex spheres after final mesh is created
        if not Globals.DEBUG:
            for sphere in _vertex_spheres:
                sphere.queue_free()
            _vertex_spheres.clear()
    else:
        push_error("Mesh generation failed")
        
