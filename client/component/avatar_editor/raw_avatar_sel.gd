extends Control

export var grid_avatar_path:NodePath 

var grid_avatar

func _ready():
    grid_avatar=get_node(grid_avatar_path)
    var new_icon = WebSprite.new()
    new_icon.loadTexture(icon_root_url+info["id"]+"/main.jpg")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
