extends MeshInstance3D
class_name MeshVisualizer

var _mesh_generator: MeshGenerator
var _st := SurfaceTool.new()
var _material: StandardMaterial3D
var _current_vertices := PackedVector3Array()
var _current_indices := PackedInt32Array()

func _ready() -> void:
    _material = StandardMaterial3D.new()
    _material.vertex_color_use_as_albedo = true
    _material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
    material_override = _material
    
    _mesh_generator = MeshGenerator.new()
    add_child(_mesh_generator)
    
    _mesh_generator.mesh_update.connect(_on_mesh_update)
    _mesh_generator.generation_complete.connect(_on_generation_complete)

func generate(prompt: String) -> void:
    _current_vertices.clear()
    _current_indices.clear()
    mesh = null  # Clear existing mesh
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
    
    # Calculate Y-axis bounds for color gradient
    var y_min := _current_vertices[0].y
    var y_max := _current_vertices[0].y
    for vertex in _current_vertices:
        y_min = min(y_min, vertex.y)
        y_max = max(y_max, vertex.y)
    
    # Add vertices with colors
    for vertex in _current_vertices:
        var y_normalized: float = 0.0
        if y_max > y_min:
            y_normalized = (vertex.y - y_min) / (y_max - y_min)
        
        # Create gradient color (red to blue like in Python script)
        var color := Color(y_normalized, 0.0, 1.0 - y_normalized, 1.0)
        
        _st.set_color(color)
        _st.add_vertex(vertex)
    
    # Add faces if we have indices
    if not _current_indices.is_empty():
        for i in range(0, _current_indices.size(), 3):
            _st.add_index(_current_indices[i])
            _st.add_index(_current_indices[i + 1])
            _st.add_index(_current_indices[i + 2])
    else:
        # If no indices provided, create triangles from sequential vertices
        for i in range(0, _current_vertices.size(), 3):
            if i + 2 < _current_vertices.size():
                _st.add_index(i)
                _st.add_index(i + 1)
                _st.add_index(i + 2)
    
    # Generate normals and assign mesh
    _st.generate_normals()
    mesh = _st.commit()

func _on_generation_complete(success: bool) -> void:
    if success:
        print("Mesh generation complete")
        _update_mesh()  # Ensure final mesh is updated
        
        # Center the mesh at origin
        if mesh:
            var aabb := mesh.get_aabb()
            position = -aabb.position - aabb.size * 0.5
    else:
        push_error("Mesh generation failed")
