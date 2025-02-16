extends Node3D

var _visualizers: Dictionary = {}

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
    _setup_visualizers()
    _load_models()

func _setup_visualizers() -> void:
    # Create visualizers for each model
    for file_path in Globals.example_models:
        var visualizer
        if file_path.to_lower().ends_with(".glb"):
            visualizer = Node3D.new()
        else:
            visualizer = MeshVisualizer.new()
            
        add_child(visualizer)
        visualizer.position += Globals.example_models[file_path]["position"]
        _visualizers[file_path] = visualizer

func _load_models() -> void:
    # Process each model in the example_models dictionary
    for file_path in Globals.example_models:
        if file_path.to_lower().ends_with(".glb"):
            _load_glb_model(file_path)
        else:
            _load_json_model(file_path)

func _load_json_model(file_path: String) -> void:
    if not FileAccess.file_exists(file_path):
        push_error("File not found: " + file_path)
        return
        
    var metadata = MeshMetadata.load_from_file(file_path)
    if metadata == null:
        push_error("Failed to load metadata from JSON file: " + file_path)
        return
        
    var visualizer = _visualizers[file_path] as MeshVisualizer
    if visualizer:
        _process_mesh_data(metadata, visualizer)

func _load_glb_model(file_path: String) -> void:
    if not FileAccess.file_exists(file_path):
        push_error("GLB file not found: " + file_path)
        return

    var scene = _load_glb_scene(file_path)
    if scene:
        var visualizer = _visualizers[file_path]
        visualizer.add_child(scene)

func _load_glb_scene(glb_file: String) -> Node3D:
    if glb_file.begins_with("res://"):
        var packed_scene = load(glb_file) as PackedScene
        return packed_scene.instantiate() if packed_scene else null

    var gltf_state = GLTFState.new()
    var gltf_doc = GLTFDocument.new()
    var err = gltf_doc.append_from_file(glb_file, gltf_state)
    return gltf_doc.generate_scene(gltf_state) if err == OK else null

func _process_mesh_data(metadata: MeshMetadata, visualizer: MeshVisualizer) -> void:
    if metadata.vertices.is_empty():
        return

    # Update the visualizer's metadata first
    visualizer.update_metadata(metadata)
    
    # Send complete mesh at once
    visualizer._on_mesh_update(metadata.vertices, metadata.indices)
    visualizer._on_generation_complete(true)
