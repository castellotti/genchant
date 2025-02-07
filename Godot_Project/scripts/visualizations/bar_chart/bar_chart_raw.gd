extends BarChartVisualization
class_name BarChartRawVisualization

var update_timer: Timer

const REFRESH_INTERVAL = 2.0
const CONFIG = {
    # Provides raw network traffic data with timestamps
    "api_path": "/api/v1/raw?relative=10s",
    "color": [1, 0, 0],   # Red
    "transform": [0, 0, 0],
    "label": false
}

func _ready() -> void:
    initialize(CONFIG)
    
    # Create a timer for periodic updates
    update_timer = Timer.new()
    update_timer.wait_time = REFRESH_INTERVAL
    update_timer.autostart = true
    update_timer.one_shot = false
    update_timer.connect("timeout", Callable(self, "_on_timer_timeout"))
    add_child(update_timer)

func _on_timer_timeout() -> void:
    print("Refreshing data for BarChartRawVisualization")
    styx_api.send_request()

func cleanup() -> void:
    if update_timer:
        update_timer.stop()
        update_timer.queue_free()
    super.cleanup()  # Call parent cleanup logic
