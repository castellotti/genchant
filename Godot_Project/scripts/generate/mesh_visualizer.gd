extends MeshInstance3D
class_name MeshVisualizer

var _mesh_generator: MeshGenerator
var _st := SurfaceTool.new()
var _material: StandardMaterial3D
var _current_vertices := PackedVector3Array()
var _current_indices := PackedInt32Array()
var _bounding_box: MeshInstance3D

func _ready() -> void:
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
    box_material.albedo_color = Color(1, 1, 1, 0.25)  # 75% transparent white
    _bounding_box.material_override = box_material

    _mesh_generator = MeshGenerator.new()
    add_child(_mesh_generator)

    _mesh_generator.mesh_update.connect(_on_mesh_update)
    _mesh_generator.generation_complete.connect(_on_generation_complete)

func generate(prompt: String) -> void:
    _current_vertices.clear()
    _current_indices.clear()
    mesh = null  # Clear existing mesh
    _bounding_box.mesh = null  # Clear bounding box
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

    # Calculate bounds for color gradient and bounding box
    var bounds = AABB()
    if not _current_vertices.is_empty():
        bounds = AABB(_current_vertices[0], Vector3.ZERO)
        for vertex in _current_vertices:
            bounds = bounds.expand(vertex)

    # Add vertices with colors
    for vertex in _current_vertices:
        var y_normalized: float = 0.0
        if bounds.size.y > 0:
            y_normalized = (vertex.y - bounds.position.y) / bounds.size.y

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

    # Create and update bounding box
    _update_bounding_box(bounds)

    # Adjust position to place bottom at 0.5m
    var target_height = 0.5  # 0.5 meters above floor
    var height_offset = target_height - bounds.position.y
    position.y = height_offset

func _update_bounding_box(bounds: AABB) -> void:
    var box_mesh = BoxMesh.new()
    box_mesh.size = bounds.size
    _bounding_box.mesh = box_mesh
    _bounding_box.position = bounds.position + bounds.size * 0.5

func _on_generation_complete(success: bool) -> void:
    if success:
        print("Mesh generation complete")
        _update_mesh()  # Ensure final mesh is updated
    else:
        push_error("Mesh generation failed")
