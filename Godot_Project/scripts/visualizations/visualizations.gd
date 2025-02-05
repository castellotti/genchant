extends Node3D

# Dictionary to hold our current visualization instances.
var windows: Dictionary = {}

func _ready() -> void:
    initialize_visualizations()

func initialize_visualizations() -> void:
    create_window("left", LeftWindow)
    create_window("right", RightWindow)
    create_window("top", TopWindow)
    create_window("matrix", MatrixWindow)
    create_window("domain", DomainWindow)

func create_window(window_name: String, window_class) -> void:
    var window = window_class.new()
    window.hide()
    window.set_process(false)
    add_child(window)
    windows[window_name] = window

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
