extends Node3D

var _stream_mesh_visualizer: MeshVisualizer
var _final_mesh_visualizer: MeshVisualizer
var _glb_visualizer: Node3D

func _read_file_content(file_path: String) -> String:
    if not FileAccess.file_exists(file_path):
        push_error("File not found: " + file_path)
        return ""
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        push_error("Failed to open file: " + file_path)
        return ""
    return file.get_as_text()

func _ready() -> void:
    # Set up base positions for the three test objects
    var left_pos = Vector3(-1.5, 1.0, -2.0)
    var center_pos = Vector3(0, 1.0, -2.0)
    var right_pos = Vector3(1.5, 1.0, -2.0)

    # Initialize visualizers with basic positioning
    _setup_visualizers(left_pos, center_pos, right_pos)

    # Load test files from environment variables
    var test_files = _get_test_files()
    _run_tests(test_files)

func _setup_visualizers(left_pos: Vector3, center_pos: Vector3, right_pos: Vector3) -> void:
    # Create stream mesh visualizer
    _stream_mesh_visualizer = MeshVisualizer.new()
    add_child(_stream_mesh_visualizer)
    # Apply offset relative to its default position
    _stream_mesh_visualizer.position += left_pos
    
    # Create final mesh visualizer
    _final_mesh_visualizer = MeshVisualizer.new()
    add_child(_final_mesh_visualizer)
    # Apply offset relative to its default position
    _final_mesh_visualizer.position += right_pos
    
    # Create GLB visualizer
    _glb_visualizer = Node3D.new()
    add_child(_glb_visualizer)
    # Apply offset relative to its default position
    _glb_visualizer.position += center_pos

func _get_test_files() -> Dictionary:
    return {
        "gdscript_log": OS.get_environment("TEST_LOG_FILE") if OS.has_environment("TEST_LOG_FILE") else Globals.get("TEST_LOG_FILE") if "TEST_LOG_FILE" in Globals else "",
        "verbose_log": OS.get_environment("TEST_DEBUG_FILE") if OS.has_environment("TEST_DEBUG_FILE") else Globals.get("TEST_DEBUG_FILE") if "TEST_DEBUG_FILE" in Globals else "",
        "glb_file": OS.get_environment("TEST_GLB_FILE") if OS.has_environment("TEST_GLB_FILE") else Globals.get("TEST_GLB_FILE") if "TEST_GLB_FILE" in Globals else ""
    }

func _run_tests(test_files: Dictionary) -> void:
    if test_files.gdscript_log:
        _test_stream_mesh(test_files.gdscript_log)
    if test_files.verbose_log:
        _test_final_mesh(test_files.verbose_log)
    if test_files.glb_file:
        _test_glb_mesh(test_files.glb_file)

func _test_stream_mesh(file_path: String) -> void:
    if not FileAccess.file_exists(file_path):
        push_error("File not found: " + file_path)
        return
        
    var metadata: MeshMetadata
    if file_path.to_lower().ends_with(".json"):
        metadata = MeshMetadata.load_from_file(file_path)
        if metadata == null:
            push_error("Failed to load metadata from JSON file: " + file_path)
            return
    else:
        # Assume it's a log file
        var content = _read_file_content(file_path)
        if content.is_empty():
            return
        metadata = MeshMetadata.parse_from_log(content)
        
    _process_mesh_data(metadata, _stream_mesh_visualizer, true)

func _test_final_mesh(file_path: String) -> void:
    if not FileAccess.file_exists(file_path):
        push_error("File not found: " + file_path)
        return
        
    var metadata: MeshMetadata
    if file_path.to_lower().ends_with(".json"):
        metadata = MeshMetadata.load_from_file(file_path)
        if metadata == null:
            push_error("Failed to load metadata from JSON file: " + file_path)
            return
    else:
        # Assume it's a log file
        var content = _read_file_content(file_path)
        if content.is_empty():
            return
        metadata = MeshMetadata.parse_from_log(content)
        
    _process_mesh_data(metadata, _final_mesh_visualizer, false)

func _test_glb_mesh(glb_file: String) -> void:
    if not FileAccess.file_exists(glb_file):
        push_error("GLB file not found: " + glb_file)
        return

    var scene = _load_glb_scene(glb_file)
    if scene:
        _glb_visualizer.add_child(scene)

func _load_glb_scene(glb_file: String) -> Node3D:
    if glb_file.begins_with("res://"):
        var packed_scene = load(glb_file) as PackedScene
        return packed_scene.instantiate() if packed_scene else null

    var gltf_state = GLTFState.new()
    var gltf_doc = GLTFDocument.new()
    var err = gltf_doc.append_from_file(glb_file, gltf_state)
    return gltf_doc.generate_scene(gltf_state) if err == OK else null

func _process_mesh_data(metadata: MeshMetadata, target_visualizer: MeshVisualizer, is_stream: bool) -> void:
    if metadata.vertices.is_empty():
        return
        
    if is_stream:
        # Simulate streaming updates
        var stream_vertices = PackedVector3Array()
        var stream_indices = PackedInt32Array()
        
        for i in range(metadata.vertices.size()):
            stream_vertices.append(metadata.vertices[i])
            if i % Globals.vertex_spheres_render_interval == 0:  # Update per vertices
                target_visualizer._on_mesh_update(stream_vertices, stream_indices)
                
        for i in range(0, metadata.indices.size(), 3):
            stream_indices.append(metadata.indices[i])
            stream_indices.append(metadata.indices[i + 1])
            stream_indices.append(metadata.indices[i + 2])
            if i % 3 * Globals.vertex_spheres_render_interval == 0:  # Update per faces (3 indices per vertex)
                target_visualizer._on_mesh_update(stream_vertices, stream_indices)
    else:
        # Send complete mesh at once
        target_visualizer._on_mesh_update(metadata.vertices, metadata.indices)
        
    target_visualizer._on_generation_complete(true)
