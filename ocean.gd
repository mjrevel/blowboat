extends Node3D

var serial
var recv

@onready var p1_data: int = 0
@onready var p2_data: int = 0
@onready var p1_greatest: int = 0
@onready var p2_greatest: int = 0

var p1_avg: int = 0
var p2_avg: int = 0
var sample_size: int = 10
var decay_rate = 500.0

func _ready():
	# List all connected serial devices.
	var devices = Serial.list_ports()
	print(devices)

	serial = Serial.new()
	# Open by vender id and product id
	serial.open("/dev/ttyACM0", 115200)

	if serial.is_open() == true:
		# Then you can read data from serial device.
		recv = serial.read()
	else:
		serial.close()
	# And write report data to serial device
	#serial.write(data_to_send)
	
func get_p1_data() -> int:
	return p1_greatest
	
func get_p2_data() -> int:
	return p2_greatest

func _physics_process(delta: float) -> void:	
	if serial.is_open() == true:
		recv = serial.read_str(true)
		recv = recv.split(",")
		
		if recv.size() == 2:
			p1_data = int(recv[0])
			p2_data = int(recv[1])
			
			if p1_data > p1_greatest:
				p1_greatest = p1_data
			elif p1_data <= p1_greatest:
				p1_greatest = RelicHelper.llerp(p1_greatest - delta * decay_rate, 0)
			
			if p2_data > p2_greatest:
				p2_greatest = p2_data
			elif p2_data <= p2_greatest:
				p2_greatest = RelicHelper.llerp(p2_greatest - delta * decay_rate, 0)
				
			#for i in sample_size:
				#p1_avg += p1_data
				#p2_avg += p2_data
				#
			#p1_avg = p1_avg / sample_size
			#p2_avg = p2_avg / sample_size
				
		#if begin == true && end == true:
			#recv = recv.split(",")
			#for p in recv:
				#print("|" + p)

func _process(_delta):
	pass
	#if serial.is_open() == true:
		#recv = serial.read()
