extends Node

@onready var floorInst = preload("res://Level/Floor.tscn")
@onready var floors = $Floors
const FLOOR_SIZE_VECT = Vector2(3000, 160)
const FLOOR_SPAWN_VECT = Vector2((FLOOR_SIZE_VECT.x-2)*5, 900 - FLOOR_SIZE_VECT.y)

@export var despawnX = -5950
const MAX_SPEED = 3000
const START_SPEED = 600
var speed = START_SPEED

const LEVEL_SPEED_FACTOR = (MAX_SPEED-START_SPEED)/(Global.MAX_GAME_SPEED-Global.START_GAME_SPEED)

@onready var guyInst = preload("res://Guy/Guy.tscn")
@onready var guys = $Guys

@onready var player = $Player
@onready var inRangeNotif = $InRangeNotifier
var guyInRange = false
var targetGuy = null

@onready var camera = $Camera2D
var cameraStartPos = Vector2(800,450)
var cameraTrauma = 0.0
var traumaPower = 1.5
var traumaDecay = 1.0
var maxOffset = Vector2(10, 8) 
var maxRoll = 20.0

@onready var bgm = $BGM

var isConfronting = false
const TWEEN_START_DURATION := 4.0
const TWEEN_TYPE = Tween.TRANS_QUINT
const TWEEN_EASE = Tween.EASE_OUT

const CONFRONT_BASE_MULT = 80
var baseConfrontScore = 0

const CHARGE_ADD_MULT = 0.1
const CHARGE_DECAY_MULT = 0.9
var chargePercent = 0.0
const chargeMeterWH = Vector2(100, 40)
@onready var chargeMeter = $ChargeMeter
@onready var chargeMeterBar = $ChargeMeter/ChargeMeterBar

const PASSING_BASE_MULT = 50

var currScore = 0
@onready var scoreUI = $Score
@onready var plusScoreNotifInst = preload("res://Level/PlusScoreNotif.tscn")

@onready var passingSFXInst = preload("res://SFX/PassingSFX.tscn")

@onready var dieGuysAndItems = $DieGuysAndItems
@onready var dieGuyInst = preload("res://Guy/DieGuy.tscn")


var isGameOver = false
@onready var gameOverScreen = $GameOverScreen

@onready var backgroundInst = preload("res://Level/Background.tscn")
@onready var backgrounds = $Backgrounds
const backgroundParaFactor = 0.4

func reset():
	targetGuy = null
	Global.currGameSpeed = 1.0
	AudioServer.set_bus_effect_enabled(1,0,false)
	AudioServer.set_bus_volume_db(0,0.0)
	get_tree().reload_current_scene()

func _ready():
	randomize()
	#noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	#noise.seed = randi()
	for i in range(1,6):
		spawnFloor(Vector2((FLOOR_SIZE_VECT.x-2)*i, 900 - FLOOR_SIZE_VECT.y))
	for i in range(1,6):
		spawnBackground(Vector2((FLOOR_SIZE_VECT.x-2)*i, 0))

func _process(delta):
	if(isConfronting):
		chargePercent = max(chargePercent - CHARGE_DECAY_MULT * Global.currGameSpeed * delta, 0)
		chargeMeterBar.region_rect = Rect2(0,0,chargeMeterWH.x * min(chargePercent, 1), chargeMeterWH.y)
	if cameraTrauma:
		cameraTrauma = max(cameraTrauma - traumaDecay * delta, 0)
		shakeCamera()
	if not(isGameOver or isConfronting):
		Global.accelGameSpeed(delta)
		# this SHOULD PAUSE, when confronting
		speed = clamp(START_SPEED + (Global.currGameSpeed-Global.START_GAME_SPEED) * (LEVEL_SPEED_FACTOR), 0, MAX_SPEED)
#		if(speed == 0):
#			if(isGameOver):
#				print("GAME OVER")
#				get_tree().paused = true
#			else:
#				print("play confront attack here...?")
			
		moveFloors(delta)
		moveGuys(delta)
		#moveDieGuysAndItems(delta)
		moveBackgrounds(delta)
		
		

func addScore(score):
	var plusScoreNotif = plusScoreNotifInst.instantiate()
	plusScoreNotif.setScore(score)
	plusScoreNotif.position = Vector2(190, 500)
	self.add_child(plusScoreNotif)
	currScore += score
	scoreUI.setScore(currScore)

func shakeCamera():
	#currNoiseY += 1 # do i need to modulo trick this...?
	var amount = cameraTrauma * traumaPower
	if(isConfronting):
		amount *= 1+Global.currGameSpeed/3
	camera.rotation = maxRoll * amount * randf_range(-1, 1) #noise.get_noise_2d(noise.seed, currNoiseY)
	camera.offset.x = maxOffset.x * amount * randf_range(-1, 1) #noise.get_noise_2d(noise.seed*2, currNoiseY)
	camera.offset.y = maxOffset.y * amount * randf_range(-1, 1) #noise.get_noise_2d(noise.seed*3, currNoiseY)

func zoomInSlowEffect(tween, tweenDuration):
	tween.tween_property(camera, "position", player.position, tweenDuration)\
	.set_trans(TWEEN_TYPE).set_ease(TWEEN_EASE)
	tween.tween_property(camera, "zoom", Vector2(2,2), tweenDuration)\
	.set_trans(TWEEN_TYPE).set_ease(TWEEN_EASE)
	tween.tween_property(bgm, "pitch_scale", 0.7, 0.8)\
	.set_trans(TWEEN_TYPE).set_ease(TWEEN_EASE)
	AudioServer.set_bus_effect_enabled(1,0,true)

func zoomOutSpeedEffect():
	var tween = create_tween().set_parallel(true)
	var tweenDuration = 1.0/Global.currGameSpeed
	tween.tween_property(camera, "position", cameraStartPos, tweenDuration)\
	.set_trans(TWEEN_TYPE).set_ease(TWEEN_EASE)
	tween.tween_property(camera, "zoom", Vector2(1,1), tweenDuration)\
	.set_trans(TWEEN_TYPE).set_ease(TWEEN_EASE)
	
	tween.tween_property(bgm, "pitch_scale", 1, 0.8)\
	.set_trans(TWEEN_TYPE).set_ease(TWEEN_EASE)
	AudioServer.set_bus_effect_enabled(1,0,false)

func confrontToPosition():
	var distanceToPosition = targetGuy.position.x - player.position.x + 30
	var tween = create_tween().set_parallel(true)
	var tweenDuration = TWEEN_START_DURATION/Global.currGameSpeed
	if(not targetGuy.isBad):
		tweenDuration = TWEEN_START_DURATION * 2
	player.startSliding()
	for floor in floors.get_children():
		tween.tween_property(floor, "position",\
		Vector2(floor.position.x-distanceToPosition,floor.position.y), tweenDuration)\
		.set_trans(TWEEN_TYPE).set_ease(TWEEN_EASE)
	for guy in guys.get_children():
		tween.tween_property(guy, "position",\
		Vector2(guy.position.x-distanceToPosition,guy.position.y), tweenDuration)\
		.set_trans(TWEEN_TYPE).set_ease(TWEEN_EASE)
	for background in backgrounds.get_children():
		tween.tween_property(background, "position",\
		Vector2(background.position.x-distanceToPosition,background.position.y), tweenDuration)\
		.set_trans(TWEEN_TYPE).set_ease(TWEEN_EASE)
	
	zoomInSlowEffect(tween, tweenDuration)
	if (targetGuy.isBad):
		await tween.finished
		await get_tree().create_timer(1.0).timeout
		# PUNCH AFTERMATH GOES HERE
		player.doPunch()
		targetGuy.die()
		spawnDieGuy()
		zoomOutSpeedEffect()
		var addAmt = int(baseConfrontScore * (1+min(chargePercent*2, 2.0)))
		print("Confront Score: ",  addAmt)
		addScore(int(addAmt))
		
		targetGuy = null
		chargePercent = 0
		chargeMeter.visible = false
		chargeMeterBar.region_rect = Rect2(0,0,0,chargeMeterWH.y)
		isConfronting = false
		Global.restartRunSpeed()
	else:
		isGameOver = true
		player.doWhoops()
		await player.get_node("AnimationPlayer").animation_finished
		targetGuy.die()
		chargePercent = 1
		spawnDieGuy()
		gameOverScreen.playGameOverSequence(currScore)
		
		

func spawnDieGuy():
	var dieGuy = dieGuyInst.instantiate()
	dieGuy.linear_velocity = Vector2(200, -1500)
	dieGuy.linear_velocity += Vector2(3500 * min(chargePercent, 1.0), -2000 * min(chargePercent, 1.0))
	dieGuy.linear_velocity += Vector2(100 * randf() * min(chargePercent, 1.0), -50 * randf() * min(chargePercent, 1.0))
	dieGuy.angular_velocity += randi_range(0, 200)
	dieGuy.position = targetGuy.position + Vector2(5, -5)
	dieGuysAndItems.add_child(dieGuy)

func setupConfront():
	baseConfrontScore = CONFRONT_BASE_MULT * Global.currGameSpeed

func _input(event):
	if(event.is_action_pressed("quickRestart")):
		reset()
	if(isGameOver):
		return
	if(not isConfronting and guyInRange and event.is_action_pressed("confront")):
		inRangeNotif.visible = false
		isConfronting = true
		
		guyInRange = false
		# should check if good but... no need to do anything if bad?
		if(targetGuy.isBad):
			# do the confronting attack
			print("RECYCLE!!!")
			chargeMeter.visible = true
			setupConfront()
		else:
			print("AGH I HIT A GOOD GUY NOOO")
			# game over
		confrontToPosition()
	elif(isConfronting and (event.is_action_pressed("powerUp1") or event.is_action_pressed("powerUp2"))):
		# WHAT HAPPENS WHEN CHARGING
		#var chargeSFX = chargeSFXInst.instantiate()
		
		
		player.chargePunch(chargePercent)
		chargePercent = min(chargePercent + CHARGE_ADD_MULT * Global.currGameSpeed, 1.1)
		cameraTrauma = min(cameraTrauma + 0.1, 1.0)
		#currConfrontScore += addConfrontScore
		

func moveBackgrounds(delta):
	for background in backgrounds.get_children():
		background.position.x -= speed * delta * backgroundParaFactor
		if(background.position.x <= despawnX):
			# moves bg back...shouldnt i use this for all the floors too...?
			background.position.x = FLOOR_SPAWN_VECT.x + background.position.x - despawnX

func moveFloors(delta):
	for floor in floors.get_children():
		floor.position.x -= speed * delta
		if(floor.position.x <= despawnX):
			#spawnFloor(FLOOR_SPAWN_VECT, floor.position.x - despawnX)
			#floor.queue_free()
			var offset = floor.position.x - despawnX
			floor.position.x = FLOOR_SPAWN_VECT.x + offset
			spawnGuys(FLOOR_SPAWN_VECT, offset)
			# in gen, we're doing a lot of repeated work...?

func moveGuys(delta):
	for guy in guys.get_children():
		guy.position.x -= speed * delta
		if(guy.position.x <= despawnX):
			guy.queue_free()
			

func moveDieGuysAndItems(delta):
	for dieGuyOrItem in dieGuysAndItems.get_children():
		dieGuyOrItem.position.x -= speed * delta
		if(dieGuyOrItem.position.x <= despawnX):
			dieGuyOrItem.queue_free()


func spawnBackground(spawnVect = FLOOR_SPAWN_VECT, offSetX = 0):
	var newBackground = backgroundInst.instantiate()
	newBackground.position = spawnVect
	newBackground.position.x += offSetX
	backgrounds.add_child(newBackground)

func spawnFloor(spawnVect = FLOOR_SPAWN_VECT, offSetX = 0):
	var newFloor = floorInst.instantiate()
	newFloor.position = spawnVect
	newFloor.position.x += offSetX
	floors.add_child(newFloor)
	spawnGuys(spawnVect, offSetX)

func spawnGuys(spawnVect = FLOOR_SPAWN_VECT, offSetX = 0):
	var newGuy = guyInst.instantiate()
	newGuy.position = spawnVect + Vector2(randi_range(0,800), 0)
	newGuy.position.x += offSetX
	guys.add_child(newGuy)
	newGuy = guyInst.instantiate()
	newGuy.position = spawnVect + Vector2(randi_range(1500,2300), 0)
	newGuy.position.x += offSetX
	guys.add_child(newGuy)


func onPlayer_AreaEntered(area):
	inRangeNotif.visible = true
	guyInRange = true
	targetGuy = area

func onPlayer_AreaExited(area):
	inRangeNotif.visible = false
	if(targetGuy == null):
		return
	guyInRange = false
	if(targetGuy.isBad):
		print("THAT WAS A BAD GUY NOOOOO") # game over
		isGameOver = true
		var tween = create_tween().set_parallel(true)
		zoomInSlowEffect(tween, TWEEN_START_DURATION)
		Global.currGameSpeed = 0.05
		targetGuy.playDropping()
		await targetGuy.get_node("AnimationPlayer").animation_finished
		gameOverScreen.playGameOverSequence(currScore)
	else:
		var passingScore = PASSING_BASE_MULT * Global.currGameSpeed
		add_child(passingSFXInst.instantiate())
		print("Pass: ", int(passingScore)) # add score
		addScore(int(passingScore))
