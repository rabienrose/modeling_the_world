extends Control

var icon_root_url="https://model-world.oss-cn-shanghai.aliyuncs.com/thumbnail/"
var download_mgr
var video_id

func _ready():
    download_mgr=get_node("/root/ui_root/download_mgr")

func set_video_info(info):
    get_node("title").text=info["title"]
    get_node("upload_date").text=info["upload_date"]
    get_node("country").text=info["country"]
    get_node("location").text=info["location"]
    get_node("file_size").text=str(int(info["file_size"]/1024/1024))+"MB"
    var duration =info["duration"]
    var h = int(duration/3600)
    var m = int((duration-h*3600)/60)
    get_node("duration").text=str(h)+":"+str(m)
    get_node("cover").url=icon_root_url+info["id"]+"/main.jpg"
    get_node("download_info").text=""
    video_id=info["id"]

func on_update_download_progress(download_info):
    get_node("download_info").text=download_info

func _on_cover_gui_input(event):
    if event is InputEventMouseButton and event.pressed and event.button_index==1:
        var check_re=download_mgr.downloaded(video_id)
        if check_re=="downloaded":
            var video_player = load("res://video_player.tscn").instance()
            video_player.set_video_id(video_id, self)
            get_node("/root/ui_root").add_child(video_player)
        elif check_re=="need_download":
            download_mgr.add_download_task(video_id, self)

func _on_rm_download_button_down():
    download_mgr.rm_download_task(video_id)


