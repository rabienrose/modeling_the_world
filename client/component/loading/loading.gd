extends Control

export var login_scene:Resource
export var main_scene:Resource

var token_file="user://token.txt"

func _ready():
    var file=File.new()
    if file.file_exists(token_file):
        file.open(token_file, File.READ)
        Global.token=file.get_as_text()
        get_tree().change_scene_to(main_scene)
    else:
        get_tree().change_scene_to(login_scene)
