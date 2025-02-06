extends Node3D

var visualizations: Dictionary = {}
var animation_duration = 0.5

# Mapping of scene labels to their paths
var visualization_scenes = {
    "bar_chart": "res://scenes/bar_chart/bar_chart.tscn"
}

# Mapping of script-based visualizations
var visualization_classes = {
    "sphere": SphereVisualization,
    "matrix": MatrixWindow,
    "domain": DomainWindow,
    "left": LeftWindow,
    "right": RightWindow,
    "top": TopWindow
}

func show_visualization(label: String) -> void:
    # If visualization doesn't exist, create and show it
    if not visualizations.has(label):
        if visualization_classes.has(label):
            print("Creating script-based visualization: ", label)
            create_visualization_from_script(label, visualization_classes[label])
        elif visualization_scenes.has(label):
            print("Loading scene-based visualization: ", label)
            create_visualization_from_scene(label, visualization_scenes[label])
        else:
            print("No visualization with name '%s'" % label)
            return

    # Show and enable processing
    var visualization = visualizations[label]
    _enable_processing(visualization)
    _animate_visualization(visualization, true)

func hide_visualization(label: String, remove: bool = false) -> void:
    if visualizations.has(label):
        var vis = visualizations[label]
        _animate_visualization(vis, false)

        if remove:
            # Use a timer to delay the removal
            var timer = Timer.new()
            timer.one_shot = true
            timer.wait_time = animation_duration + 0.1  # Slightly longer than the animation duration
            timer.connect("timeout", func():
                vis.queue_free()
                visualizations.erase(label)
            )
            add_child(timer)
            timer.start()
    else:
        print("No visualization with name '%s'" % label)

func create_visualization_from_script(label: String, visualization_class) -> void:
    var instance = visualization_class.new()
    if instance is Node3D:
        # Hide until animation is called
        instance.hide()
        _disable_processing(instance)
        add_child(instance)
        visualizations[label] = instance
    else:
        print("Error: Visualization '%s' is not a valid Node3D" % label)

func create_visualization_from_scene(label: String, scene_path: String) -> void:
    print("Instantiating scene: ", scene_path)
    var scene = load(scene_path)
    if scene:
        var instance = scene.instantiate()
        if instance is Node3D:
            # Hide until animation is called
            instance.hide()
            _disable_processing(instance)
            add_child(instance)
            visualizations[label] = instance
        else:
            print("Error: Scene '%s' does not instantiate a valid Node3D" % scene_path)
    else:
        print("Error: Failed to load scene '%s'" % scene_path)

func _disable_processing(node: Node) -> void:
    node.set_process(false)
    node.set_physics_process(false)
    node.set_process_input(false)
    if node is Timer:
        node.stop()  # Stop any active timers
    for child in node.get_children():
        _disable_processing(child)

func _enable_processing(node: Node) -> void:
    node.set_process(true)
    node.set_physics_process(true)
    node.set_process_input(true)
    if node is Timer:
        node.start()  # Restart timers when enabled
    for child in node.get_children():
        _enable_processing(child)

func _animate_visualization(node: Node3D, set_visibile: bool) -> void:
    var tween = get_tree().create_tween()

    # Find all MeshInstance3D nodes in the hierarchy
    var mesh_instances = _find_all_mesh_instances(node)

    if set_visibile:
        node.show()
        node.set_process(true)
        tween.tween_property(node, "scale", Vector3(1, 1, 1), animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

        for mesh in mesh_instances:
            _animate_material_alpha(tween, mesh, 1.0)
    else:
        tween.tween_property(node, "scale", Vector3(0.1, 0.1, 0.1), animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

        for mesh in mesh_instances:
            _animate_material_alpha(tween, mesh, 0.0)

    # After animation, fully disable processing and hide
    tween.tween_callback(func():
        if not set_visibile:
            print("Hiding visualization node: ", node.name)
            node.hide()
        _set_node_and_children_processing(node, set_visibile)
    )

# Animate material transparency by modifying the albedo color's alpha channel
func _animate_material_alpha(tween: Tween, mesh_instance: MeshInstance3D, target_alpha: float) -> void:
    var material = mesh_instance.get_surface_override_material(0)
    if material == null:
        material = StandardMaterial3D.new()
        mesh_instance.set_surface_override_material(0, material)

    var current_color = material.albedo_color
    var target_color = Color(current_color.r, current_color.g, current_color.b, target_alpha)
    
    tween.tween_property(material, "albedo_color", target_color, animation_duration)

# Find all MeshInstance3D nodes recursively
func _find_all_mesh_instances(root: Node) -> Array[MeshInstance3D]:
    var mesh_instances: Array[MeshInstance3D] = []
    if root is MeshInstance3D:
        mesh_instances.append(root)
    for child in root.get_children():
        mesh_instances += _find_all_mesh_instances(child)
    return mesh_instances

# New helper function to recursively set processing for a node and its children
func _set_node_and_children_processing(node: Node, enable: bool) -> void:
    node.set_process(enable)
    node.set_physics_process(enable)
    node.set_process_input(enable)
    if node is Timer:
        if enable:
            node.start()
        else:
            node.stop()
    for child in node.get_children():
        _set_node_and_children_processing(child, enable)

func toggle_visualization(label: String) -> void:
    if visualizations.has(label) and visualizations[label].visible:
        print("Toggling off: ", label)
        hide_visualization(label)
    else:
        print("Toggling on: ", label)
        show_visualization(label)
