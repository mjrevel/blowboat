class_name Helper extends Node

var initial_time = null
var is_complete = false
var result

func local_lerp(A: float, B: float, time_now: float, delay: float) -> float:
	if initial_time == null:
		initial_time = time_now
		
	result = A + (B - A) * map(time_now, initial_time, initial_time + delay, 0, 1)
	
	if result <= 0:
		is_complete = true
	else:
		is_complete = false
	# the current time needs to be stored becaues thats the starting time of the lerp
	return result

func llerp(value: float, stop_at: float) -> float:
	var result = stop_at
	
	if value > stop_at:
		result = value
	else:
		result = stop_at
	
	return result

	
func map(x: float, in_min: float, in_max: float, out_min: float, out_max: float) :
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
