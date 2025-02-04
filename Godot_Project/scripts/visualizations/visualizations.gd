extends Node3D

# Dictionary to hold our current visualization instances.
var windows: Dictionary = {}

func _ready() -> void:
    initialize_visualizations()

func initialize_visualizations() -> void:
    var left_window = LeftWindow.new()
    left_window.hide()
    left_window.set_process(false)
    add_child(left_window)
    windows["left"] = left_window
   
    var right_window = RightWindow.new()
    right_window.hide()
    right_window.set_process(false)
    add_child(right_window)
    windows["right"] = right_window
    
    var top_window = TopWindow.new()
    top_window.hide()
    top_window.set_process(false)
    add_child(top_window)
    windows["top"] = top_window    

# Turn on visualization
func show_window(window_name: String) -> void:
    if windows.has(window_name):
        var win = windows[window_name]
        win.show()
        win.set_process(true)
    else:
        print("No window with name '%s'" % window_name)

# Turn off visualization
func hide_window(window_name: String) -> void:
    if windows.has(window_name):
        var win = windows[window_name]
        win.hide()
        win.set_process(false)
        # Optionally, remove from the scene tree
        # win.queue_free()
        # windows.erase(window_name)
    else:
        print("No window with name '%s'" % window_name)
