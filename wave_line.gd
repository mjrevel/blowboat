extends Line2D


func _ready() -> void:
	default_color = Color(1.0, 0.0, 0.0, 1.0)
	width = 1
	antialiased = true
	
	#add_point(Vector2(0, 100))
	#add_point(Vector2(100, 200))
	#add_point(Vector2(200, 500))
	
func _physics_process(_delta: float) -> void:
	pass
