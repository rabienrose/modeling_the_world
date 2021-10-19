extends Control

var video_id="BXhAEBSY1wc"
var player

func _ready():
    OS.screen_orientation=OS.SCREEN_ORIENTATION_LANDSCAPE
#    player=get_node("VideoPlayer")
#    var v_stream = VideoStreamTheora.new()
#    var file_addr="user://video_cache/"+video_id+".ogv"
#    v_stream.set_file(file_addr)
#    player.stream=v_stream
#    player.play()

func set_video_id(v_id):
    video_id=v_id
    
