# BarChartVisualization.gd
extends Node3D
class_name BarChartVisualization

var styx_api: StyxApi
var columns_node: Node3D

func initialize(endpoint: String) -> void:
    # Create and initialize the API
    styx_api = StyxApi.new()
    styx_api.init(endpoint)
    
    # Listen for data; when received, our _on_data_received() will be called.
    if not styx_api.is_connected("data_received", Callable(self, "_on_data_received")):
        styx_api.connect("data_received", Callable(self, "_on_data_received"))
        
    add_child(styx_api)
    
    # Create a container for our columns.
    columns_node = Node3D.new()
    columns_node.name = "ColumnsNode"
    add_child(columns_node)
    
    # Send the first request
    styx_api.send_request()

func _on_data_received(_endpoint: String, parsed_data: Array) -> void:
    # Process the parsed data (this method can be overridden)
    var processed_data: Dictionary = process_data(parsed_data)
    update_columns(processed_data)

func process_data(parsed_data: Array) -> Dictionary:
    # Default processing: sum the “sent” and “received” values per address (or “remote” if missing)
    var traffic_dict: Dictionary = {}
    for entry in parsed_data:
        var address: String = entry.get("address", "")
        if address == "" and entry.has("remote"):
            address = entry["remote"]
        var total_traffic: int = int(entry.get("sent", 0)) + int(entry.get("received", 0))
        traffic_dict[address] = total_traffic
    
    # Sort addresses by descending traffic and select the top 10.
    var sorted_keys = traffic_dict.keys()
    sorted_keys.sort_custom(func(a, b):
        return traffic_dict[a] > traffic_dict[b]  # Correct way for descending order
    )
    var top_traffic: Dictionary = {}
    for i in range(min(10, sorted_keys.size())):
        var key = sorted_keys[i]
        top_traffic[key] = traffic_dict[key]
    return top_traffic

func update_columns(traffic_data: Dictionary) -> void:
    # Remove any existing columns by freeing the container
    if columns_node:
        columns_node.queue_free()
    # Create a new container for columns
    columns_node = Node3D.new()
    columns_node.name = "ColumnsNode"
    add_child(columns_node)
    
    if traffic_data.size() == 0:
        print("No traffic data to visualize.")
        return
    
    # Retrieve endpoint-specific settings (color, transform, label) from the API’s endpoints dictionary.
    var endpoint_data: Dictionary = get_endpoint_data()
    var max_traffic: int = 0
    for traffic in traffic_data.values():
        if traffic > max_traffic:
            max_traffic = traffic
    
    var index: int = 0
    for address in traffic_data.keys():
        var total_traffic = traffic_data[address]
        var height_ratio: float = float(total_traffic) / float(max_traffic)
        
        # Load and instance the column (using your column.gd script)
        var column_scene = load("res://scripts/common/column.gd")
        if column_scene == null:
            print("Error: Could not load column.gd")
            return
        var column = column_scene.new(endpoint_data["color"], address, endpoint_data["label"])
        
        # Set the column’s size (its y‑scale is determined by the data)
        column.scale = Vector3(1, height_ratio * 5.0, 1)
        # Position the column; here we space them along the x‑axis and adjust the y‑position so they “grow” from the base.
        column.transform.origin = Vector3(index * 0.2, (height_ratio * 2.5), 6)
        # Apply any additional translation from the endpoint settings.
        column.translate(Vector3(endpoint_data["transform"][0], endpoint_data["transform"][1], endpoint_data["transform"][2]))
        columns_node.add_child(column)
        index += 1

func get_endpoint_data() -> Dictionary:
    # Return the configuration for the current endpoint from the API.
    return styx_api.endpoints.get(styx_api.current_endpoint, {})

func cleanup() -> void:
    # Called when the visualization is hidden or removed.
    if columns_node:
        columns_node.queue_free()
