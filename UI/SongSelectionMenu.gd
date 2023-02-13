extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	$SongList.connect("song_selected",$SongPreview._on_song_selected)
	pass # Replace with function body.
