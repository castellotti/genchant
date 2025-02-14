extends BarChartVisualization
class_name BarChartRemoteVisualization

const CONFIG = {
    # Retrieves traffic summary grouped by remote IP or domain name, along with the port
    "endpoint": "/api/v1/remote?relative=1h",
    "color": [0, 0, 1],  # Blue
    "transform": [0, 0, -1],
    "label": false
}

func _init() -> void:
    initialize(CONFIG)
