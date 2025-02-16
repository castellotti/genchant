extends Node3D
class_name MeshVisualizer

var _mesh_generator: MeshGenerator
var _st := SurfaceTool.new()
var _vertex_spheres_container: Node3D
var _vertex_spheres: Array[MeshInstance3D] = []
var _final_mesh: MeshInstance3D
var _bounding_box_vertex_spheres: MeshInstance3D
var _bounding_box_final_mesh: MeshInstance3D
var _collision_shape: CollisionShape3D
var _rigid_body: RigidBody3D
var _total_vertices: int = 0
var _metadata: MeshMetadata

func _ready() -> void:
    _metadata = MeshMetadata.new()
    
    # vertex spheres
    _vertex_spheres_container = Node3D.new()
    add_child(_vertex_spheres_container)
    _vertex_spheres_container.position = Vector3(_metadata.vertex_spheres_offset.x, 0, _metadata.vertex_spheres_offset.z)

    if _metadata.vertex_spheres_bounding_box_enabled:    
        _bounding_box_vertex_spheres = MeshInstance3D.new()
        _vertex_spheres_container.add_child(_bounding_box_vertex_spheres)
        var box_material = StandardMaterial3D.new()
        box_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        box_material.albedo_color = Color(1, 1, 1, _metadata.vertex_spheres_bounding_box_alpha)
        _bounding_box_vertex_spheres.material_override = box_material

    # Create RigidBody3D as parent for final mesh
    _rigid_body = RigidBody3D.new()
    add_child(_rigid_body)
    _rigid_body.position = _metadata.final_mesh_offset

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
    if _metadata.final_mesh_bounding_box_enabled:
        _bounding_box_final_mesh = MeshInstance3D.new()
        _rigid_body.add_child(_bounding_box_final_mesh)
        var box_material = StandardMaterial3D.new()
        box_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        box_material.albedo_color = Color(1, 1, 1, _metadata.final_mesh_bounding_box_alpha)
        _bounding_box_final_mesh.material_override = box_material

    # Set up mesh generator
    _mesh_generator = MeshGenerator.new()
    add_child(_mesh_generator)
    _mesh_generator.mesh_update.connect(_on_mesh_update)
    _mesh_generator.generation_complete.connect(_on_generation_complete)

func generate(prompt: String) -> void:
    # Clear existing visualization
    _clear_visualization()

    # Reset state and create new metadata instance
    _metadata = MeshMetadata.new()
    _metadata.prompt = prompt
    _metadata.generation_timestamp = Time.get_unix_time_from_system()
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
    if _bounding_box_vertex_spheres:
        _bounding_box_vertex_spheres.mesh = null
    if _bounding_box_final_mesh:
        _bounding_box_final_mesh.mesh = null
    if _collision_shape.shape:
        _collision_shape.shape = null

func _add_vertex_sphere(new_position: Vector3) -> void:
    var sphere_mesh = SphereMesh.new()
    sphere_mesh.radius = _metadata.sphere_radius * _metadata.scale_factor
    sphere_mesh.height = _metadata.sphere_radius * 2 * _metadata.scale_factor

    var sphere_instance = MeshInstance3D.new()
    sphere_instance.mesh = sphere_mesh

    var material = StandardMaterial3D.new()
    material.albedo_color = Color.BLACK
    sphere_instance.material_override = material

    # Center the position relative to bounds
    var centered_pos = new_position - _metadata.bounds.position - (_metadata.bounds.size / 2)
    var scaled_pos = centered_pos * _metadata.scale_factor
    sphere_instance.position = scaled_pos
    _vertex_spheres_container.add_child(sphere_instance)
    _vertex_spheres.append(sphere_instance)

func _update_bounds_and_scale() -> void:
    if _metadata.vertices.is_empty():
        return

    # Calculate scale factor
    var max_dimension = max(_metadata.bounds.size.x, 
                          max(_metadata.bounds.size.y, _metadata.bounds.size.z))
    var new_scale_factor = _metadata.target_size / max_dimension if max_dimension > 0 else 1.0
    
    # Only update if scale factor has changed
    if new_scale_factor != _metadata.scale_factor:
        _metadata.scale_factor = new_scale_factor
        
        # Update all existing vertex spheres with new scale
        for i in range(_vertex_spheres.size()):
            var sphere = _vertex_spheres[i]
            # Update sphere mesh size
            var sphere_mesh = sphere.mesh as SphereMesh
            sphere_mesh.radius = _metadata.sphere_radius * _metadata.scale_factor
            sphere_mesh.height = _metadata.sphere_radius * 2 * _metadata.scale_factor
            # Update sphere position with centering offset
            var centered_pos = _metadata.vertices[i] - _metadata.bounds.position - (_metadata.bounds.size / 2)
            sphere.position = centered_pos * _metadata.scale_factor

    # Position containers with proper centering
    _vertex_spheres_container.position = _metadata.vertex_spheres_offset
    _rigid_body.position = Vector3(
        _metadata.final_mesh_offset.x,
        _metadata.initial_height + _metadata.final_mesh_offset.y,
        _metadata.final_mesh_offset.z
    )
    _rigid_body.visible = true

func _on_mesh_update(vertices: PackedVector3Array, indices: PackedInt32Array) -> void:
    _metadata.vertices = vertices
    _metadata.indices = indices

    # Update bounds
    if not vertices.is_empty():
        if _metadata.bounds.size == Vector3.ZERO:
            _metadata.bounds = AABB(vertices[0], Vector3.ZERO)
        for vertex in vertices:
            _metadata.bounds = _metadata.bounds.expand(vertex)
    
    # Update scale and positioning
    _update_bounds_and_scale()
    
    # Update vertex spheres bounding box with scaled padding
    if _metadata.vertex_spheres_bounding_box_enabled and _bounding_box_vertex_spheres:
        var scaled_bounds = AABB(_metadata.bounds.position * _metadata.scale_factor, 
                               _metadata.bounds.size * _metadata.scale_factor)
        # Apply padding scaled by the same factor as the mesh
        var scaled_padding = _metadata.vertex_spheres_bounding_box_padding * _metadata.scale_factor
        scaled_bounds = scaled_bounds.grow(scaled_padding)
        _update_bounding_box(_bounding_box_vertex_spheres, scaled_bounds)

    # Update vertex spheres
    if vertices.size() > _total_vertices:
        for i in range(_total_vertices, vertices.size()):
            _add_vertex_sphere(vertices[i])
        _total_vertices = vertices.size()

    # Update existing sphere positions
    for i in range(vertices.size()):
        if i < _vertex_spheres.size():
            _vertex_spheres[i].position = vertices[i] * _metadata.scale_factor

    # Create streaming mesh with faces
    if not vertices.is_empty() and not indices.is_empty():
        _update_mesh(true) # true for streaming mode

func _update_mesh(streaming: bool = false) -> void:
    if _metadata.vertices.is_empty():
        return

    _st.clear()
    _st.begin(Mesh.PRIMITIVE_TRIANGLES)

    # Center vertices around origin
    var center_offset = _metadata.bounds.position + (_metadata.bounds.size / 2)
    
    # Add vertices with height-based coloring
    for vertex in _metadata.vertices:
        var centered_vertex = vertex - center_offset
        var scaled_vertex = centered_vertex * _metadata.scale_factor
        var y_normalized: float
        if streaming:
            y_normalized = 0.5
        else:
            y_normalized = (vertex.y - _metadata.bounds.position.y) / _metadata.bounds.size.y if _metadata.bounds.size.y > 0 else 0.0
        var color = Color(y_normalized, 0.0, 1.0 - y_normalized, 1.0)
        _st.set_color(color)
        _st.add_vertex(scaled_vertex)

    # Add faces
    if not _metadata.indices.is_empty():
        for i in range(0, _metadata.indices.size(), 3):
            _st.add_index(_metadata.indices[i])
            _st.add_index(_metadata.indices[i + 1])
            _st.add_index(_metadata.indices[i + 2])

    _st.generate_normals()
    _final_mesh.mesh = _st.commit()

    if not streaming:
        # Update collision shape and bounding box with centered bounds
        var scaled_bounds = AABB(-(_metadata.bounds.size * _metadata.scale_factor) / 2, 
                               _metadata.bounds.size * _metadata.scale_factor)
        scaled_bounds = scaled_bounds.grow(_metadata.final_mesh_bounding_box_padding)
        _update_collision_shape(scaled_bounds)
        if _metadata.final_mesh_bounding_box_enabled and _bounding_box_final_mesh:
            _update_bounding_box(_bounding_box_final_mesh, scaled_bounds)

func _update_bounding_box(bounding_box: MeshInstance3D, bounds: AABB) -> void:
    var box_mesh = BoxMesh.new()
    box_mesh.size = bounds.size
    bounding_box.mesh = box_mesh
    bounding_box.position = bounds.position + bounds.size * 0.5

func _update_collision_shape(bounds: AABB) -> void:
    var box_shape = BoxShape3D.new()
    box_shape.size = bounds.size
    _collision_shape.shape = box_shape
    _collision_shape.position = bounds.position + bounds.size * 0.5

func update_metadata(new_metadata: MeshMetadata) -> void:
    _metadata = new_metadata
    
# In mesh_visualizer.gd, update _on_generation_complete():
func _on_generation_complete(success: bool) -> void:
    if success:
        print("Mesh generation complete - Creating final mesh")
        _metadata.generation_time_ms = (Time.get_unix_time_from_system() - _metadata.generation_timestamp) * 1000
        _update_mesh(false)  # false for final mesh
        
        if Globals.DEBUG:
            print("metadata:")
            print(_metadata.to_json_string())

        # Only remove vertex spheres and their bounding box if retain settings are false
        if not _metadata.retain_vertex_spheres:
            for sphere in _vertex_spheres:
                sphere.queue_free()
            _vertex_spheres.clear()

        # Hide vertex spheres bounding box if retention is disabled
        if _bounding_box_vertex_spheres and not _metadata.retain_vertex_spheres_bounding_box:
            _bounding_box_vertex_spheres.visible = false
                
        # Hide final mesh bounding box if retention is disabled
        if _bounding_box_final_mesh and not _metadata.retain_final_mesh_bounding_box:
            _bounding_box_final_mesh.visible = false
    else:
        push_error("Mesh generation failed")
