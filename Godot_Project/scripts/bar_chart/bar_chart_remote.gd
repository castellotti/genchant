# StyxRemoteVisualization.gd
extends Node3D
class_name BarChartRemoteVisualization

var styx_api
var columns_node: Node3D

func _ready() -> void:
    # Initialize the API
    styx_api = StyxApi.new()
    styx_api.init("remote")
    add_child(styx_api)
    
    # Create columns node
    columns_node = Node3D.new()
    columns_node.name = "ColumnsNode"
    add_child(columns_node)
    
    # Initial request
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
