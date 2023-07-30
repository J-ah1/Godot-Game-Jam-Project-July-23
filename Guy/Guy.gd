extends Area2D

@onready var item = $Item
@onready var trash1 = preload("res://Guy/trash1.png")
@onready var recyclable1 = preload("res://Guy/recyclable1.png")

@onready var bin = $Bin
@onready var garbageBin = preload("res://Guy/garbageBinButEvenBigger.png")
@onready var recycleBin = preload("res://Guy/recycleBinButEvenBigger.png")

@onready var animPlayer = $AnimationPlayer

const GOOD_FACTOR = 5
var isBad = false

func _ready():
	if(randi() % GOOD_FACTOR == 0):
		isBad = true
		if(randi() % 2):
			bin.texture = garbageBin
			item.texture = recyclable1
		else:
			bin.texture = recycleBin
			item.texture = trash1
	else:
		isBad = false
		if(randi() % 2):
			bin.texture = garbageBin
			item.texture = trash1
		else:
			bin.texture = recycleBin
			item.texture = recyclable1

func die():
	self.remove_child($GuySprite)
	self.remove_child(item)

func playDropping():
	animPlayer.play("dropping")
