extends Node

# Environment
var DEBUG: bool = true
var is_running_in_visionos: bool = OS.get_name() == "iOS" and OS.get_environment("GODOT_PLATFORM") == "visionOS"
var is_running_in_web: bool = OS.get_name() == "Web" or OS.get_name() == "HTML5"
var joystick_touch_pad_enabled: bool = false
var passthrough_enabled: bool = false
var enable_visualizations: bool = false

# UI
var mesh_scene : Node3D

# User
var EYE_HEIGHT: float = 1.75
var MAX_HEIGHT: float = 20  # Ceiling limit
var MIN_HEIGHT: float = 0.0005  # Floor limit

# API
var server_ip: String = "172.16.100.1"
var server_port_tcp: int = 443
var server_port_udp: int = 8192

# Generate
const OLLAMA_HOST= "http://localhost:11434"
const MODEL_NAME = "hf.co/bartowski/LLaMA-Mesh-GGUF:Q4_K_M"
const TEMPERATURE = 0.95
const MAX_TOKENS = 4096
const TEST_LOG_FILE = "generate-verbose.log"
const TEST_DEBUG_FILE = "generate-gdscript.log"
const TEST_GLB_FILE = "sword.glb"
const LOG_STREAM = true
