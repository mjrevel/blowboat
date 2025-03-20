# Resource: https://forum.godotengine.org/t/how-can-i-make-a-function-graphic/19562
extends Node2D

var a = 1.0
var w = 1.0
var s = 1.0

func _ready() -> void:
	pass
	#print("Draw is ready...")
	
func update_equation(aa: float, ww: float, ss: float):
	a = aa
	w = ww
	s = ss
	queue_redraw()

func _draw():
	#DebugDraw2D.set_text("get_heght: {0}".format([wave_height]))
	# Create an Expression from the formula
	var input_names = PackedStringArray(["x"])
	var expression = Expression.new()
	var err = expression.parse("{0}*sin(x*{1}+{2})".format([a, w, s]), input_names)
	if err != OK:
		print("Error parsing the formula: ", err)
		return
	
	# Choose graph dimensions and scales:
	# In pixels on screen
	var pixel_xmin = 0.0
	var pixel_xmax = 150.0
	var pixel_ymin = 150.0 # in Godot 2D, Y axis points down, but we want up
	var pixel_ymax = 0.0
	# Graph area
	var xmin = -4.0
	var xmax = 8.0
	var ymin = -4.0
	var ymax = 4.0
	
	var inputs = [0]
	var prev_pixel_y = null
		
	# For each pixel along the X axis
	for pixel_x in range(pixel_xmin, pixel_xmax):
		# Convert X to graph coordinates
		var x = lerp(xmin, xmax, inverse_lerp(pixel_xmin, pixel_xmax, pixel_x))
		
		# Execute expression
		inputs[0] = x
		var y = expression.execute(inputs)
		
		if expression.has_execute_failed() or is_inf(y) or is_nan(y):
			# Skip this point
			prev_pixel_y = null
			continue
		
		# Convert Y to graph coordinates
		var pixel_y = lerp(pixel_ymin, pixel_ymax, inverse_lerp(ymin, ymax, y))
		
		if prev_pixel_y != null:
			# Draw line if we have a previous value to connect to the current one
			draw_line(
				Vector2(pixel_x - 1, prev_pixel_y),
				Vector2(pixel_x, pixel_y),
				Color(1, 1, 0))
		
		# Remember last value so we can draw a line in the next iteration
		prev_pixel_y = pixel_y
