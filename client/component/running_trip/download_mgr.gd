extends Node2D

var task_list={}
var cache_folder="user://video_cache/"
var file_cache_addr=cache_folder+"temp/"
var cur_thread=null
var thread
var mutex
var cur_downloading_id
var stop_download_flag=false
var split_file_size=10000000

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

func get_last_download_posi():
    var dir = Directory.new()
    var v_id=""
    var start_file_id=0
    var size_file_posi=0
    if not dir.dir_exists(file_cache_addr):
        dir.make_dir(file_cache_addr)
    else:
        dir.open(file_cache_addr)
        dir.list_dir_begin()
        start_file_id=0
        while true:
            var filename = dir.get_next()
            if filename=="":
                break
            if filename.begins_with("temp"):
                start_file_id=start_file_id+1
                var tmp_str_vec = filename.split("_")
                v_id=tmp_str_vec[1]
                var t_f=File.new()
                t_f.open(file_cache_addr+filename,File.READ)
                var t_f_size=t_f.get_len()
                t_f.close()
                size_file_posi=size_file_posi+t_f_size
        dir.list_dir_end()
    return [v_id, start_file_id, size_file_posi]

func clear_download_temp_folder():
    var dir = Directory.new()
    if dir.dir_exists(file_cache_addr):
        dir.open(file_cache_addr)
        dir.list_dir_begin()
        while true:
            var filename = dir.get_next()
            if filename=="":
                break
            dir.remove(file_cache_addr+filename)
        dir.list_dir_end()

func final_download():
    var dir = Directory.new()
    dir.open(file_cache_addr)
    dir.list_dir_begin()
    var max_id=-1
    var file_count=0
    var video_id=""
    var b_all=true
    while true:
        var filename = dir.get_next()
        if filename=="":
            break
        if filename.begins_with("temp"):
            var tmp_str_vec = filename.split("_")
            var video_id_t=tmp_str_vec[1]
            if video_id=="":
                video_id=video_id_t
            else:
                if video_id!=video_id_t:
                    b_all=false
                    break
            var file_id=int(tmp_str_vec[2])
            file_count=file_count+1
            if file_id>max_id or max_id==-1:
                max_id=file_id
    dir.list_dir_end()
    if file_count!=max_id+1:
        b_all=false
    if b_all:
        var final_file=File.new()
        final_file.open(cache_folder+"/"+video_id+".webm", File.WRITE)
        for i in range(max_id+1):
            var temp_file=File.new()
            var tmp_filename=file_cache_addr+"temp_"+video_id+"_"+str(i)+".webm"
            temp_file.open(tmp_filename, File.READ)
            final_file.store_buffer(temp_file.get_buffer(temp_file.get_len()))
            temp_file.close()
        final_file.close()        
    clear_download_temp_folder()

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
            var re = get_last_download_posi()
            var start_download_posi=0
            var start_temp_id=0
            if re[0]!=video_id:
                clear_download_temp_folder()
            else:
                start_download_posi=re[2]
                start_temp_id=re[1]
            var headers_req = [
                "User-Agent: Pirulo/1.0 (Godot)",
                "Accept: */*",
                "Range: bytes="+str(start_download_posi)+"-"
            ]
            err = http.request(HTTPClient.METHOD_GET, "/video/"+video_id+"/main.webm", headers_req)
            if err != OK:
                ui_obj.on_update_download_progress("failed")
                remove_task_from_list(video_id)
                continue

            while http.get_status() == HTTPClient.STATUS_REQUESTING:
                http.poll()
                OS.delay_msec(500)
            if http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED:
                var headers_res = http.get_response_headers_as_dictionary()
                var bl=-1
                if http.is_response_chunked():
                    pass
                else:
                    bl = http.get_response_body_length()
                var last_rb_size=0
                cur_downloading_id=start_temp_id
                stop_download_flag=false
                var f=File.new()
                var file_addr=cache_folder+"temp.webm"
                f.open(file_addr,File.WRITE)
                var download_size=0
                while http.get_status() == HTTPClient.STATUS_BODY:
                    if stop_download_flag:
                        break
                    http.poll()
                    var chunk = http.read_response_body_chunk()
                    if chunk.size() == 0:
                        pass
                    else:
                        f.store_buffer(chunk)
                        if f.get_len()>split_file_size:
                            f.close()
                            var dir = Directory.new()
                            var temp_file_name="temp_"+str(video_id)+"_"+str(cur_downloading_id)+".webm"
                            dir.copy(cache_folder+"temp.webm", file_cache_addr+temp_file_name)
                            cur_downloading_id=cur_downloading_id+1
                            f=File.new()
                            f.open(file_addr,File.WRITE)
                        download_size=download_size+chunk.size()
                        var c_time=OS.get_ticks_msec()
                        if c_time-s_time>1*1000:
                            var raw_speed=(download_size-last_rb_size)/(c_time-s_time)*1000
                            var d_rate=str(int(raw_speed/1024))+"K/s"
                            last_rb_size=download_size
                            s_time=c_time
                            if bl>0:
                                var need_time = (bl-last_rb_size)/raw_speed
                                var h = int(need_time/3600)
                                var m = int((need_time-h*3600)/60)
                                var s = int(need_time-h*3600-m*60)
                                var time_str=str(h)+":"+str(m)+":"+str(s)
                                ui_obj.on_update_download_progress(str(int(download_size/float(bl)*100))+"%  "+d_rate+"  "+time_str)
                            else:
                                ui_obj.on_update_download_progress(str(int(last_rb_size/1024/1024))+"M  "+d_rate)
                f.close()
                var dir = Directory.new()
                var temp_file_name="temp_"+str(video_id)+"_"+str(cur_downloading_id)+".webm"
                dir.copy(cache_folder+"temp.webm", file_cache_addr+temp_file_name)
                if stop_download_flag==false:
                    re = final_download()
                    if re==false:
                        ui_obj.on_update_download_progress("failed")
                    else:
                        ui_obj.on_update_download_progress("downloaded")
                    remove_task_from_list(video_id)
                else:
                    ui_obj.on_update_download_progress("canceled")
                cur_downloading_id=""
            else:
                ui_obj.on_update_download_progress("failed")
                remove_task_from_list(video_id)
        else:
            OS.delay_msec(1000)

func add_download_task(video_id, ui_obj):
    if video_id in task_list:
        return
    mutex.lock()
    task_list[video_id]=ui_obj
    mutex.unlock()
    ui_obj.on_update_download_progress("Pending")

func downloaded(video_id):
    var file2Check = File.new()
    var doFileExists = file2Check.file_exists(cache_folder+video_id+".webm")
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
    var temp_addr=cache_folder+video_id+".webm"
    var doFileExists = file2Check.file_exists(temp_addr)
    if doFileExists:
        var dir = Directory.new()
        dir.remove(temp_addr)

func load_download_task_list():
    pass
