extends Node
class_name StyxApi

# This line will generate the following debugger warning, please ignore:
# The signal "data_received" is declared but never explicitly used in the cslass.
signal data_received(endpoint: String, data: Array)

# Network client setup (UDP for native clients, TCP HTTPRequest for WebXR web export)
var http_client: HTTPRequest = HTTPRequest.new()
var is_initialized: bool = false  # Prevents duplicate initialization
var udp_client: PacketPeerUDP = PacketPeerUDP.new()
var packet_fragments := {}

var api_endpoint: String = ""

# Initialize styx_api with a specific endpoint
func init(api_path: String) -> void:
    if is_initialized:
        return
    is_initialized = true
    api_endpoint = api_path

func _ready():
    if not Globals.is_running_in_web:
        # Create and bind the UDP client to any available port
        if udp_client and not udp_client.is_bound():  # Ensure it's not already bound
            var bind_result: int = udp_client.bind(0)
            if bind_result != OK:
                print("Failed to bind UDP client, error code: ", bind_result)
    else:
        # Add HTTPRequest to the scene tree and connect signal
        add_child(http_client)
        http_client.connect("request_completed", self._process_response_http)
        send_request()

func send_request() -> void:
    if not Globals.is_running_in_web:
        var json_data: Dictionary = {"GET": api_endpoint}
        var json_str: String = JSON.stringify(json_data)

        # Send request via UDP
        udp_client.connect_to_host(Globals.server_ip, Globals.server_port_udp)
        var packet: PackedByteArray = json_str.to_utf8_buffer()
        var sent: int = udp_client.put_packet(packet)
        if sent == OK:
            print("Sent via UDP: ", json_str)
        else:
            print("Failed to send request via UDP")
    else:
        var status = http_client.get_http_client_status()
        if status == HTTPClient.STATUS_DISCONNECTED:
            var url = "https://%s:%d%s" % [Globals.server_ip, Globals.server_port_tcp, api_endpoint]
            print("Connecting to URL: ", url)
            var error = http_client.request(url, [], HTTPClient.METHOD_GET)
            if error != OK:
                print("Failed to initiate HTTP request. Error: ", error)
        else:
            print("Delaying HTTP request, status: ", status)

func _process(_delta: float) -> void:
    if not Globals.is_running_in_web:
        receive_udp_response()

func receive_udp_response() -> void:
    while udp_client.get_available_packet_count():
        var packet: PackedByteArray = udp_client.get_packet()
        var response: String = packet.get_string_from_utf8()
        process_response_udp(response)

func process_response_udp(response: String) -> void:
    # Parse the fragment
    var delimiter_index: int = response.find(":")
    if delimiter_index == -1:
        print("Received malformed packet: ", response)
        return

    var header: String = response.substr(0, delimiter_index)
    var body: String = response.substr(delimiter_index + 1)

    # Parse the header (format: "fragment_num/total_fragments")
    var fragment_info: PackedStringArray = header.split("/")
    if fragment_info.size() != 2:
        print("Received malformed packet header: ", header)
        return

    var fragment_num: int = int(fragment_info[0])
    var total_fragments: int = int(fragment_info[1])

    # Store the fragment
    if !packet_fragments.has(fragment_num):
        packet_fragments[fragment_num] = body

    # Once all fragments have been received, process the complete response.
    if packet_fragments.size() == total_fragments:
        var complete_response: String = ""
        for i in range(1, total_fragments + 1):
            complete_response += packet_fragments[i]

        # All fragments received, process the response
        process_data(complete_response)

        # Clear stored fragments for the next message
        packet_fragments.clear()

func _process_response_http(_result, response_code: int, _headers, body: PackedByteArray) -> void:
    if response_code == 200:
        var response: String = body.get_string_from_utf8()
        process_data(response)
    else:
        print("HTTP request failed with response code: ", response_code)

# Process the data returned by the call to the API
func process_data(body: String) -> void:
    var json = JSON.new()
    var json_result = json.parse(body)

    if json_result == OK:
        var parsed_data = json.get_data()
        if parsed_data.size() > 0:
            # Emit the data_received signal with the current endpoint and parsed data.
            emit_signal("data_received", api_endpoint, parsed_data)
        else:
            print("No data found in JSON response")
    else:
        print("Failed to parse JSON: ", body)
