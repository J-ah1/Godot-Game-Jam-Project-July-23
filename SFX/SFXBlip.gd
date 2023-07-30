extends AudioStreamPlayer

func _ready():
	play()
	await finished
	queue_free()
