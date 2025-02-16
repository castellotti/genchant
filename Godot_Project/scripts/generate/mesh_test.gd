extends Node3D

const FORWARD_OFFSET = 1.0  # Meters in front of player
const SIDE_OFFSET = 1.0  # Meters to left/right

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
    var left_pos = Vector3(-SIDE_OFFSET - 2.0, 0, FORWARD_OFFSET)
    var center_pos = Vector3(0, 0, FORWARD_OFFSET)
    var right_pos = Vector3(SIDE_OFFSET, 0, FORWARD_OFFSET)

    # Initialize visualizers with basic positioning
    _setup_visualizers(left_pos, center_pos, right_pos)

    # Load test files from environment variables
    var test_files = _get_test_files()
    _run_tests(test_files)

func _setup_visualizers(left_pos: Vector3, center_pos: Vector3, right_pos: Vector3) -> void:
    _stream_mesh_visualizer = MeshVisualizer.new()
    add_child(_stream_mesh_visualizer)
    _stream_mesh_visualizer.position = left_pos

    _final_mesh_visualizer = MeshVisualizer.new()
    add_child(_final_mesh_visualizer)
    _final_mesh_visualizer.position = right_pos

    _glb_visualizer = Node3D.new()
    add_child(_glb_visualizer)
    _glb_visualizer.position = center_pos

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

func _test_stream_mesh(log_file: String) -> void:
    var content = _read_file_content(log_file)
    if content.is_empty():
        return
    _process_mesh_data(content, _stream_mesh_visualizer, true)

func _test_final_mesh(log_file: String) -> void:
    var content = _read_file_content(log_file)
    if content.is_empty():
        return
    _process_mesh_data(content, _final_mesh_visualizer, false)

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

func _process_mesh_data(content: String, target_visualizer: MeshVisualizer, is_stream: bool) -> void:
    var vertex_array = PackedVector3Array()
    var index_array = PackedInt32Array()
    var mesh_content = content.substr(content.find("Mesh content:"))
    
    for line in mesh_content.split("\n"):
        line = line.strip_edges()
        if line.is_empty() or line == "Mesh content:":
            continue

        if line.begins_with("v "):
            var parts = line.split(" ", false)
            if parts.size() >= 4:
                vertex_array.append(Vector3(
                    float(parts[1]),
                    float(parts[2]),
                    float(parts[3])
                ))
                if is_stream and vertex_array.size() % 10 == 0:
                    target_visualizer._on_mesh_update(vertex_array, index_array)

        elif line.begins_with("f "):
            var parts = line.split(" ", false)
            if parts.size() >= 4:
                index_array.append(int(parts[1]) - 1)
                index_array.append(int(parts[2]) - 1)
                index_array.append(int(parts[3]) - 1)
                if is_stream and index_array.size() % 30 == 0:
                    target_visualizer._on_mesh_update(vertex_array, index_array)

        elif line.begins_with("Number of"):
            break

    if not vertex_array.is_empty():
        target_visualizer._on_mesh_update(vertex_array, index_array)
        target_visualizer._on_generation_complete(true)
