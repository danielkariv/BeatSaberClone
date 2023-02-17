extends Node

@export var red_cube_prefeb : PackedScene = preload("res://red_cube_prefeb.tscn")
@export var blue_cube_prefeb : PackedScene = preload("res://blue_cube_prefeb.tscn")
@export var boom_prefeb : PackedScene = preload("res://boom_predeb.tscn")
@export var wall_prefeb : PackedScene = preload("res://wall_prefeb.tscn")

var interface : XRInterface
var placement_offset : Vector3 = Vector3(-1.5,0.5,0)

var _left_controller : XRController3D
var _right_controller : XRController3D

# need to reset all of those when loading new beatmap.
var scroller : Node3D
var isplaying : bool = false
var time : float = 0.0
var bpm : float = 128.0
var songTimeOffset : float = 0.0
var songlabel : String = ""
var noteJumpMovementSpeed : float = 0.0
var noteJumpStartBeatOffset : float = 0.0
var song_time : float = 0.0

signal song_label_changed(new_text : String)
signal time_label_changed(new_text : String)
signal show_menu(value : bool)
func _ready():
	interface = XRServer.find_interface("OpenXR")
	if interface and interface.is_initialized():
		print("OpenXR initialised successfully")
		
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialised, please check if your headset is connected")
	
func on_play_beatmap(songPath,diff):
	print("try to load beatmap: ",songPath, "diffuclty: ",diff)
	
	# resets all old beatmap information:
	isplaying = false
	time = 0.0
	bpm = 128.0
	songTimeOffset = 0.0
	songlabel = ""
	noteJumpMovementSpeed = 0.0
	noteJumpStartBeatOffset = 0.0
	song_time = 0.0
	
	var current = Time.get_unix_time_from_system()
	
	var level_filename = load_beatmap_info(songPath,diff)
	var beatmap_diff_path = songPath + "/" +level_filename
	load_beatmap(beatmap_diff_path)
	
	var took = Time.get_unix_time_from_system() - current
	
	print("Done loading after : ",took)
	
	isplaying = true

func load_beatmap_info(beatmap_path : String,selected_diff : String) -> String:
	var file = FileAccess.open(beatmap_path + "/Info.dat", FileAccess.READ)
	var text = file.get_as_text(true)
	var dict = JSON.parse_string(text)
	# Debug printing
	if false: 
		print(dict["_songName"],"|||",dict["_songSubName"],"|||",dict["_songAuthorName"],"|||",dict["_levelAuthorName"])
		print(dict["_beatsPerMinute"],"|||", dict["_shuffle"],"|||", dict["_shufflePeriod"])
		print(dict["_previewStartTime"],"|||", dict["_previewDuration"])
		print(dict["_songFilename"],"|||", dict["_coverImageFilename"],"|||", dict["_environmentName"],"|||", dict.get("_allDirectionsEnvironmentName"))
		print(dict["_songTimeOffset"])
		print(dict.get("_customData")) # Note: can be non existing # NOTE: custom date isn't needed for loading the beatmap, more so for general info. (also don't think it is part of offical beatmaps).
	# load data from config file.
	bpm = dict["_beatsPerMinute"]
	songTimeOffset = dict["_songTimeOffset"]
	songlabel = get_song_info(dict["_songAuthorName"], dict["_songName"], dict["_levelAuthorName"]) # TODO: maybe move it out of here, to post processing with difficulity
	var difficultyBeatMaps = dict["_difficultyBeatmapSets"][0]["_difficultyBeatmaps"]
	var filename = ""
	for level in difficultyBeatMaps:
		if level["_difficulty"] == selected_diff:
			filename = level["_beatmapFilename"]
			songlabel += "\nDifficulty: " + level["_difficulty"] # TODO: maybe move it out of here, to post processing with pre-songlabel.
			noteJumpMovementSpeed = level["_noteJumpMovementSpeed"]
			noteJumpStartBeatOffset = level["_noteJumpStartBeatOffset"]
			break
	return filename

func load_beatmap(path : String):
	var childs = scroller.get_children() # remove old beatmap.
	for child in childs:
		scroller.remove_child(child)
		child.queue_free()
	scroller.transform.origin.z = 0 # reset position.
	
	var file = FileAccess.open(path,FileAccess.READ)
	var text = file.get_as_text()
	var dict = JSON.parse_string(text)
	var notes = dict["_notes"]
	for note in notes:
		var type = int(note["_type"])
		var cube : Node3D 
		if type == 0: # left(red) note
			cube = red_cube_prefeb.instantiate()
		elif type == 1: # right(blue) note
			cube = blue_cube_prefeb.instantiate()
		elif type == 3: # bomb note
			cube = boom_prefeb.instantiate()
		else: # unused
			continue
		scroller.add_child(cube)
		cube.name = "cube " + str(note["_time"])
		cube.transform.origin.z = -float(note["_time"]) * noteJumpMovementSpeed
		cube.transform.origin.x = int(note["_lineIndex"])
		cube.transform.origin.y = int(note["_lineLayer"])
		cube.transform.origin += placement_offset
		var angle : float = 0
		var direction = int(note["_cutDirection"])
		match direction:
			0:
				angle = 0
			1:
				angle = deg_to_rad(180)
			2:
				angle = deg_to_rad(90)
			3:
				angle = deg_to_rad(-90)
			4:
				angle = deg_to_rad(45)
			5:
				angle = deg_to_rad(-45)
			6:
				angle = deg_to_rad(45+90)
			7:
				angle = deg_to_rad(-45-90)
			8:
				angle = 0 # suppose to be 'any' direction cut.
		
		cube.transform.basis = cube.transform.basis.rotated(Vector3(0,0,1), angle)
	
	var obstacles = dict["_obstacles"]
	for obstacle in obstacles:
		var wall = wall_prefeb.instantiate()
		scroller.add_child(wall)
		wall.name = "wall " + str(obstacle["_time"])
		wall.transform.origin.z = (-float(obstacle["_time"])) * noteJumpMovementSpeed
		wall.transform.origin.x = int(obstacle["_lineIndex"])
		wall.transform.origin += placement_offset
		# TODO: crouth/full wall. ("_type")
		var meshinstance : MeshInstance3D = wall.get_node("MeshInstance3D")
		var collisionshape : CollisionShape3D = wall.get_node("CollisionShape3D")
		var mesh = BoxMesh.new()
		var shape = BoxShape3D.new()
		var size = Vector3(obstacle["_width"],4,obstacle["_duration"] * noteJumpMovementSpeed)
		mesh.size = size
		shape.size = size # TODO: some songs has negative wall sizes.
		meshinstance.mesh = mesh
		wall.transform.origin.z -= size.z/2.0 
		# TODO: not extacly fit, need to a better way to strech a shape to fit with blocks layout.
	song_time = notes[-1]["_time"] * 60 / bpm ; # in seconds.
	song_label_changed.emit(songlabel)
	show_menu.emit(false)
	# TODO: Loading sound file (dones't work with Godot 4.0.RC2)
	# var songStream = load_ogg(songPath)
	# $AudioStreamPlayer.stream = songStream

func _process(delta):
	if isplaying:
		time += delta
		if time > song_time:
			isplaying = false
			song_label_changed.emit("Song have ended.\nSelect next beatmap!")
			#get_tree().quit()
		else:
			time_label_changed.emit(get_time(time) + "/" + get_time(song_time))
		
		scroller.transform.origin.z += delta * noteJumpMovementSpeed * bpm/60
	if _left_controller != null and _right_controller != null:
		if _left_controller.get_input("by_button") or _right_controller.get_input("by_button"):
			isplaying = false
			show_menu.emit(true)
	else:
		print("no controllers? _left: ", _left_controller, " _right: ", _right_controller)
	
### Return given value (seconds) in a format of mins:secs with zero-filling to two digits at secs.
func get_time(value : float) -> String:
	var mins : int = int(value/60)
	var secs : int = int(value)%60
	return "%d:%02d" %[mins,secs]

### Return given song info in a string format.
func get_song_info(songAuthorName : String, songName : String, levelAuthorName) -> String:
	# TODO: add difficulty, but requires some redesign to the code.
	return "{} - {}\nMapper: {}".format([songAuthorName, songName, levelAuthorName], "{}")

### Return audiostream for given audio file, in our case .ogg file (called .egg in beatmaps)
func load_ogg(path) -> AudioStream:
	# TODO: didn't test if it actually works (it loads), 
	#		but there is missing data for OggPacketSequence which I am not sure how to load.
	#		There seems to be 'ResourceImporterOggVorbis' which maybe doesn't work or only C++ code.
	var file = FileAccess.open(path,FileAccess.READ)
	var sound = AudioStreamOggVorbis.new()
	var seq = OggPacketSequence.new()
	seq.packet_data = file.get_buffer(file.get_length())
	sound.packet_sequence = seq
	return sound

