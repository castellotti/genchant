extends Node2D

func _ready():
    # Get references to the TextEdit nodes
    var render_host_edit = $Container/Line1/TextEdit
    var temperature_edit = $Container/Line2/TextEdit
    var prompt_edit = $Container/Line3/TextEdit
    
    # Set their text values from Globals
    render_host_edit.text = Globals.RENDER_HOST
    temperature_edit.text = str(Globals.TEMPERATURE)  # Convert float to string
    prompt_edit.text = Globals.PROMPT

func _on_ClearButton_pressed():
    Globals.mesh_scene.generate()
