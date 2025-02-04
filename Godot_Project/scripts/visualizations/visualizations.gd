extends Node3D

# Dictionary to hold our current visualization instances.
var windows: Dictionary = {}

func _ready() -> void:
    # For example, add a LeftWindow but keep it hidden until needed.
    var left_window = LeftWindow.new()
    #left_window.hide()  # not visible initially
    add_child(left_window)
    windows["left"] = left_window

    var top_window = TopWindow.new()
    add_child(top_window)
    windows["top"] = top_window
        
    # Optionally, disable processing for hidden nodes:
    #left_window.set_process(false)

# Call this to turn a visualization on:
func show_window(window_name: String) -> void:
    if windows.has(window_name):
        var win = windows[window_name]
        win.show()
        win.set_process(true)
    else:
        print("No window with name '%s'" % window_name)

# And call this to turn it off completely:
func hide_window(window_name: String) -> void:
    if windows.has(window_name):
        var win = windows[window_name]
        win.hide()
        win.set_process(false)
        # Optionally, remove it from the scene tree:
        # win.queue_free()
        # windows.erase(window_name)
    else:
        print("No window with name '%s'" % window_name)
