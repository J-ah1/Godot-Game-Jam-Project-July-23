extends Node

const ACCEL := 0.03
const MAX_GAME_SPEED := 4.0
const START_GAME_SPEED := 1.0
var currGameSpeed := START_GAME_SPEED

const TWEEN_START_DURATION := 2.0
const TWEEN_TYPE = Tween.TRANS_SINE
const TWEEN_EASE = Tween.EASE_IN
var restartingRunSpeed = false

func accelGameSpeed(delta):
	if(restartingRunSpeed):
		return
	#hmmm... why are we multiplying by delta here...?
	#vf = vi + (at)
	#df = di + (vt)
	currGameSpeed += ACCEL * delta

func restartRunSpeed():
	restartingRunSpeed = true
	var topSpeed = currGameSpeed
	currGameSpeed = 0
	var tween = create_tween()
	tween.tween_property(self, "currGameSpeed", topSpeed, TWEEN_START_DURATION/(1+log(topSpeed)))\
	.set_trans(TWEEN_TYPE).set_ease(TWEEN_EASE)
	await tween.finished
	restartingRunSpeed = false
