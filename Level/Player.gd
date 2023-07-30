extends Area2D

@onready var playerSprite = $Sprite2D
@onready var animPlayer = $AnimationPlayer
@onready var hitSFXInst = preload("res://SFX/HitSFX.tscn")
@onready var chargeSFXInst = preload("res://SFX/ChargeSFX.tscn")

# note: this is purely animation speed
const MAX_SPEED = 4
const START_SPEED = 1

# 5-8 is the whole confront, charge, punch, pullback
const FRAME_SLIDING = 5
const FRAME_CHARGING = 6

func _process(delta):
	# this SHOULD PAUSE, when confronting
	animPlayer.speed_scale = clamp(Global.currGameSpeed, 0, MAX_SPEED)
	
func startRunning():
	animPlayer.play("running")

func startSliding():
	animPlayer.stop()
	playerSprite.frame = FRAME_SLIDING
	
func chargePunch(chargePercent):
	var pitchInc = 1 + min(chargePercent*2, 2)
	var chargeSFX = chargeSFXInst.instantiate()
	add_child(chargeSFX)
	chargeSFX.playAtPitch(pitchInc)
	playerSprite.frame = FRAME_CHARGING

func doPunch():
	add_child(hitSFXInst.instantiate())
	animPlayer.play("punch")
	await animPlayer.animation_finished
	startRunning()

func doWhoops():
	animPlayer.stop()
	animPlayer.speed_scale = 1
	animPlayer.play("whoops")
	await animPlayer.animation_finished
	add_child(hitSFXInst.instantiate())
	# can maybe have level look out for the animPlayer signal to continue the game over sequence
