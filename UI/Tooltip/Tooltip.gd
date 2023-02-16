extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$ButtonList/InfoButton.pressed.connect(on_infobutton_pressed)
	$ButtonList/LeaderboardButton.pressed.connect(on_leaderboardbutton_pressed)
	$ButtonList/FolderButton.pressed.connect(on_folderbutton_pressed)
	$ButtonList/SettingsButton.pressed.connect(on_settingsbutton_pressed)
	$ButtonList/ExitButton.pressed.connect(on_exitbutton_pressed)
	
	$ButtonList/InfoButton.mouse_entered.connect(on_mouse_entered.bind("Player information"))
	$ButtonList/InfoButton.mouse_exited.connect(on_mouse_exited)
	$ButtonList/LeaderboardButton.mouse_entered.connect(on_mouse_entered.bind("Global Leaderboard"))
	$ButtonList/LeaderboardButton.mouse_exited.connect(on_mouse_exited)
	$ButtonList/FolderButton.mouse_entered.connect(on_mouse_entered.bind("Open custom data folder"))
	$ButtonList/FolderButton.mouse_exited.connect(on_mouse_exited)
	$ButtonList/SettingsButton.mouse_entered.connect(on_mouse_entered.bind("Settings"))
	$ButtonList/SettingsButton.mouse_exited.connect(on_mouse_exited)
	$ButtonList/ExitButton.mouse_entered.connect(on_mouse_entered.bind("Exit"))
	$ButtonList/ExitButton.mouse_exited.connect(on_mouse_exited)
	pass # Replace with function body.

func on_infobutton_pressed():
	print("info button pressed")
	# not implemented yet

func on_leaderboardbutton_pressed():
	print("leaderboard button pressed")
	# not implemented yet

func on_folderbutton_pressed():
	print("folder button pressed")
	OS.shell_open("file://"+OS.get_user_data_dir())

func on_settingsbutton_pressed():
	print("settings button pressed")
	# not implemented yet

func on_exitbutton_pressed():
	print("exit button pressed")
	get_tree().quit()

func on_mouse_entered(text):
	$TooltipLabel.text = text

func on_mouse_exited():
	$TooltipLabel.text = ""
