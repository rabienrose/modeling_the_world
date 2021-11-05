extends Control

export var avatar_sprite_path:NodePath
export var curser_path:NodePath
export var popup_menu_path:NodePath 
export var group_name_path:NodePath 
export var pattern_name_path:NodePath 
export var frame_label_path:NodePath 
export var auto_sel_btn_path:NodePath 

var raw_image_tex
var sel_image
var sel_image_tex
var avatar_sprite:TextureRect
var w
var h
var w_p
var h_p
var w_t
var h_t
var tile_w=3
var tile_h=3
var pixel_p_pixel
var color_group={}
var color_dict={}
var image_list=[]
var current_frame=1
var current_group_name="hair"
var max_frame_count
var curser
var mouse_clicked=false
var mouse_drag=false
var popup_menu:PopupMenu
var group_name_label:Label
var frame_label:Label
var pattern_label:Label
var auto_sel_btn:CheckBox
var pattern_info
var group_name_by_id=[]
var group_id_by_name={}
var saving=false
var alert_ui

signal get_pattern_data(data,pattern_name)


func _ready():
    if Global.current_edit_pattern=="":
        return
    avatar_sprite=get_node(avatar_sprite_path)
    curser=get_node(curser_path)
    popup_menu=get_node(popup_menu_path)
    group_name_label=get_node(group_name_path)
    pattern_label=get_node(pattern_name_path)
    frame_label=get_node(frame_label_path)
    auto_sel_btn=get_node(auto_sel_btn_path)
    alert_ui=get_node("alert")
    connect("get_pattern_data", self, "on_get_pattern_data")
    Utils.download_small_file("get_pattern?pattern_name="+Global.current_edit_pattern,"get_pattern_data",self,Global.current_edit_pattern)

func on_get_pattern_data(data, pattern_name):
    var spb = StreamPeerBuffer.new()
    spb.data_array = data.subarray(0,3)
    var png_len = spb.get_32() 
    spb.data_array = data.subarray(4,7)
    var json_len = spb.get_32() 
    var png_b=data.subarray(8,png_len+8-1)
    var json_compress=data.subarray(png_len+8,data.size()-1)
    var json_b = json_compress.decompress(json_len,File.COMPRESSION_GZIP)
    var json_s = json_b.get_string_from_utf8()
    pattern_info = JSON.parse(json_s).result
    w=avatar_sprite.rect_size.x
    h=avatar_sprite.rect_size.y
    w_p=pattern_info["image_size"][0]
    h_p=pattern_info["image_size"][1]
    w_t=pattern_info["tile_size"][0]
    h_t=pattern_info["tile_size"][1]
    pixel_p_pixel=int(w/w_p)
    var pattern_img=Image.new()
    pattern_img.load_png_from_buffer(png_b)
    for j in range(w_t):
        for i in range(h_t):
            var tmp_image = Image.new()
            tmp_image.create(w_p, h_p,false,Image.FORMAT_RGBA8)
            var src_rect=Rect2(i*w_p, j*h_p, w_p, h_p )
            tmp_image.blit_rect(pattern_img, src_rect, Vector2(0,0))
            image_list.append(tmp_image)
    max_frame_count=w_t*h_t
    current_frame=1
    current_group_name="hair"
    pattern_label.text=pattern_info["raw_name"]
    popup_menu.connect("index_pressed", self, "on_chosse_group")
    show_frame(current_frame)

func set_pixel(posi, b_range):
    var cell_x= floor(posi.x/pixel_p_pixel)
    var cell_y= floor(posi.y/pixel_p_pixel)
    var pos_cell=Vector2(cell_x, cell_y)
    sel_image.lock()
    var b_set=true
    var sel_temp = sel_image.get_pixel(cell_x, cell_y).r
    if sel_temp>0.5:
        b_set=false
    sel_image.unlock()
    if not pos_cell in color_dict:
        return
    var color = color_dict[pos_cell]
    var all_temp_pixel=[]
    if b_range:
        all_temp_pixel = color_group[color]
    else:
        all_temp_pixel=[pos_cell]
    sel_image.lock()
    var sel_p_list = pattern_info["groups"][current_frame][current_group_name]
    var remove_mask={}
    for p in all_temp_pixel:
        if b_set:
            sel_p_list.append(vec2_2_pos_id(p))
            sel_image.set_pixel(p.x,p.y,Color(1,0,0,0))
        else:
            remove_mask[vec2_2_pos_id(p)]=1
            sel_image.set_pixel(p.x,p.y,Color(0,0,0,0))
    sel_image.unlock()
    if b_set==false:
        var tmp_new_sel_p_list=[]
        for p in sel_p_list:
            if not p in remove_mask:
                tmp_new_sel_p_list.append(p)
        pattern_info["groups"][current_frame][current_group_name]=tmp_new_sel_p_list
    update_tex(true)

func update_tex(only_sel):
    if not only_sel:
        raw_image_tex.set_data(image_list[current_frame])
        avatar_sprite.material.set_shader_param("raw_texture", raw_image_tex)
    sel_image_tex.set_data(sel_image)
    avatar_sprite.material.set_shader_param("sel_texture", sel_image_tex)

func _on_avatar_gui_input(event):
    if event is InputEventMouseButton:
        if event.pressed:
            mouse_clicked=true
            mouse_drag=false
        else:
            if mouse_drag==false:
                set_pixel(event.position, auto_sel_btn.pressed)
            mouse_clicked=false
    if event is InputEventMouseMotion:
        if mouse_clicked:
            mouse_drag=true
            var tmp_posi=curser.position+event.relative
            if tmp_posi.x<0:
                tmp_posi.x=0;
            if tmp_posi.y<0:
                tmp_posi.y=0; 
            if tmp_posi.x>w:
                tmp_posi.x=w-1;
            if tmp_posi.y>h-1:
                tmp_posi.y=h-1;
            curser.position=tmp_posi
            
func _on_push_button_down():
    set_pixel(curser.position, auto_sel_btn.pressed)

func _on_sel_button_down():
    popup_menu.clear()
    for group_name in pattern_info["groups"][current_frame]:
        group_name_by_id.append(group_name)
        var px_count_by_group=len(pattern_info["groups"][current_frame][group_name])
        popup_menu.add_check_item(group_name+"("+str(px_count_by_group)+")")
        group_id_by_name[group_name]=popup_menu.get_item_count()-1  
    popup_menu.set_item_checked(group_id_by_name[current_group_name], true)
    popup_menu.popup(Rect2(200,200,800,600))

func on_chosse_group(id):
    var t_group_name= group_name_by_id[id]
    current_group_name=t_group_name
    show_selection_by_info(t_group_name)

func _on_save_button_down():
    if saving:
        return
    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.connect("request_completed",self,"save_pattern_done")
    var request_data={"name":pattern_label.text, "info":JSON.print(pattern_info)}
    var request_data_str = JSON.print(request_data)
    var headers = ["Content-Type: application/json"]
    if http_request.request(Global.root_url+"/update_pattern",headers,false,HTTPClient.METHOD_POST,request_data_str)>=0:
        saving=true

func save_pattern_done(result, response_code, headers, body):
    saving=false
    var re_info = JSON.parse(body.get_string_from_utf8()).result
    if re_info["re"]=="ok":
        alert_ui.set_alert_text("保存成功")
        alert_ui.popup_centered_minsize()

func pos_id_2_vec2(pos_id):
    return Vector2(pos_id - floor(pos_id/w_p)*w_p, floor(pos_id/w_p))

func vec2_2_pos_id(pos):
    return pos.y*w_p+pos.x

func show_selection_by_info(group_name_t):
    group_name_label.text=group_name_t
    var selection_list = pattern_info["groups"][current_frame][group_name_t]
    sel_image.fill(Color(0,0,0,0))
    sel_image.lock()
    for pos_id in selection_list:
        var pos = pos_id_2_vec2(pos_id)
        sel_image.set_pixel(pos.x,pos.y,Color(1,0,0,0))
    sel_image.unlock()
    update_tex(true)

func show_frame(frame_id):
    var raw_image=image_list[frame_id]
    raw_image.lock()
    color_group={}
    color_dict={}
    for i in range(w_p):
        for j in range(h_p):
            var c_tmp=raw_image.get_pixel(i,j)
            var color_str = c_tmp.to_html(false)
            if c_tmp.a<0.01: 
                continue
            if not color_str in color_group:
                color_group[color_str]=[]
            color_group[color_str].append(Vector2(i,j))
            color_dict[Vector2(i,j)]=color_str
    raw_image.unlock()
    frame_label.text=str(frame_id)
    raw_image_tex=ImageTexture.new()
    raw_image_tex.create_from_image(raw_image,0)
    sel_image=Image.new()
    sel_image.create(w_p, h_p,false, Image.FORMAT_R8)
    sel_image_tex=ImageTexture.new()
    sel_image_tex.create_from_image(sel_image,0)
    update_tex(false)
    show_selection_by_info(current_group_name)

func _on_next_button_down():
    current_frame=current_frame+1
    if current_frame>=max_frame_count:
        current_frame=max_frame_count-1
        return
    show_frame(current_frame)

func _on_prev_button_down():
    current_frame=current_frame-1
    if current_frame<0:
        current_frame=0
        return
    show_frame(current_frame)

func _on_reset_button_down():
    if current_frame==1:
        return
    var frame_1_info=pattern_info["groups"][1]
    var frame_c_info=pattern_info["groups"][current_frame]
    image_list[1].lock()
    var raw_image=image_list[current_frame]
    raw_image.lock()
    for group_name in frame_1_info:
        var sel_color_list={}
        if len(frame_1_info[group_name])==0:
            continue
        for pos_id in frame_1_info[group_name]:
            var tmp_pos=pos_id_2_vec2(pos_id)
            var c_tmp=image_list[1].get_pixel(tmp_pos.x,tmp_pos.y)
            var color_str = c_tmp.to_html(false)
            if not color_str in sel_color_list:
                sel_color_list[color_str]=1
        frame_c_info[group_name]=[]
        if len(sel_color_list)>0:
            for i in range(w_p):
                for j in range(h_p):
                    var c_str = raw_image.get_pixel(i,j).to_html(false)
                    if c_str in sel_color_list:
                        var pos_id = vec2_2_pos_id(Vector2(i,j))
                        frame_c_info[group_name].append(pos_id)
    image_list[1].unlock()
    raw_image.unlock()
    show_selection_by_info(current_group_name)
