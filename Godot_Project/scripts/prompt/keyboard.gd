extends Node2D

var render_host_edit
var temperature_edit
var prompt_edit

func _ready():
    # Get references to the TextEdit nodes
    render_host_edit = $Container/Line1/TextEdit
    temperature_edit = $Container/Line2/TextEdit
    prompt_edit = $Container/Line3/TextEdit
    
    # Set their text values from Globals
    render_host_edit.text = Globals.RENDER_HOST
    temperature_edit.text = str(Globals.TEMPERATURE)  # Convert float to string
    prompt_edit.text = Globals.PROMPT
    
    # Connect text submission handlers for each TextEdit
    render_host_edit.gui_input.connect(_on_text_edit_gui_input)
    temperature_edit.gui_input.connect(_on_text_edit_gui_input)
    prompt_edit.gui_input.connect(_on_text_edit_gui_input)

func _on_text_edit_gui_input(event):
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
            event.set_pressed(false)  # Prevent the line return
            _on_generate_button_pressed()

func _on_generate_button_pressed():
    Globals.RENDER_HOST = render_host_edit.text
    var temp_value = temperature_edit.text.strip_edges()
    if temp_value.is_valid_float():
        Globals.TEMPERATURE = float(temp_value)
    Globals.PROMPT = prompt_edit.text
    Globals.mesh_scene.generate()
