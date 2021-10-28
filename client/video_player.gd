extends Control

var video_id="BXhAEBSY1wc"
var player

func _ready():
    OS.screen_orientation=OS.SCREEN_ORIENTATION_LANDSCAPE
#    get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D,  SceneTree.STRETCH_ASPECT_KEEP, Vector2(800,500),1)
    player=get_node("VideoPlayer")
    var v_stream = VideoStreamWebm.new()
    var file_addr="user://video_cache/"+video_id+".webm"
    v_stream.set_file(file_addr)
    player.stream=v_stream
    player.play()

func set_video_id(v_id):
    video_id=v_id
    
