extends Node

var is_running_in_visionos : bool = OS.get_name() == "iOS" and OS.get_environment("GODOT_PLATFORM") == "visionOS"
var is_running_in_web : bool = OS.get_name() == "Web" or OS.get_name() == "HTML5"
var joystick_touch_pad_enabled : bool = false
