extends MeshInstance3D
class_name MeshVisualizer

const TARGET_SIZE = 1.0  # Target size in meters for the bounding cube
const INITIAL_HEIGHT = 1.0  # Initial height off the floor in meters

var _mesh_generator: MeshGenerator
var _st := SurfaceTool.new()
var _material: StandardMaterial3D
var _current_vertices := PackedVector3Array()
var _current_indices := PackedInt32Array()
var _bounding_box: MeshInstance3D
var _collision_shape: CollisionShape3D
var _rigid_body: RigidBody3D

func _ready() -> void:
    # Create RigidBody3D as parent
    _rigid_body = RigidBody3D.new()
    var parent = get_parent()
    parent.remove_child(self)
    _rigid_body.add_child(self)
    parent.add_child(_rigid_body)
    
    # Set up collision shape
    _collision_shape = CollisionShape3D.new()
    _rigid_body.add_child(_collision_shape)
    
    # Configure physics properties
    _rigid_body.mass = 1.0  # 1kg mass
    _rigid_body.physics_material_override = PhysicsMaterial.new()
    _rigid_body.physics_material_override.bounce = 0.3
    _rigid_body.physics_material_override.friction = 0.8
    
    # Set up material
    _material = StandardMaterial3D.new()
    _material.vertex_color_use_as_albedo = true
    _material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
    material_override = _material

    # Create bounding box mesh instance
    _bounding_box = MeshInstance3D.new()
    add_child(_bounding_box)

    # Create transparent material for bounding box
    var box_material = StandardMaterial3D.new()
    box_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    box_material.albedo_color = Color(1, 1, 1, 0.25)
    _bounding_box.material_override = box_material

    _mesh_generator = MeshGenerator.new()
    add_child(_mesh_generator)

    _mesh_generator.mesh_update.connect(_on_mesh_update)
    _mesh_generator.generation_complete.connect(_on_generation_complete)

func generate(prompt: String) -> void:
    _current_vertices.clear()
    _current_indices.clear()
    mesh = null
    _bounding_box.mesh = null
    if _collision_shape.shape:
        _collision_shape.shape = null
    _mesh_generator.clear()
    _mesh_generator.generate_mesh(prompt)

func _on_mesh_update(vertices: PackedVector3Array, indices: PackedInt32Array) -> void:
    _current_vertices = vertices
    _current_indices = indices
    _update_mesh()

func _update_mesh() -> void:
    if _current_vertices.is_empty():
        return

    _st.clear()
    _st.begin(Mesh.PRIMITIVE_TRIANGLES)

    # Calculate bounds for color gradient and scaling
    var bounds = AABB()
    if not _current_vertices.is_empty():
        bounds = AABB(_current_vertices[0], Vector3.ZERO)
        for vertex in _current_vertices:
            bounds = bounds.expand(vertex)
    
    # Calculate scaling factor to fit within target size
    var max_dimension = max(bounds.size.x, max(bounds.size.y, bounds.size.z))
    var scale_factor = TARGET_SIZE / max_dimension if max_dimension > 0 else 1.0
    
    # Add vertices with colors and apply scaling
    for vertex in _current_vertices:
        var scaled_vertex = vertex * scale_factor
        var y_normalized = (vertex.y - bounds.position.y) / bounds.size.y if bounds.size.y > 0 else 0.0
        var color = Color(y_normalized, 0.0, 1.0 - y_normalized, 1.0)
        
        _st.set_color(color)
        _st.add_vertex(scaled_vertex)

    # Add faces
    if not _current_indices.is_empty():
        for i in range(0, _current_indices.size(), 3):
            _st.add_index(_current_indices[i])
            _st.add_index(_current_indices[i + 1])
            _st.add_index(_current_indices[i + 2])
    else:
        for i in range(0, _current_vertices.size(), 3):
            if i + 2 < _current_vertices.size():
                _st.add_index(i)
                _st.add_index(i + 1)
                _st.add_index(i + 2)

    _st.generate_normals()
    mesh = _st.commit()

    # Update collision shape
    var scaled_bounds = AABB(bounds.position * scale_factor, bounds.size * scale_factor)
    _update_collision_shape(scaled_bounds)
    
    # Update bounding box visualization
    #_update_bounding_box(scaled_bounds)
    
    # Set initial position
    _rigid_body.position.y = INITIAL_HEIGHT
    _rigid_body.freeze = false  # Allow physics to take effect

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
        print("Mesh generation complete")
        _update_mesh()
    else:
        push_error("Mesh generation failed")
