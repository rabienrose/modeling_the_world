extends VBoxContainer

export var play_tex:Resource
export var stop_tex:Resource

var player:VideoPlayer
var play_btn:TextureButton

var slider_presssed=false
var seek_freeze_time=500
var seek_time=0
var last_seek_time=0
var last_seek_x=0
var pixel_per_sec=100
var pressed=false
var dragged=false
var map=null

func _ready():
    map=get_node("map/Viewport/map")
    player=get_node("video")
    play_btn=get_node("Control/GridContainer/play")
    var v_stream = VideoStreamTrip.new()
    var file_addr="user://video_cache/temp.webm"
    v_stream.set_file(file_addr)
    player.stream=v_stream

func _on_play_button_down():
    if not player.is_playing():
        player.play()
        play_btn.texture_normal=stop_tex
    else:
        if not player.is_paused():
            player.set_paused(true)
            play_btn.texture_normal=play_tex
        else:
            player.set_paused(false)
            play_btn.texture_normal=stop_tex

func _on_video_slider_gui_input(event):
    if event is InputEventMouseButton:
        if event.pressed:
            last_seek_x=0
            seek_time=0
            player.set_paused(true)
            play_btn.texture_normal=play_tex
            slider_presssed=true
        else:
            # print("seek pos: ",last_seek_x*0.1)
            # player.stream_position=player.stream_position+last_seek_x*0.1
            # seek_time=0
            # last_seek_x=0
            slider_presssed=false

    if event is InputEventMouseMotion:
        if slider_presssed:
            if seek_time>seek_freeze_time and abs(last_seek_x)>10:
                player.stream_position=player.stream_position+last_seek_x/pixel_per_sec
                seek_time=0
                last_seek_x=0
            var temp_c_time=OS.get_ticks_msec()
            var temp_d_time=temp_c_time-last_seek_time
            last_seek_time=temp_c_time
            seek_time=seek_time+temp_d_time
            last_seek_x=last_seek_x+event.relative.x

func _on_map_gui_input(event):
    if event is InputEventMouseButton:
        if event.pressed:
            pressed=true
            dragged=false
        else:
            if dragged:
                map.request_new_tile()
            pressed=false
    if event is InputEventMouseMotion:
        if pressed:
            dragged=true
            map.move_cam_pos(event.relative)


func _on_zoom_in_button_down():
    map.set_zoom_level(map.get_zoom_level()+1)

func _on_zoom_out_button_down():
    map.set_zoom_level(map.get_zoom_level()-1)

func _on_time_out_button_down():
    pass # Replace with function body.

func _on_time_in_button_down():
    pass # Replace with function body.
