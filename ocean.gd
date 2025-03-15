extends Node3D

var serial
var recv

func _ready():
	# List all connected serial devices.
	var devices = Serial.list_ports()
	print(devices)

	serial = Serial.new()
	# Open by vender id and product id
	serial.open("/dev/pts/1", 115200)

	if serial.is_open() == true:
		# Then you can read data from serial device.
		recv = serial.read()
	else:
		serial.close()
	# And write report data to serial device
	#serial.write(data_to_send)


func _process(delta):
	if serial.is_open() == true:
		recv = serial.read()
