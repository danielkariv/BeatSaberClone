extends Node3D

@export var red_cube_prefeb : PackedScene
@export var blue_cube_prefeb : PackedScene
@export var boom_prefeb : PackedScene
@export var wall_prefeb : PackedScene

var interface : XRInterface
var scroller : Node3D # loaded at _ready().
var placement_offset : Vector3 = Vector3(-1.5,0.5,0)
# TODO: (It is more of optimization/cleanup)
#		remove all this data into a something less global, 
#		it needs to be loaded locally and push to load functions, not just stay around.
var noteJumpMovementSpeed : int
var noteJumpStartBeatOffset : int # NOTE: not used yet.
var bpm : int
var song_time : int
var songTimeOffset : int # NOTE: not used yet (don't have a map with it).
var songlabel : String
var songPath : String

var time : float = 0
var isplaying  = false
var debug := true
# Called when the node enters the scene tree for the first time.
func _ready():
	# load VR interface or report we couldn't.
	interface = XRServer.find_interface("OpenXR")
	if interface and interface.is_initialized():
		print("OpenXR initialised successfully")
		
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialised, please check if your headset is connected")
	
	scroller = $Scroller
	
	# test open, make and load folders from user directory.
	if debug:
		# NOTE: just check if I can open the folder and add folders
		# NOTE: should maybe make the mods/maps folders a custom path that users can change.
		# 		maybe even create a array of folders to read from (so you could split between different websites).
		OS.shell_open("file://"+OS.get_user_data_dir())
		# try to add folders and find them.
		var user_dir = DirAccess.open("user://")
		user_dir.make_dir("beatmaps")
		user_dir.make_dir("avatars")
		user_dir.make_dir("swords")
		if user_dir:
			user_dir.list_dir_begin()
			var file_name = user_dir.get_next()
			while file_name != "":
				if user_dir.current_is_dir():
					print("Found directory: " + file_name)
				else:
					print("Found file: " + file_name)
				file_name = user_dir.get_next()
	
	process_new_beatmap()

func process_new_beatmap():
	var current = Time.get_unix_time_from_system()
	
	# loads songs_lists -> beatmap_info -> select difficulty(level) -> load difficulty(level) beatmap.
	var song_dirs = get_songs_lists()
	if len(song_dirs) <= 0:
		print("No songs found!")
		get_tree().close() # TODO: doesn't work, crashing for now.
	if debug:
		print(song_dirs)
	var rng = RandomNumberGenerator.new() # TODO: used for selection right now but  switch with UI interface.
	
	var songSelector = rng.randi_range(0,len(song_dirs)-1)
	
	var levels = load_beatmap_info(song_dirs[songSelector]) # TODO: add ui selector.
	
	var levelSelector = rng.randi_range(0,len(levels)-1)
	
	var level_filename = load_difficulty(levels[levelSelector]) # TODO: add ui selector.
	
	load_beatmap(song_dirs[songSelector] + "/" +level_filename)
	
	var took = Time.get_unix_time_from_system() - current
	# Debug printing
	if debug:
		print("Took ", took, " seconds to load beat map")

func get_songs_lists(path : String = "user://beatmaps") -> Array:
	var user_dir = DirAccess.open(path)
	var songs_array : Array = []
	if user_dir:
			user_dir.list_dir_begin()
			var file_name = user_dir.get_next()
			while file_name != "":
				if user_dir.current_is_dir():
					print("Found directory: " + file_name)
					songs_array.append(user_dir.get_current_dir() + "/" + file_name)
				else:
					print("Found file: " + file_name)
				file_name = user_dir.get_next()
	return songs_array;

func load_beatmap_info(beatmap_path : String) -> Array:
	var file = FileAccess.open(beatmap_path + "/Info.dat", FileAccess.READ)
	var text = file.get_as_text(true)
	var dict = JSON.parse_string(text)
	# Debug printing
	if debug: 
		print(dict["_songName"],"|||",dict["_songSubName"],"|||",dict["_songAuthorName"],"|||",dict["_levelAuthorName"])
		print(dict["_beatsPerMinute"],"|||", dict["_shuffle"],"|||", dict["_shufflePeriod"])
		print(dict["_previewStartTime"],"|||", dict["_previewDuration"])
		print(dict["_songFilename"],"|||", dict["_coverImageFilename"],"|||", dict["_environmentName"],"|||", dict.get("_allDirectionsEnvironmentName"))
		print(dict["_songTimeOffset"])
		print(dict.get("_customData")) # Note: can be non existing # NOTE: custom date isn't needed for loading the beatmap, more so for general info. (also don't think it is part of offical beatmaps).
	# load data from config file.
	songPath = beatmap_path + "/" + dict["_songFilename"]
	bpm = dict["_beatsPerMinute"]
	songTimeOffset = dict["_songTimeOffset"]
	songlabel = get_song_info(dict["_songAuthorName"], dict["_songName"], dict["_levelAuthorName"]) # TODO: maybe move it out of here, to post processing with difficulity
	var difficultyBeatMaps = dict["_difficultyBeatmapSets"][0]["_difficultyBeatmaps"]
	return difficultyBeatMaps

func load_difficulty(levelinfo):
	var filename = levelinfo["_beatmapFilename"]
	songlabel += "\nDifficulty: " + levelinfo["_difficulty"] # TODO: maybe move it out of here, to post processing with pre-songlabel.
	noteJumpMovementSpeed = levelinfo["_noteJumpMovementSpeed"]
	noteJumpStartBeatOffset = levelinfo["_noteJumpStartBeatOffset"]
	# I think this is it. 
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
	$SongLabel.text = songlabel
	var songStream = load_ogg(songPath)
	$AudioStreamPlayer.stream = songStream
	

func _process(delta):
	if isplaying:
		time += delta
		if time > song_time:
			get_tree().quit()
		else:
			$TimeLabel.text = get_time(time) + "/" + get_time(song_time)
		
		scroller.transform.origin.z += delta * noteJumpMovementSpeed * bpm/60

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

func on_play_beatmap(currentSongPath,diff_selected):
	print("Testing in game manager", currentSongPath,diff_selected)
	# TODO: 13/02/2023, Can't test it yet as we don't have pointers to use the menus, not clear if we do get currentSongPath, and diff_selected.
	#		Also, some of the code here in this script isn't needed anymore when we got the menu selection working.
	pass
