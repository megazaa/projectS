extends Label
var fps_display_interval = 1.0  # Time in seconds to update the FPS
var frame_count = 0
var elapsed_time = 0.0
@onready var label: Label = $"."

func _ready():
	# Set initial text for the label
	text = "Physics FPS: 0"

func _process(delta):
	frame_count += 1
	elapsed_time += delta
	var eneymy =  "\n"+"player_pos"+str(Global.enemy_state)
	var text =  "\n"+"player_pos"+str(Global.player_current_pos) + eneymy
	self.text = text
	
