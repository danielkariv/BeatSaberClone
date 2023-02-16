extends PanelContainer

var songItemPacked : PackedScene = preload("res://UI/SongList/SongItem.tscn")
signal song_selected(songPath)

func _ready():
	var songDirs = get_songs_lists()
	if len(songDirs) < 0:
		print("No songs found!")
		get_tree().close()
	var songCount = len(songDirs)
	# create list of songs.
	for songIter in songDirs:
		var songDict : Dictionary = load_beatmap_info(songIter) 
		# getting info into variables
		var songAuthorName = songDict["_songAuthorName"]
		var songName = songDict["_songName"]
		var coverImageFilename = songDict["_coverImageFilename"]
		var levelAuthorName = songDict["_levelAuthorName"]
		# create the new item and change prameters with given info.
		var songItem = songItemPacked.instantiate()
		
		songItem.get_node("HSplitContainer/VBoxContainer/SongName").text = songName
		songItem.get_node("HSplitContainer/VBoxContainer/AuthorName").text = songAuthorName
		songItem.get_node("HSplitContainer/VBoxContainer/LevelAuthorName").text = levelAuthorName
		var imagePath = songIter + "/" +coverImageFilename
		var img_tex = ImageTexture.create_from_image(Image.load_from_file(imagePath))
		# Can't load PNG, so we place placeholder image instead if null. (as for Godot 4.0RC1)
		if img_tex != null:
			songItem.get_node("HSplitContainer/Image").texture = img_tex
		
		# add it as child of list.
		$ScrollContainer/VBoxContainer.add_child(songItem)
		songItem.connect("pressed",_on_item_selected.bind(songItem,songIter))

func get_songs_lists(path : String = "user://beatmaps") -> Array:
	var user_dir = DirAccess.open(path)
	var songs_array : Array = []
	if user_dir:
			user_dir.list_dir_begin()
			var file_name = user_dir.get_next()
			while file_name != "":
				if user_dir.current_is_dir():
					songs_array.append(user_dir.get_current_dir() + "/" + file_name)
				file_name = user_dir.get_next()
	return songs_array;

func load_beatmap_info(beatmap_path : String) -> Dictionary:
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
	return dict

func _on_item_selected(songItem,songIter):
	song_selected.emit(songIter)
