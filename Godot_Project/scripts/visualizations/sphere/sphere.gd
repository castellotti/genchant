extends Node3D
class_name SphereVisualization

var shader_material = ShaderMaterial.new()
var standard_material = StandardMaterial3D.new()
var sphere: CSGSphere3D
var current_color: Color = Color.WHITE  # Default to idle/white

func _ready() -> void:
    sphere = CSGSphere3D.new()
    sphere.radius = 0.5  # Slightly smaller than the original
    sphere.radial_segments = 32
    sphere.rings = 24

    # Position using Globals configuration
    if Globals.visualizations.has("sphere") and Globals.visualizations["sphere"].has("position"):
        self.transform.origin = Globals.visualizations["sphere"]["position"]
    else:
        # Fallback position if not defined in Globals
        self.transform.origin = Vector3(0, 1.0, 0.0)

    if Globals.enable_visualizations:
        # Use standard material for VisionOS
        standard_material.albedo_color = current_color
        sphere.material = standard_material
    
    if Globals.enable_shaders:
        # Use shader material for other platforms
        shader_material.shader = load("res://shaders/common/rgb.gdshader")
        shader_material.set_shader_parameter("speed", 0.5)
        shader_material.set_shader_parameter("linger", 4.0)
        sphere.material = shader_material

    add_child(sphere)

# Original method, now can be called by on_status_update or directly with a color
func update_status_color(new_color: Color) -> void:
    print("update_status_color received color: ", new_color)
    # Store current color
    current_color = new_color

    if not Globals.enable_shaders:
        standard_material.albedo_color = new_color

# Add a pulsing effect for better visibility
func _process(delta: float) -> void:
    # Add subtle pulsing based on the current status
    if current_color.is_equal_approx(Color.YELLOW):
        # Fast pulse for connecting
        _pulse(delta, 5.0, 0.2)
    elif current_color.is_equal_approx(Color.BLUE):
        # Medium pulse for receiving
        _pulse(delta, 2.0, 0.1)
    elif current_color.is_equal_approx(Color.RED):
        # Strong pulse for failure
        _pulse(delta, 1.0, 0.4)

var _pulse_time: float = 0.0
func _pulse(delta: float, frequency: float, intensity: float) -> void:
    _pulse_time += delta * frequency

    # Calculate pulse factor (0.0 to 1.0)
    var pulse_factor = (sin(_pulse_time) + 1.0) / 2.0

    # Scale the sphere slightly based on pulse
    var base_scale = 1.0
    var scale_change = intensity * pulse_factor
    sphere.scale = Vector3.ONE * (base_scale + scale_change)
