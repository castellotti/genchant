extends Node3D

@onready var mesh_visualizer: MeshVisualizer
var sphere_visualization: SphereVisualization

var is_generating := false
var generation_succeeded := false

# Status signals
signal generation_started
signal generation_completed(success: bool)

func _ready() -> void:
    # Create and add mesh visualizer if not present
    if not mesh_visualizer:
        mesh_visualizer = MeshVisualizer.new()
        add_child(mesh_visualizer)

    # Find the sphere visualization from the scene
    # Wait a frame to ensure visualizations manager has created it
    await get_tree().process_frame
    var visualizations_scene = get_node_or_null("/root/main/visualizations")
    if visualizations_scene and visualizations_scene.visualizations.has("sphere"):
        sphere_visualization = visualizations_scene.visualizations["sphere"]

        # Connect mesh generator signals to the sphere visualization
        mesh_visualizer._mesh_generator.status_update.connect(sphere_visualization.update_status_color)

    # Set up initial transform for the mesh visualizer
    mesh_visualizer.position = Vector3.ZERO
    scale = Vector3.ONE

func generate() -> void:
    if is_generating:
        return

    is_generating = true
    generation_succeeded = false

    # Emit signal that generation has started
    generation_started.emit()

    # Start the mesh generation process
    mesh_visualizer.generate(Globals.PROMPT)

    # Wait for completion
    await mesh_visualizer._mesh_generator.generation_complete

    # Update state flags
    generation_succeeded = not is_generating  # Only set success if we weren't interrupted
    is_generating = false

    # Emit completion signal
    generation_completed.emit(generation_succeeded)

func _process(delta: float) -> void:
    # Only rotate when generation is complete and successful
    if mesh_visualizer and not is_generating and generation_succeeded:
        mesh_visualizer.rotate_y(delta * 0.5)

# Method to cancel an ongoing generation (if needed)
func cancel_generation() -> void:
    if is_generating:
        is_generating = false
        generation_succeeded = false
        generation_completed.emit(false)
