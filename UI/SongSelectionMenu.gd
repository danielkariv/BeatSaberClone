extends Control

func _ready():
	$SongList.connect("song_selected",$SongPreview._on_song_selected)
	$SongPreview.connect("play_pressed", get_node("/root/GameManager").on_play_beatmap) # note: $GameManager doesn't work, so get_node is used instead.
