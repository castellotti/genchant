# StyxRawVisualization.gd
extends Node3D
class_name BarChartRawVisualization

var styx_api
var columns_node: Node3D
var timer: Timer

func _ready() -> void:
    # Initialize the API
    styx_api = StyxApi.new()
    styx_api.init("raw")
    add_child(styx_api)
    
    # Create columns node
    columns_node = Node3D.new()
    columns_node.name = "ColumnsNode"
    add_child(columns_node)
    
    # Set up timer for periodic updates
    timer = Timer.new()
    timer.wait_time = 2.0
    timer.one_shot = false
    add_child(timer)
    timer.connect("timeout", _on_timer_timeout)
    
    # Initial request
    styx_api.send_request()
    timer.start()

func _on_timer_timeout() -> void:
    print("Timer timeout reached, sending request.")
    styx_api.send_request()

# Clean up when visualization is hidden
func cleanup() -> void:
    if columns_node:
        for child in columns_node.get_children():
            child.queue_free()

func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        # Cleanup before the node is deleted
        cleanup()
    elif what == NOTIFICATION_WM_CLOSE_REQUEST:
        # Handle window close
        cleanup()

func _exit_tree() -> void:
    # Final cleanup when node is removed from scene
    cleanup()
