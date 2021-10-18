extends Node2D

var task_list={}
var cache_folder="user://video_cache/"
var cur_thread=null
var thread
var mutex
var cur_downloading_id
var stop_download_flag=false

func _ready():
    thread = Thread.new()
    mutex = Mutex.new()
    thread.start(self, "update_thread")

func remove_task_from_list(video_id):
    mutex.lock()
    if video_id in task_list:
        task_list.erase(video_id)
    mutex.unlock()

func check_dir(addr):
    var dir = Directory.new()
    if not dir.dir_exists(addr):
        dir.make_dir(addr);

func update_thread(param):
    check_dir(cache_folder)
    var s_time=OS.get_ticks_msec()
    while true:
        var has_task=false
        var video_id = ""
        var ui_obj=null
        if task_list.size()>0:
            for v_id in task_list:
                video_id=v_id
                ui_obj=task_list[v_id]
                break
            has_task=true
        if has_task:
            var err = 0
            var http = HTTPClient.new() 
            err = http.connect_to_host("model-world.oss-cn-shanghai.aliyuncs.com", 80)
            assert(err == OK)
            while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
                http.poll()
                OS.delay_msec(500)
            if http.get_status() != HTTPClient.STATUS_CONNECTED:
                print("http init failed")
                return
            var headers = [
                "User-Agent: Pirulo/1.0 (Godot)",
                "Accept: */*"
            ]
            err = http.request(HTTPClient.METHOD_GET, "/video/"+video_id+"/main.webm", headers) # Request a page from the site (this one was chunked..)
            if err != OK:
                ui_obj.on_update_download_progress("failed")
                remove_task_from_list(video_id)
                continue

            while http.get_status() == HTTPClient.STATUS_REQUESTING:
                http.poll()
                OS.delay_msec(500)
            if http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED:
                headers = http.get_response_headers_as_dictionary()
                var bl=-1
                if http.is_response_chunked():
                    pass
                else:
                    bl = http.get_response_body_length()
                var rb = PoolByteArray()
                var last_rb_size=0
                cur_downloading_id=video_id
                while http.get_status() == HTTPClient.STATUS_BODY:
                    if stop_download_flag:
                        stop_download_flag=false
                        break
                    http.poll()
                    var chunk = http.read_response_body_chunk()
                    if chunk.size() == 0:
                        pass
                    else:
                        rb = rb + chunk
                        var c_time=OS.get_ticks_msec()
                        if c_time-s_time>1*1000:
                            var d_rate=str(int((rb.size()-last_rb_size)/(c_time-s_time)*1000/1024))+"K/s"
                            last_rb_size=rb.size()
                            s_time=c_time
                            if bl>0:
                                ui_obj.on_update_download_progress(str(int(rb.size()/float(bl)*100))+"%    "+d_rate)
                            else:
                                ui_obj.on_update_download_progress(str(int(last_rb_size/1024/1024))+"M    "+d_rate)
                var f=File.new()
                f.open("user://"+cache_folder+video_id+".webm",File.WRITE)
                f.store_buffer(rb)
                f.close()
                ui_obj.on_update_download_progress("downloaded")
                cur_downloading_id=""
            else:
                ui_obj.on_update_download_progress("failed")
                remove_task_from_list(video_id)
                continue
            ui_obj.on_update_download_progress("Downloaded")
            remove_task_from_list(video_id)
        else:
            OS.delay_msec(1000)
            if stop_download_flag:
                stop_download_flag=false


func add_download_task(video_id, ui_obj):
    if video_id in task_list:
        return
    mutex.lock()
    task_list[video_id]=ui_obj
    mutex.unlock()
    ui_obj.on_update_download_progress("Pending")

func downloaded(video_id):
    var file2Check = File.new()
    var doFileExists = file2Check.file_exists(cache_folder+"video_id"+".webm")
    if doFileExists:
        return "downloaded"
    else:
        if video_id in task_list:
            return "downloading"
        else:
            return "need_download"

func rm_download_task(video_id):
    if video_id in task_list:
        task_list[video_id].on_update_download_progress("")
        remove_task_from_list(video_id)
        if cur_downloading_id==video_id:
            stop_download_flag=true
    var file2Check = File.new()
    var temp_addr=cache_folder+"video_id"+".webm"
    var doFileExists = file2Check.file_exists(temp_addr)
    if doFileExists:
        var dir = Directory.new()
        dir.remove(temp_addr)
