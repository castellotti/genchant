extends VisualizationWindow
class_name MatrixDomainWindow

var resolution = Vector2(1024, 1024)
var render_speed: float = 0.36
var total_columns : int = resolution.x / 8.0  # const float LX = 8.0; // letter space x
var total_rows : int = resolution.y / 10.0  # const float LY = 10.0; // letter space y
var max_rain_speed : float = 5.0  # Max possible speed is 10.0
var min_rain_speed : float = 1.0  # Min possible speed is 0.1

var domain_counts = {}

var character_table: Dictionary = {
    "0": 0.0,
    "1": 1.0,
    "2": 2.0,
    "3": 3.0,
    "4": 4.0,
    "5": 5.0,
    "6": 6.0,
    "7": 7.0,
    "8": 8.0,
    "9": 9.0,
    "A": 10.0,
    "B": 11.0,
    "C": 12.0,
    "D": 13.0,
    "E": 14.0,
    "F": 15.0,
    "G": 16.0,
    "H": 17.0,
    "I": 18.0,
    "J": 19.0,
    "K": 20.0,
    "L": 21.0,
    "M": 22.0,
    "N": 23.0,
    "O": 24.0,
    "P": 25.0,
    "Q": 26.0,
    "R": 27.0,
    "S": 28.0,
    "T": 29.0,
    "U": 30.0,
    "V": 31.0,
    "W": 32.0,
    "X": 33.0,
    "Y": 34.0,
    "Z": 35.0,
    ".": 36.0,
    "-": 37.0,
    ":": 38.0,
    " ": 39.0
}

func _ready() -> void:
    window_position = Vector3(0, 1.5, 6.5)
    window_size = Vector2(5, 5)
    shader_path = "res://shaders/matrix/matrix_domain.gdshader"

    domain_counts = get_domains()

    create_domain_windows()

func get_domains() -> Dictionary:
    return {
        "graph.facebook.com:443": 100,
        "google.com:443": 20,
        "cf-proxy-cf-eu12-9dasdf3fb142345b.elb.eu-central-1.amazonaws.com:443": 1,
    }    

func create_domain_windows() -> void:
    
    var domain_speeds = calculate_frequencies(domain_counts)
    print("Domain speeds: ", domain_speeds)
    
    # Sort domains by access count (descending)
    var sorted_domains = domain_counts.keys()
    sorted_domains.sort_custom(func(a, b): return domain_counts[a] > domain_counts[b])
    
    # Select a random column for each domain
    var available_columns = range(total_columns)
    
    for domain in sorted_domains:
        if available_columns.is_empty():
            break
        
        var column = available_columns.pick_random()
        available_columns.erase(column)

        var domain_chars = []
        for c in domain.reverse():
            # Convert character to uppercase and match to float value from table
            domain_chars.append(character_table[c.to_upper()])

        shader_parameters = {
            "resolution": resolution,
            "render_speed": render_speed,
            "rain_speed": domain_speeds[domain],
            "domain": PackedFloat32Array(domain_chars),
            "domain_length": domain.length(),
            "domain_column": randi() % total_columns,
        }
        
        setup_window()
        
        # Set render priority higher than MatrixWindow so it appears on top
        if mesh_instance and mesh_instance.material_override is ShaderMaterial:
            mesh_instance.material_override.render_priority = 1
    
    # Reset domain counts after displaying
    domain_counts.clear()

func calculate_frequencies(counts):
    var total_requests = 0
    var max_count = 0
    
    # Calculate total requests and find the maximum count
    for count in counts.values():
        total_requests += count
        if count > max_count:
            max_count = count
    
    if total_requests == 0:
        return {}  # Avoid division by zero
    
    var max_frequency = max_rain_speed
    var min_frequency = min_rain_speed
    
    var frequencies = {}
    
    for domain in counts.keys():
        var count = counts[domain]
        var normalized_freq = (count / float(max_count)) * (max_frequency - min_frequency) + min_frequency
        frequencies[domain] = normalized_freq
    
    return frequencies
