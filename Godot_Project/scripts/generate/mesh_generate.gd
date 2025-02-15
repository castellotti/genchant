extends Node
class_name MeshGenerator

signal mesh_update(vertices: PackedVector3Array, indices: PackedInt32Array)
signal generation_complete(success: bool)

var _http_client: HTTPClient
var _response_data := ""
var _current_vertices := PackedVector3Array()
var _current_indices := PackedInt32Array()
var _vertex_buffer := []
var _index_buffer := []
var _number_buffer := ""
var _parsing_faces := false
var _vertex_count := 0

func _init() -> void:
    _http_client = HTTPClient.new()

func generate_mesh(prompt: String) -> void:
    var host = Globals.OLLAMA_HOST.split("://")[1]
    var port = host.split(":")[1].to_int()
    host = host.split(":")[0]
    var err = _http_client.connect_to_host(host, port)
    if err != OK:
        push_error("Failed to connect to Ollama server")
        generation_complete.emit(false)
        return
    
    # Wait for connection
    while _http_client.get_status() == HTTPClient.STATUS_CONNECTING or \
          _http_client.get_status() == HTTPClient.STATUS_RESOLVING:
        _http_client.poll()
        await get_tree().process_frame
    
    if _http_client.get_status() != HTTPClient.STATUS_CONNECTED:
        push_error("Failed to connect to server")
        generation_complete.emit(false)
        return
    
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
        generation_complete.emit(false)
        return
    
    # Process the streaming response
    while _http_client.get_status() == HTTPClient.STATUS_REQUESTING:
        _http_client.poll()
        await get_tree().process_frame
    
    while _http_client.get_status() == HTTPClient.STATUS_BODY:
        _http_client.poll()
        var chunk = _http_client.read_response_body_chunk()
        if chunk.size() > 0:
            var text = chunk.get_string_from_utf8()
            _process_chunk(text)
        await get_tree().process_frame
    
    # Final mesh update with all vertices and indices
    if not _current_vertices.is_empty():
        mesh_update.emit(_current_vertices, _current_indices)
    
    _http_client.close()
    generation_complete.emit(true)

func _process_chunk(chunk: String) -> void:
    _response_data += chunk
    var lines = _response_data.split("\n")
    
    # Process all complete lines except the last one
    for i in range(lines.size() - 1):
        var line = lines[i].strip_edges()
        if line.is_empty():
            continue
        elif Globals.DEBUG:
            print(line)
        
        # Parse JSON response from Ollama
        var json = JSON.parse_string(line)
        if json and "response" in json:
            _process_mesh_data(json["response"])
    
    # Keep the incomplete last line for the next chunk
    _response_data = lines[-1] if lines.size() > 0 else ""

func _process_mesh_data(content: String) -> void:
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
                            # For faces with more than 3 vertices, create additional triangles
                            _index_buffer = [_index_buffer[0]]
                else:
                    _vertex_buffer.append(num)
                    # If we have 3 coordinates, we have a complete vertex
                    if _vertex_buffer.size() == 3:
                        var vertex = Vector3(_vertex_buffer[0], _vertex_buffer[1], _vertex_buffer[2])
                        _current_vertices.append(vertex)
                        _vertex_count += 1
                        _vertex_buffer.clear()
                        
                        # Update mesh every few vertices for visual feedback
                        if _current_vertices.size() % 10 == 0:
                            mesh_update.emit(_current_vertices, _current_indices)
                _number_buffer = ""

func clear() -> void:
    _current_vertices.clear()
    _current_indices.clear()
    _vertex_buffer.clear()
    _index_buffer.clear()
    _number_buffer = ""
    _response_data = ""
    _parsing_faces = false
    _vertex_count = 0
