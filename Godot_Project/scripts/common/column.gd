extends MeshInstance3D

var color: Array = [1, 1, 1]  # Default white
var label_enabled: bool = false  # Default: no label
var x_width_and_z_depth: float = 0.1
var domain_label: Label3D = null

# Toggle whether to use the glow shader. (True by default but not supported in visionOS)
var use_glow_shader: bool = not Globals.is_running_in_visionos

func _init(column_color: Array = [1, 1, 1], label_content: String = "", label_show: bool = false):
    self.color = column_color
    self.name = label_content
    self.label_enabled = label_show

    if use_glow_shader:
        # Attempt to load the glow shader
        var glow_shader = load("res://shaders/common/cube_mesh_glow_outline.gdshader")
        if glow_shader and glow_shader is Shader:
            var shader_material = ShaderMaterial.new()
            shader_material.shader = glow_shader
            # Preserve the color. (Other uniforms such as width, sharpness, glow will use the defaults from the shader)
            shader_material.set_shader_parameter("color", Color(color[0], color[1], color[2]))
            
            var tex = load("res://assets/textures/cube_mesh_glow_outline.png")
            if tex is Texture2D:
                shader_material.set_shader_parameter("tex", tex)

            # BoxMesh of size (1,1,1) is required by the shader
            var box_mesh = BoxMesh.new()
            box_mesh.size = Vector3.ONE
            # Set a default custom AABB (this will be updated in _ready() based on the final scale)
            box_mesh.custom_aabb = AABB(Vector3(-0.5, -0.5, -0.5), Vector3.ONE)

            mesh = box_mesh
            material_override = shader_material
        else:
            use_glow_shader = false

    if not use_glow_shader:
        var box_mesh = BoxMesh.new()
        box_mesh.size = Vector3(x_width_and_z_depth, 1.0, x_width_and_z_depth)
        mesh = box_mesh

        var material = StandardMaterial3D.new()
        material.albedo_color = Color(color[0], color[1], color[2])
        material_override = material

func _ready():
    # If using the glow shader, transfer the node’s externally set scale into the shader uniform,
    # then reset the node’s scale so that the shader (and our custom AABB) are the only source of scaling
    if material_override is ShaderMaterial:
        var shader_material = material_override as ShaderMaterial
        # The node’s scale (set externally) becomes the new scale
        #  shader_material.set_shader_parameter("scale", self.scale)
        var desired_scale = Vector3(x_width_and_z_depth, self.scale.y, x_width_and_z_depth)
        shader_material.set_shader_parameter("scale", desired_scale)
        # Reset the node’s scale so that it remains (1,1,1) in the scene
        self.scale = Vector3.ONE
        # Update the custom AABB to match the scaled size
        var half_extents = desired_scale * 0.5
        set_custom_aabb(AABB(-half_extents, desired_scale))

    # Create a StaticBody3D for input events
    var static_body = StaticBody3D.new()
    add_child(static_body)
    var collision_shape = CollisionShape3D.new()
    var box_shape = BoxShape3D.new()
    if material_override is ShaderMaterial:
        # Set the collision box size to match the shader scale
        var shader_material = material_override as ShaderMaterial
        var desired_scale = shader_material.get_shader_parameter("scale")
        box_shape.extents = desired_scale * 0.5
    else:
        box_shape.extents = (mesh as BoxMesh).size * 0.5
    collision_shape.shape = box_shape
    static_body.add_child(collision_shape)

    static_body.input_ray_pickable = true

    if label_enabled:
        display_domain_name()

func _input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton and event.is_pressed():
        print("Column tapped: ", name)
        display_domain_name()

func display_domain_name():
    if domain_label:
        domain_label.queue_free()
    domain_label = Label3D.new()
    domain_label.text = name
    domain_label.transform.basis = Basis(Vector3(0, 1, 0), -PI / 2)
    var column_height: float = 0.0
    if material_override is ShaderMaterial:
        var shader_material = material_override as ShaderMaterial
        column_height = shader_material.get_shader_parameter("scale").y
    else:
        column_height = (mesh as BoxMesh).size.y
    domain_label.transform.origin = transform.origin + Vector3(-1.2, column_height, -7)
    add_child(domain_label)
