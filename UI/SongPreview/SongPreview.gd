extends PanelContainer

var btn_easy : Button
var btn_normal : Button
var btn_hard : Button
var btn_expert : Button
var btn_expertplus : Button
var btn_play : Button

var currentSongPath = null
var diff_selected = null

signal play_pressed(songPath,diff)

func _ready():
	get_node("MarginContainer").visible = false
	btn_easy = get_node("MarginContainer/VBoxContainer/HBoxContainer/EasyButton")
	btn_normal = get_node("MarginContainer/VBoxContainer/HBoxContainer/NormalButton")
	btn_hard = get_node("MarginContainer/VBoxContainer/HBoxContainer/HardButton")
	btn_expert = get_node("MarginContainer/VBoxContainer/HBoxContainer/ExpertButton")
	btn_expertplus = get_node("MarginContainer/VBoxContainer/HBoxContainer/ExpertPlusButton")
	btn_play = get_node("MarginContainer/VBoxContainer/PlayButton")
	
	btn_easy.pressed.connect(on_difficulty_selected.bind('Easy'))
	btn_normal.pressed.connect(on_difficulty_selected.bind('Normal'))
	btn_hard.pressed.connect(on_difficulty_selected.bind('Hard'))
	btn_expert.pressed.connect(on_difficulty_selected.bind('Expert'))
	btn_expertplus.pressed.connect(on_difficulty_selected.bind('ExpertPlus'))
	btn_play.pressed.connect(on_play_pressed)

func _on_song_selected(songPath):
	get_node("MarginContainer").visible = true
	load_beatmap_info(songPath)
	pass

func load_beatmap_info(beatmap_path : String):
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
		print(dict["_customData"]) # NOTE: doesn't exist in some songs. # NOTE: custom date isn't needed for loading the beatmap, more so for general info. (also don't think it is part of offical beatmaps).
	# load data from config file.
	get_node("MarginContainer/VBoxContainer/HSplitContainer/VBoxContainer/SongName").text = dict["_songName"]
	get_node("MarginContainer/VBoxContainer/HSplitContainer/VBoxContainer/Author").text = dict["_songAuthorName"]
	get_node("MarginContainer/VBoxContainer/HSplitContainer/VBoxContainer/LevelAuthor").text =  dict["_levelAuthorName"]
	get_node("MarginContainer/VBoxContainer/HSplitContainer/VBoxContainer2/BPM").text = str(dict["_beatsPerMinute"])
	var imagePath = beatmap_path + "/" + dict["_coverImageFilename"]
	var img_tex = ImageTexture.create_from_image(Image.load_from_file(imagePath))
	# Can't load PNG, so we place placeholder image instead if null. (as for Godot 4.0RC1)
	if img_tex != null:
		get_node("MarginContainer/VBoxContainer/MarginContainer/TextureRect").texture = img_tex
	else:
		get_node("MarginContainer/VBoxContainer/MarginContainer/TextureRect").texture = load("res://assets/missing-cover.png")
	
	var difficultyBeatMaps = dict["_difficultyBeatmapSets"][0]["_difficultyBeatmaps"]
	# disable all button
	btn_easy.disabled = true
	btn_normal.disabled = true
	btn_hard.disabled = true
	btn_expert.disabled = true
	btn_expertplus.disabled = true
	
	btn_play.disabled = true
	diff_selected = null
	
	# turn on only difficulty maps that exist.
	for diff in difficultyBeatMaps:
		if diff["_difficulty"] == 'Easy':
			btn_easy.disabled = false
		if diff["_difficulty"] == 'Normal':
			btn_normal.disabled = false
		if diff["_difficulty"] == 'Hard':
			btn_hard.disabled = false
		if diff["_difficulty"] == 'Expert':
			btn_expert.disabled = false
		if diff["_difficulty"] == 'ExpertPlus':
			btn_expertplus.disabled = false
		
	
	currentSongPath = beatmap_path
func on_difficulty_selected(diff):
	diff_selected = diff
	btn_play.disabled = false
	# TODO: add here current score for this level + diff. 

func on_play_pressed():
	play_pressed.emit(currentSongPath,diff_selected)
