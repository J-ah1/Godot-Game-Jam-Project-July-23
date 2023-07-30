extends RigidBody2D

const DURATION = 2
@onready var scoreText = $ScoreText
@onready var timer = $Timer
var score = 0

func _ready():
	timer.wait_time = DURATION / Global.currGameSpeed
	timer.start()
	scoreText.text = "+ " + str(score)
	await timer.timeout
	queue_free()

func setScore(score):
	self.score = score
