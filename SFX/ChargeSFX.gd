extends AudioStreamPlayer


func playAtPitch(pitch):
	self.pitch_scale = pitch
	play()
	await finished
	queue_free()
