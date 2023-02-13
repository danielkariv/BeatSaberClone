extends Control
@export var _gameManager : Node
# Called when the node enters the scene tree for the first time.
func _ready():
	$SongList.connect("song_selected",$SongPreview._on_song_selected)
	if _gameManager.has_method("on_play_beatmap"):
		$SongPreview.connect("play_pressed",_gameManager.on_play_beatmap)
	pass # Replace with function body.
