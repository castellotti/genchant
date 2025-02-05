extends Node3D

# Dictionary to hold our current visualization instances.
var visualizations: Dictionary = {}

func _ready() -> void:
    initialize_visualizations()

func initialize_visualizations() -> void:
    create_visualization("left", LeftWindow)
    create_visualization("right", RightWindow)
    create_visualization("top", TopWindow)
    create_visualization("matrix", MatrixWindow)
    create_visualization("domain", DomainWindow)
    create_visualization("sphere", SphereVisualization)  # Load sphere dynamically

func create_visualization(label: String, visualization_class) -> void:
    var visualization = visualization_class.new()
    
    if visualization is Node3D:
        visualization.hide()
        visualization.set_process(false)
        add_child(visualization)
        visualizations[label] = visualization
    else:
        print("Error: Visualization '%s' is not a valid Node3D" % label)

# Turn on visualization
func show_visualization(label: String) -> void:
    if visualizations.has(label):
        var vis = visualizations[label]
        vis.show()
        vis.set_process(true)
    else:
        print("No visualization with name '%s'" % label)

# Turn off visualization
func hide_visualization(label: String) -> void:
    if visualizations.has(label):
        var vis = visualizations[label]
        vis.hide()
        vis.set_process(false)
        # Optionally, remove from the scene tree
        # vis.queue_free()
        # visualizations.erase(label)
    else:
        print("No visualization with name '%s'" % label)
