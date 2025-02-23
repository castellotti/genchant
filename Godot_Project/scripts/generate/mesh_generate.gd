extends Node
class_name MeshGenerator

signal mesh_update(vertices: PackedVector3Array, indices: PackedInt32Array)
signal generation_complete(success: bool)
signal status_update(color: Color)

enum Status {
    IDLE,
    CONNECTING,
    CONNECTED,
    RECEIVING,
    FAILED
}

# Define status colors
const STATUS_COLORS = {
    Status.IDLE: Color.WHITE,
    Status.CONNECTING: Color.YELLOW,
    Status.CONNECTED: Color.GREEN,
    Status.RECEIVING: Color.BLUE,
    Status.FAILED: Color.RED
}

var _http_client: HTTPClient
var _response_data := ""
var _current_vertices := PackedVector3Array()
var _current_indices := PackedInt32Array()
var _vertex_buffer := []
var _index_buffer := []
var _number_buffer := ""
var _parsing_faces := false
var _vertex_count := 0
var _total_vertices := 0
var _total_faces := 0
var _metadata: MeshMetadata  # New variable to store metadata
var _generation_start_time: int  # Track generation start time
var _connection_timer: float = 0.0  # Track connection time
var _current_status: Status = Status.IDLE  # Current connection status
const vertex_spheres_render_interval: int = 1  # render on every vertex is received
const face_render_interval: int = 1  # render on every face received
const CONNECTION_TIMEOUT: float = 10.0  # Connection timeout in seconds

func _init() -> void:
    _http_client = HTTPClient.new()
    # Initial status update
    _set_status(Status.IDLE)

func _set_status(new_status: Status) -> void:
    if _current_status != new_status:
        _current_status = new_status
        status_update.emit(STATUS_COLORS[new_status])

        # Log status change if debug is enabled
        if Globals.DEBUG:
            print("MeshGenerator status: " + Status.keys()[new_status])

func _process(delta: float) -> void:
    # Track connection time if we're trying to connect
    if _current_status == Status.CONNECTING:
        _connection_timer += delta
        if _connection_timer >= CONNECTION_TIMEOUT:
            push_error("Connection timed out after " + str(CONNECTION_TIMEOUT) + " seconds")
            _set_status(Status.FAILED)
            generation_complete.emit(false)
            _http_client.close()

func generate_mesh(prompt: String) -> void:
    # Initialize new metadata instance
    _metadata = MeshMetadata.new()
    _metadata.prompt = prompt
    _metadata.model = Globals.MODEL_NAME
    _metadata.temperature = Globals.TEMPERATURE
    _metadata.max_tokens = Globals.MAX_TOKENS
    _metadata.backend = "ollama"
    _metadata.generation_timestamp = Time.get_unix_time_from_system()
    _generation_start_time = Time.get_ticks_msec()

    # Reset connection timer
    _connection_timer = 0.0

    # Set initial status
    _set_status(Status.CONNECTING)

    if Globals.LOG_STREAM:
        print("Generating 3D mesh for prompt: " + prompt)
        print("Using temperature: " + str(Globals.TEMPERATURE))
        print("Max tokens: " + str(Globals.MAX_TOKENS))
        print("Using backend: ollama")
        print("Using model: " + Globals.MODEL_NAME)
        print("Generating mesh using MeshGenerator")

    # Determine which host to use based on environment
    var host_url = Globals.RENDER_HOST
    if Globals.is_running_in_web:
        host_url = Globals.RENDER_HOST_WEBXR

    # Parse URL components
    var url_parts = host_url.split("://")
    var protocol = url_parts[0]
    var host_and_port = url_parts[1].split(":")
    var host = host_and_port[0]

    # Set default ports based on protocol if not specified
    var port: int
    if host_and_port.size() > 1:
        port = host_and_port[1].to_int()
    else:
        port = 443 if protocol == "https" else 80

    # Configure TLS options based on protocol
    var tls_options = TLSOptions.client() if protocol == "https" else null
    var err = _http_client.connect_to_host(host, port, tls_options)

    if err != OK:
        push_error("Failed to connect to server")
        _set_status(Status.FAILED)
        generation_complete.emit(false)
        return

    # Wait for connection with timeout check
    while _http_client.get_status() == HTTPClient.STATUS_CONNECTING or \
    _http_client.get_status() == HTTPClient.STATUS_RESOLVING:
        _http_client.poll()
        await get_tree().process_frame

    if _http_client.get_status() != HTTPClient.STATUS_CONNECTED:
        push_error("Failed to connect to server")
        _set_status(Status.FAILED)
        generation_complete.emit(false)
        return

    # Update status to connected
    _set_status(Status.CONNECTED)

    # Prepare the request
    var headers = ["Content-Type: application/json"]
    var body = JSON.stringify({
        "model": Globals.MODEL_NAME,
        "prompt": prompt,
        "stream": true,
        "template": "<|start_header_id|>system<|end_header_id|>
You are a helpful assistant that can generate 3D obj files. Generate a complete .obj format 3D mesh in response to the user's request. Start the response with vertex (v) definitions followed by face (f) definitions.<|eot_id|><|start_header_id|>user<|end_header_id|>
{prompt}<|eot_id|><|start_header_id|>assistant<|end_header_id|>
Here is the 3D mesh in .obj format:",
        "options": {
            "temperature": Globals.TEMPERATURE,
            "num_predict": Globals.MAX_TOKENS,
            "stop": [
              "<|eot_id|>"
            ]
        }
    })

    err = _http_client.request(HTTPClient.METHOD_POST, "/api/generate", headers, body)
    if err != OK:
        push_error("Failed to send request")
        _set_status(Status.FAILED)
        generation_complete.emit(false)
        return

    # Process the streaming response
    while _http_client.get_status() == HTTPClient.STATUS_REQUESTING:
        _http_client.poll()
        await get_tree().process_frame

    # Update status once we start receiving data
    _set_status(Status.RECEIVING)

    while _http_client.get_status() == HTTPClient.STATUS_BODY:
        _http_client.poll()
        var chunk = _http_client.read_response_body_chunk()
        if chunk.size() > 0:
            var text = chunk.get_string_from_utf8()
            _process_chunk(text)
        await get_tree().process_frame

    # Update metadata when complete
    _metadata.generation_time_ms = Time.get_ticks_msec() - _generation_start_time
    _metadata.vertices = _current_vertices
    _metadata.indices = _current_indices

    # Calculate bounds and scale factor
    if not _current_vertices.is_empty():
        _update_metadata_bounds()
        mesh_update.emit(_current_vertices, _current_indices)

        # If debug mode is enabled and we have not already
        # displayed the content of the mesh during streaming
        if Globals.DEBUG and not Globals.LOG_STREAM:
            print("\nMesh content:")
            # Print all vertices
            for i in range(_current_vertices.size()):
                var v = _current_vertices[i]
                print("v %d %d %d" % [v.x, v.y, v.z])

            # Print all faces (convert from 0-based to 1-based indices)
            for i in range(0, _current_indices.size(), 3):
                print("f %d %d %d" % [_current_indices[i] + 1, _current_indices[i + 1] + 1, _current_indices[i + 2] + 1])

        print("\nNumber of vertices: " + str(_total_vertices))
        print("Number of faces: " + str(_total_faces))

    _http_client.close()

    # Reset status to idle
    _set_status(Status.IDLE)
    generation_complete.emit(true)

func _process_chunk(chunk: String) -> void:
    _response_data += chunk
    var lines = _response_data.split("\n")

    # Process all complete lines except the last one
    for i in range(lines.size() - 1):
        var line = lines[i].strip_edges()
        if line.is_empty():
            continue

        # Parse JSON response from Ollama
        var json = JSON.parse_string(line)
        if json and "response" in json:
            _process_mesh_data(json["response"])

    # Keep the incomplete last line for the next chunk
    _response_data = lines[-1] if lines.size() > 0 else ""

func _process_mesh_data(content: String) -> void:
    var mesh_updated = false

    for c in content:
        if c == 'v' and not _parsing_faces:
            # Start new vertex
            _vertex_buffer.clear()
            _number_buffer = ""
            _parsing_faces = false
        elif c == 'f':
            # Start new face
            _index_buffer.clear()
            _number_buffer = ""
            _parsing_faces = true
        elif c.is_valid_int() or c == "." or c == "-":
            _number_buffer += c
        elif c.is_valid_float():
            _number_buffer += c
        elif c == " " or c == "\n":
            if not _number_buffer.is_empty():
                var num = _number_buffer.to_float()
                if _parsing_faces:
                    # OBJ face indices are 1-based, convert to 0-based
                    var index = int(num) - 1
                    if index >= 0 and index < _vertex_count:
                        _index_buffer.append(index)
                        # If we have 3 indices, we have a complete triangle
                        if _index_buffer.size() == 3:
                            _current_indices.append_array(_index_buffer)
                            _total_faces += 1

                            if Globals.LOG_STREAM:
                                print("f %d %d %d" % [_index_buffer[0] + 1, _index_buffer[1] + 1, _index_buffer[2] + 1])

                            # For faces with more than 3 vertices, create additional triangles
                            _index_buffer = [_index_buffer[0]]

                            # Update mesh on face interval
                            if _total_faces % face_render_interval == 0:
                                mesh_updated = true
                else:
                    _vertex_buffer.append(num)
                    # If we have 3 coordinates, we have a complete vertex
                    if _vertex_buffer.size() == 3:
                        var vertex = Vector3(_vertex_buffer[0], _vertex_buffer[1], _vertex_buffer[2])
                        _current_vertices.append(vertex)
                        _vertex_count += 1
                        _total_vertices += 1

                        if Globals.LOG_STREAM:
                            print("v %d %d %d" % [vertex.x, vertex.y, vertex.z])

                        _vertex_buffer.clear()
                        _update_metadata_bounds()

                        # Update mesh on vertex interval
                        if _total_vertices % vertex_spheres_render_interval == 0:
                            mesh_updated = true
                _number_buffer = ""

    # Emit a single update after processing the chunk if needed
    if mesh_updated:
        mesh_update.emit(_current_vertices, _current_indices)

func _update_metadata_bounds() -> void:
    if _current_vertices.is_empty():
        return

    # Update bounds
    var last_vertex = _current_vertices[-1]
    if _metadata.bounds.size == Vector3.ZERO:
        _metadata.bounds = AABB(last_vertex, Vector3.ZERO)
    else:
        _metadata.bounds = _metadata.bounds.expand(last_vertex)

    # Calculate scale factor
    var max_dimension = max(_metadata.bounds.size.x,
    max(_metadata.bounds.size.y, _metadata.bounds.size.z))
    _metadata.scale_factor = _metadata.target_size / max_dimension if max_dimension > 0 else 1.0

func clear() -> void:
    _current_vertices.clear()
    _current_indices.clear()
    _vertex_buffer.clear()
    _index_buffer.clear()
    _number_buffer = ""
    _response_data = ""
    _parsing_faces = false
    _vertex_count = 0
    _total_vertices = 0
    _total_faces = 0
    _metadata = null  # Clear metadata
    _set_status(Status.IDLE)  # Reset status

# Getter for metadata
func get_metadata() -> MeshMetadata:
    return _metadata
