extends Node3D

var visualizations: Dictionary = {}

func _ready() -> void:
    initialize_visualizations()

func initialize_visualizations() -> void:
    create_visualization("sphere", SphereVisualization)
    create_visualization("matrix", MatrixWindow)
    create_visualization("domain", DomainWindow)

    create_visualization("left", LeftWindow)
    create_visualization("right", RightWindow)
    #create_visualization("top", TopWindow)

    create_visualization_from_scene("bar_chart", "res://scenes/bar_chart/bar_chart.tscn")

func create_visualization(label: String, visualization_class) -> void:
    var visualization = visualization_class.new()

    if visualization is Node3D:
        visualization.hide()
        visualization.set_process(false)
        add_child(visualization)
        visualizations[label] = visualization
    else:
        print("Error: Visualization '%s' is not a valid Node3D" % label)

func create_visualization_from_scene(label: String, scene_path: String) -> void:
    print("Loading scene:", scene_path)
    var scene = load(scene_path)
    if scene:
        var instance = scene.instantiate()
        if instance is Node3D:
            instance.hide()
            instance.set_process(false)
            add_child(instance)
            visualizations[label] = instance
            print("Successfully loaded scene:", label)
        else:
            print("Error: Scene '%s' does not instantiate a valid Node3D" % label)
    else:
        print("Error: Failed to load scene '%s'" % scene_path)

func show_visualization(label: String) -> void:
    if visualizations.has(label):
        _animate_visualization(label, visualizations[label], true)
    else:
        print("No visualization with name '%s'" % label)

func hide_visualization(label: String, remove: bool = false) -> void:
    if visualizations.has(label):
        _animate_visualization(label, visualizations[label], false, remove)
    else:
        print("No visualization with name '%s'" % label)

func _animate_visualization(label: String, node: Node3D, is_visible: bool, remove: bool = false) -> void:
    var tween = get_tree().create_tween()

    if is_visible:
        node.show()
        node.set_process(true)
        tween.tween_property(node, "scale", Vector3(1, 1, 1), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tween.tween_property(node, "modulate", Color(1, 1, 1, 1), 0.5)
    else:
        tween.tween_property(node, "scale", Vector3(0.1, 0.1, 0.1), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        tween.tween_property(node, "modulate", Color(1, 1, 1, 0), 0.5)

        # After hiding, remove if needed
        tween.tween_callback(func():
            node.hide()
            node.set_process(false)
            if remove:
                # Remove from the scene tree
                node.queue_free()
                visualizations.erase(label)
        )
    print("Animating", node.name, "to", "show" if is_visible else "hide")
