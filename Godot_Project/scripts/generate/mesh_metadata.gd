class_name MeshMetadata
extends RefCounted

# Visualization settings
var sphere_radius: float = 0.8  # 80cm radius for vertex spheres
var target_size: float = 1.0  # Target size in meters for the bounding cube
var initial_height: float = 0  # Initial height off the floor in meters
var retain_vertex_spheres: bool = false  # Whether to keep vertex spheres after generation
var retain_vertex_spheres_bounding_box: bool = false  # Whether to keep vertex spheres bounding box after generation
var retain_final_mesh_bounding_box: bool = false  # Whether to keep final mesh bounding box after generation
var assign_grab_points: bool = true  # Whether to add grab points to the mesh

# Position offsets - Adjusted to be closer to player's origin at (0, 0, 9)
var vertex_spheres_offset: Vector3 = Vector3(-target_size/2, target_size/2, 10.5 - target_size/2)
var final_mesh_offset: Vector3 = Vector3(0, 0, 10.5)

# Bounding box settings
var vertex_spheres_bounding_box_enabled: bool = true
var final_mesh_bounding_box_enabled: bool = true
var vertex_spheres_bounding_box_alpha: float = 0.05
var final_mesh_bounding_box_alpha: float = 0.2
# Padding will be adjusted by scale factor in the visualizer
var vertex_spheres_bounding_box_padding: float = 0.1 + sphere_radius * 2  # Diameter of sphere
var final_mesh_bounding_box_padding: float = 0.1

# Generation metadata
var model: String = ""
var prompt: String = ""
var temperature: float = Globals.TEMPERATURE
var max_tokens: int = Globals.MAX_TOKENS
var backend: String = ""
var generation_time_ms: float = 0  # Time taken to generate the mesh
var generation_timestamp: float = 0  # Unix timestamp when generation started

# Mesh data
var vertices: PackedVector3Array
var indices: PackedInt32Array
var bounds: AABB
var scale_factor: float = 1.0

func _init() -> void:
    vertices = PackedVector3Array()
    indices = PackedInt32Array()
    bounds = AABB()

# Serialization methods
func to_dict() -> Dictionary:
    return {
        "visualization_settings": {
            "sphere_radius": sphere_radius,
            "target_size": target_size,
            "initial_height": initial_height,
            "vertex_spheres_offset": {
                "x": vertex_spheres_offset.x,
                "y": vertex_spheres_offset.y,
                "z": vertex_spheres_offset.z
            },
            "final_mesh_offset": {
                "x": final_mesh_offset.x,
                "y": final_mesh_offset.y,
                "z": final_mesh_offset.z
            },
            "retain_vertex_spheres": retain_vertex_spheres,
            "retain_vertex_spheres_bounding_box": retain_vertex_spheres_bounding_box,
            "retain_final_mesh_bounding_box": retain_final_mesh_bounding_box,
            "assign_grab_points": assign_grab_points,
        },
        "bounding_box_settings": {
            "vertex_spheres_enabled": vertex_spheres_bounding_box_enabled,
            "final_mesh_enabled": final_mesh_bounding_box_enabled,
            "vertex_spheres_alpha": vertex_spheres_bounding_box_alpha,
            "final_mesh_alpha": final_mesh_bounding_box_alpha,
            "vertex_spheres_padding": vertex_spheres_bounding_box_padding,
            "final_mesh_padding": final_mesh_bounding_box_padding
        },
        "generation_info": {
            "model": model,
            "prompt": prompt,
            "temperature": temperature,
            "max_tokens": max_tokens,
            "backend": backend,
            "generation_time_ms": generation_time_ms,
            "generation_timestamp": generation_timestamp
        },
        "mesh_data": {
            "vertices": _pack_vector3_array(vertices),
            "indices": Array(indices),
            "bounds": {
                "position": {
                    "x": bounds.position.x,
                    "y": bounds.position.y,
                    "z": bounds.position.z
                },
                "size": {
                    "x": bounds.size.x,
                    "y": bounds.size.y,
                    "z": bounds.size.z
                }
            },
            "scale_factor": scale_factor
        }
    }

# New function to generate JSON string
func to_json_string() -> String:
    return JSON.stringify(to_dict())

# Updated save method to use the new JSON string function
func save_to_file(path: String) -> Error:
    var file = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return FileAccess.get_open_error()
    
    file.store_string(to_json_string())
    return OK

static func from_dict(data: Dictionary) -> MeshMetadata:
    var metadata = MeshMetadata.new()
    
    # Visualization settings
    var viz = data.get("visualization_settings", {})
    metadata.sphere_radius = viz.get("sphere_radius", 0.8)
    metadata.target_size = viz.get("target_size", 1.0)
    metadata.initial_height = viz.get("initial_height", 0.5)
    metadata.retain_vertex_spheres = viz.get("retain_vertex_spheres", false)
    metadata.retain_vertex_spheres_bounding_box = viz.get("retain_vertex_spheres_bounding_box", true)
    metadata.retain_final_mesh_bounding_box = viz.get("retain_final_mesh_bounding_box", false)
    metadata.assign_grab_points = viz.get("assign_grab_points", true)
    
    var spheres_offset = viz.get("vertex_spheres_offset", {})
    metadata.vertex_spheres_offset = Vector3(
        spheres_offset.get("x", 0),
        spheres_offset.get("y", 1),
        spheres_offset.get("z", 0)
    )
    
    var mesh_offset = viz.get("final_mesh_offset", {})
    metadata.final_mesh_offset = Vector3(
        mesh_offset.get("x", 0),
        mesh_offset.get("y", 0),
        mesh_offset.get("z", 0)
    )
    
    # Bounding box settings
    var bb = data.get("bounding_box_settings", {})
    metadata.final_mesh_bounding_box_enabled = bb.get("final_mesh_enabled", true)
    metadata.final_mesh_bounding_box_alpha = bb.get("final_mesh_alpha", 0.2)
    metadata.final_mesh_bounding_box_padding = bb.get("final_mesh_padding", 0.0)
    metadata.vertex_spheres_bounding_box_enabled = bb.get("vertex_spheres_enabled", true)
    metadata.vertex_spheres_bounding_box_alpha = bb.get("vertex_spheres_alpha", 0.05)
    metadata.vertex_spheres_bounding_box_padding = bb.get("vertex_spheres_padding", 0.8)
    
    # Generation info
    var gen = data.get("generation_info", {})
    metadata.model = gen.get("model", "")
    metadata.prompt = gen.get("prompt", "")
    metadata.temperature = gen.get("temperature", 0.0)
    metadata.max_tokens = gen.get("max_tokens", 0)
    metadata.backend = gen.get("backend", "")
    metadata.generation_time_ms = gen.get("generation_time_ms", 0)
    metadata.generation_timestamp = gen.get("generation_timestamp", 0)
    
    # Mesh data
    var mesh = data.get("mesh_data", {})
    metadata.vertices = _unpack_vector3_array(mesh.get("vertices", []))
    metadata.indices = PackedInt32Array(mesh.get("indices", []))
    
    var bounds_data = mesh.get("bounds", {})
    var bounds_pos = bounds_data.get("position", {})
    var bounds_size = bounds_data.get("size", {})
    metadata.bounds = AABB(
        Vector3(
            bounds_pos.get("x", 0),
            bounds_pos.get("y", 0),
            bounds_pos.get("z", 0)
        ),
        Vector3(
            bounds_size.get("x", 0),
            bounds_size.get("y", 0),
            bounds_size.get("z", 0)
        )
    )
    
    metadata.scale_factor = mesh.get("scale_factor", 1.0)
    
    return metadata

# Helper methods for serializing Vector3 arrays
static func _pack_vector3_array(arr: PackedVector3Array) -> Array:
    var result = []
    for v in arr:
        result.append({"x": v.x, "y": v.y, "z": v.z})
    return result

static func _unpack_vector3_array(arr: Array) -> PackedVector3Array:
    var result = PackedVector3Array()
    for v in arr:
        result.append(Vector3(v.get("x", 0), v.get("y", 0), v.get("z", 0)))
    return result

# Load metadata from a file
static func load_from_file(path: String) -> MeshMetadata:
    if not FileAccess.file_exists(path):
        return null
        
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return null
        
    var json_string = file.get_as_text()
    var json = JSON.parse_string(json_string)
    if json == null:
        return null
        
    return from_dict(json)

# Parse metadata from log file content
static func parse_from_log(content: String) -> MeshMetadata:
    var metadata = MeshMetadata.new()
    
    # Parse generation info
    var lines = content.split("\n")
    for line in lines:
        line = line.strip_edges()
        
        if line.begins_with("Using temperature:"):
            metadata.temperature = line.split(": ")[1].to_float()
        elif line.begins_with("Max tokens:"):
            metadata.max_tokens = line.split(": ")[1].to_int()
        elif line.begins_with("Using backend:"):
            metadata.backend = line.split(": ")[1]
        elif line.begins_with("Using model:"):
            metadata.model = line.split(": ")[1]
        elif line.begins_with("Generating 3D mesh for prompt:"):
            metadata.prompt = line.split(": ")[1]
    
    # Parse mesh data
    var mesh_content = content.substr(content.find("Mesh content:"))
    for line in mesh_content.split("\n"):
        line = line.strip_edges()
        if line.is_empty() or line == "Mesh content:":
            continue

        if line.begins_with("v "):
            var parts = line.split(" ", false)
            if parts.size() >= 4:
                var vertex = Vector3(
                    float(parts[1]),
                    float(parts[2]),
                    float(parts[3])
                )
                metadata.vertices.append(vertex)
                # Update bounds
                if metadata.bounds.size == Vector3.ZERO:
                    metadata.bounds = AABB(vertex, Vector3.ZERO)
                else:
                    metadata.bounds = metadata.bounds.expand(vertex)

        elif line.begins_with("f "):
            var parts = line.split(" ", false)
            if parts.size() >= 4:
                metadata.indices.append(int(parts[1]) - 1)
                metadata.indices.append(int(parts[2]) - 1)
                metadata.indices.append(int(parts[3]) - 1)

        elif line.begins_with("Number of"):
            break
    
    # Calculate scale factor
    if not metadata.bounds.size == Vector3.ZERO:
        var max_dimension = max(metadata.bounds.size.x, 
                              max(metadata.bounds.size.y, metadata.bounds.size.z))
        metadata.scale_factor = metadata.target_size / max_dimension if max_dimension > 0 else 1.0
    
    return metadata
