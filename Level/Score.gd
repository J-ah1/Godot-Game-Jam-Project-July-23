extends Node2D

@onready var scoreText = $ScoreText

func setScore(score):
	scoreText.text = "Score: " + str(score)
