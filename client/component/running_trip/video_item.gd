extends Control

var icon_root_url="https://model-world.oss-cn-shanghai.aliyuncs.com/thumbnail/"
var download_mgr
var video_id
var download_info
var title
var upload_date
var country
var location
var file_size
var duration
var cover

func _ready():
    download_info=get_node("HBoxContainer/VBoxContainer/download_info")
    title=get_node("HBoxContainer/VBoxContainer/title")
    upload_date=get_node("HBoxContainer/VBoxContainer/HBoxContainer2/upload_date")
    country=get_node("HBoxContainer/VBoxContainer/HBoxContainer/country")
    location=get_node("HBoxContainer/VBoxContainer/HBoxContainer/location")
    file_size=get_node("HBoxContainer/VBoxContainer/HBoxContainer2/file_size")
    duration=get_node("HBoxContainer/VBoxContainer/HBoxContainer2/duration")
    cover=get_node("HBoxContainer/cover")
    download_mgr=get_node("/root/ui_root/download_mgr")    

func on_create(info):
    title.text=info["title"] 
    upload_date.text=info["upload_date"]
    country.text=info["country"]
    location.text=info["location"]
    file_size.text=str(int(info["file_size"]/1024/1024))+"MB"
    var duration_t =info["duration"]
    var h = int(duration_t/3600)
    var m = int((duration_t-h*3600)/60)
    duration.text=str(h)+":"+str(m)
    cover.loadTexture(icon_root_url+info["id"]+"/main.jpg")
    video_id=info["id"]
    var check_re=download_mgr.downloaded(video_id)
    if check_re=="downloaded":
        download_info.text="downloaded"
    else:
        download_info.text=""

func on_update_download_progress(download_info):
    self.download_info.text=download_info

func _on_cover_gui_input(event):
    if event is InputEventMouseButton and event.pressed and event.button_index==1:
        var check_re=download_mgr.downloaded(video_id)
        if check_re=="downloaded":
            var video_player = load("res://video_player.tscn").instance()
            video_player.set_video_id(video_id)
            get_node("/root/ui_root").add_child(video_player)
        elif check_re=="need_download":
            download_mgr.add_download_task(video_id, self)

func _on_rm_download_button_down():
    download_mgr.rm_download_task(video_id)


