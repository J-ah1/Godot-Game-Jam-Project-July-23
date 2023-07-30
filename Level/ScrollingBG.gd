extends ParallaxBackground


const MAX_SPEED = 3000
const START_SPEED = 600
var acceleration = 0
var speed = START_SPEED

func setAccel(accelPercentage):
	# SHOULD be the SAME as the Level...?
	acceleration = accelPercentage * (MAX_SPEED - START_SPEED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# this SHOULD PAUSE, when confronting
	speed = clamp(speed + acceleration * delta, START_SPEED, MAX_SPEED)
	self.scroll_offset.x =  self.scroll_offset.x + speed * delta
	
