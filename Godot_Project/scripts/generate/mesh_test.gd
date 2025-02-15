extends Node3D

const FORWARD_OFFSET = 2.0  # Meters in front of player
const SIDE_OFFSET = 2.0    # Meters to left/right

@export var stream_scale: float = 0.05
@export var final_scale: float = 0.1
@export var glb_scale: float = 0.1

var _stream_mesh_visualizer: MeshVisualizer
var _final_mesh_visualizer: MeshVisualizer
var _glb_visualizer: Node3D  # Parent node for GLB and its bounding box

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
    # Calculate base positions
    var left_pos = Vector3(-SIDE_OFFSET - 2.0, 0, FORWARD_OFFSET)
    var center_pos = Vector3(0, 0, FORWARD_OFFSET)
    var right_pos = Vector3(SIDE_OFFSET, 0, FORWARD_OFFSET)
    
    # Set up visualizers
    _setup_visualizers(left_pos, center_pos, right_pos)
    
    # Load test data based on environment variables or defaults
    var gdscript_log = ""
    var verbose_log = ""
    var glb_file = ""
    
    if OS.has_environment("TEST_LOG_FILE"):
        verbose_log = OS.get_environment("TEST_LOG_FILE")
    elif "TEST_LOG_FILE" in Globals:
        verbose_log = Globals.TEST_LOG_FILE
        
    if OS.has_environment("TEST_DEBUG_FILE"):
        gdscript_log = OS.get_environment("TEST_DEBUG_FILE")
    elif "TEST_DEBUG_FILE" in Globals:
        gdscript_log = Globals.TEST_DEBUG_FILE

    if OS.has_environment("TEST_GLB_FILE"):
        glb_file = OS.get_environment("TEST_GLB_FILE")
    elif "TEST_GLB_FILE" in Globals:
        glb_file = Globals.TEST_GLB_FILE
    
    # Load the appropriate test data
    if gdscript_log:
        _load_test_data(gdscript_log, true, left_pos, stream_scale)
    if verbose_log:
        _load_test_data(verbose_log, false, center_pos, final_scale)
    if glb_file:
        _load_glb_file(glb_file, right_pos, glb_scale)

func _setup_visualizers(left_pos: Vector3, center_pos: Vector3, right_pos: Vector3) -> void:
    # Set up stream mesh visualizer (left position)
    _stream_mesh_visualizer = MeshVisualizer.new()
    add_child(_stream_mesh_visualizer)
    _stream_mesh_visualizer.position = left_pos
    _stream_mesh_visualizer.scale = Vector3.ONE * stream_scale
    
    # Set up final mesh visualizer (center position)
    _final_mesh_visualizer = MeshVisualizer.new()
    add_child(_final_mesh_visualizer)
    _final_mesh_visualizer.position = center_pos
    _final_mesh_visualizer.scale = Vector3.ONE * final_scale
    
    # Set up GLB visualizer container
    _glb_visualizer = Node3D.new()
    add_child(_glb_visualizer)
    _glb_visualizer.position = right_pos
    _glb_visualizer.scale = Vector3.ONE * glb_scale

func _load_test_data(log_file: String, is_stream: bool, new_position: Vector3, new_scale: float) -> void:
    var content = _read_file_content(log_file)
    if content.is_empty():
        return
        
    var target_visualizer = _stream_mesh_visualizer if is_stream else _final_mesh_visualizer
    target_visualizer.position = new_position
    target_visualizer.scale = Vector3.ONE * new_scale
    
    if is_stream:
        _process_stream_data(content, target_visualizer)
    else:
        _process_final_data(content, target_visualizer)

func _process_stream_data(content: String, target_visualizer: MeshVisualizer) -> void:
    var json_lines = content.split("\n")
    var stream_vertices := PackedVector3Array()
    var stream_indices := PackedInt32Array()
    var vertex_count := 0
    var current_vertex := Vector3()
    var vertex_components := 0
    var number_buffer := ""
    var parsing_faces := false
    var face_indices := []
    
    for line in json_lines:
        if line.is_empty():
            continue
            
        var json = JSON.parse_string(line)
        if json and "response" in json:
            var response = json["response"]
            
            for c in response:
                if c == 'v' and not parsing_faces:
                    vertex_components = 0
                    number_buffer = ""
                    parsing_faces = false
                elif c == 'f':
                    face_indices.clear()
                    number_buffer = ""
                    parsing_faces = true
                elif c.is_valid_int() or c == "." or c == "-":
                    number_buffer += c
                elif c.is_valid_float():
                    number_buffer += c
                elif c == " " or c == "\n":
                    if not number_buffer.is_empty():
                        var num = number_buffer.to_float()
                        if parsing_faces:
                            var index = int(num) - 1
                            if index >= 0 and index < vertex_count:
                                face_indices.append(index)
                                if face_indices.size() == 3:
                                    stream_indices.append_array(face_indices)
                                    face_indices = [face_indices[0]]
                        else:
                            vertex_components += 1
                            match vertex_components:
                                1: current_vertex.x = num
                                2: current_vertex.y = num
                                3:
                                    current_vertex.z = num
                                    stream_vertices.append(current_vertex)
                                    vertex_count += 1
                        number_buffer = ""
    
    if not stream_vertices.is_empty():
        target_visualizer._on_mesh_update(stream_vertices, stream_indices)
        target_visualizer._on_generation_complete(true)

func _process_final_data(content: String, target_visualizer: MeshVisualizer) -> void:
    var final_start = content.find("Mesh content:")
    if final_start != -1:
        var final_data = content.substr(final_start)
        var vertex_array = PackedVector3Array()
        var index_array = PackedInt32Array()
        
        for line in final_data.split("\n"):
            if line.begins_with("v "):
                var parts = line.split(" ", false)
                if parts.size() >= 4:
                    vertex_array.append(Vector3(
                        float(parts[1]),
                        float(parts[2]),
                        float(parts[3])
                    ))
            elif line.begins_with("f "):
                var parts = line.split(" ", false)
                if parts.size() >= 4:
                    index_array.append(int(parts[1]) - 1)
                    index_array.append(int(parts[2]) - 1)
                    index_array.append(int(parts[3]) - 1)
        
        if not vertex_array.is_empty():
            target_visualizer._on_mesh_update(vertex_array, index_array)
            target_visualizer._on_generation_complete(true)

func _load_glb_file(glb_file: String, new_position: Vector3, new_scale: float) -> void:
    var scene: Node3D
    
    if glb_file.begins_with("res://"):
        # Load from resources
        var packed_scene = load(glb_file) as PackedScene
        if packed_scene:
            scene = packed_scene.instantiate()
    else:
        # Load from filesystem
        if not FileAccess.file_exists(glb_file):
            push_error("GLB file not found: " + glb_file)
            return
        
        var gltf_state = GLTFState.new()
        var gltf_doc = GLTFDocument.new()
        var err = gltf_doc.append_from_file(glb_file, gltf_state)
        if err != OK:
            push_error("Failed to load GLB file: " + glb_file)
            return
        
        scene = gltf_doc.generate_scene(gltf_state)
    
    if scene:
        _glb_visualizer.add_child(scene)
        _glb_visualizer.position = new_position
        _glb_visualizer.scale = Vector3.ONE * new_scale
        
        # Find the first MeshInstance3D and create a bounding box
        for child in scene.get_children():
            if child is MeshInstance3D:
                var aabb = child.get_aabb()
                var box = _create_bounding_box(aabb)
                scene.add_child(box)
                
                # Adjust height to 0.5m above floor
                var target_height = 0.5
                var height_offset = target_height - (aabb.position.y * scale)
                _glb_visualizer.position.y = height_offset
                break

func _create_bounding_box(bounds: AABB) -> MeshInstance3D:
    var box = MeshInstance3D.new()
    var box_mesh = BoxMesh.new()
    box_mesh.size = bounds.size
    box.mesh = box_mesh
    
    var box_material = StandardMaterial3D.new()
    box_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    box_material.albedo_color = Color(1, 1, 1, 0.25)
    box.material_override = box_material
    
    box.position = bounds.position + bounds.size * 0.5
    return box
