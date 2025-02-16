extends Node3D

@onready var mesh_visualizer: MeshVisualizer

const DEFAULT_PROMPT = "Create a 3D model of a sword"
var is_generating := false
var generation_succeeded := false

func _ready() -> void:
    if not mesh_visualizer:
        mesh_visualizer = MeshVisualizer.new()
        add_child(mesh_visualizer)
    
    # Set up initial transform
    mesh_visualizer.position = Vector3.ZERO
    # TODO: Disabled to handle in code, revisit after rending complete
    # scale = Vector3.ONE * 0.1  # Scale down for reasonable size in XR
#    scale = Vector3.ONE

func generate() -> void:
    if is_generating:
        return
        
    is_generating = true
    generation_succeeded = false
    mesh_visualizer.generate(DEFAULT_PROMPT)
    await mesh_visualizer._mesh_generator.generation_complete
    generation_succeeded = not is_generating  # Only set success if we weren't interrupted
    is_generating = false

func _process(delta: float) -> void:
    # Only rotate when generation is complete and successful
    if mesh_visualizer and not is_generating and generation_succeeded:
        mesh_visualizer.rotate_y(delta * 0.5)
