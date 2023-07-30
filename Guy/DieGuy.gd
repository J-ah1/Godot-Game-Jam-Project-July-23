extends RigidBody2D

@onready var particles = $GPUParticles2D
@onready var onScreenNotif = $VisibleOnScreenNotifier2D
var isOnScreen = true

func _physics_process(delta):
	particles.process_material.gravity = Vector3(-linear_velocity.x*0.1, -linear_velocity.y*0.1, 0)

func onBodyEntered(body):
	self.call_deferred("remove_child", $CollisionShape2D)
	self.call_deferred("changeParent", body)


func changeParent(body):
	if isOnScreen:
		particles.emitting = false
	else:
		self.call_deferred("remove_child", particles)
	var newParent = body
	var offsetFromParent = self.position - newParent.position
	get_parent().remove_child(self)
	newParent.add_child(self)
	newParent.move_child(self, 0)
	self.position = offsetFromParent
	self.lock_rotation = true
	self.freeze = true

func onVisibleOnScreenNotifier2d_ScreenEntered():
	isOnScreen = true


func onVisibleOnScreenNotifier2d_ScreenExited():
	isOnScreen = false
