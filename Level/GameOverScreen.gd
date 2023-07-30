extends CanvasLayer

@onready var blackBG = $BlackBG
@onready var gameOverText = $GameOverText
@onready var finalScoreText = $FinalScoreText


func playGameOverSequence(finalScore):
	visible = true
	var tween = create_tween()
	tween.tween_property(blackBG, "color:a", 1, 3).set_trans(tween.TRANS_LINEAR)
	await tween.finished
	await get_tree().create_timer(1.0).timeout
	gameOverText.visible = true
	finalScoreText.text = "Final Score: " + str(finalScore)
	finalScoreText.visible = true

func reset():
	gameOverText.visible = false
	finalScoreText.visible = false
	blackBG.color.a = 0
	visible = false
