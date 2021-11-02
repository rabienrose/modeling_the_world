extends VBoxContainer

var avatar

var color_bar
var bar_w
var color_list_ui
var fix_list
var h_stats_trim

export var color_marker_path:Resource

func hsv_2_rgb(h,s,v):
    if s == 0.0: 
        return [v, v, v]
    var i = int(h*6.0)
    var f = (h*6.0)-i
    var p = v*(1.0-s)
    var q = v*(1.0-s*f)
    var t = v*(1.0-s*(1.0-f))
    i=i%6
    if i == 0:
        return [v, t, p]
    if i == 1: 
        return [q, v, p]
    if i == 2: 
        return [p, v, t]
    if i == 3: 
        return [p, q, v]
    if i == 4: 
        return [t, p, v]
    if i == 5: 
        return [v, p, q]

func rgb_2_hsv(r,g,b):
    # r, g, b = r / 255.0, g / 255.0, b / 255.0
    var cmax = max(r, max(g, b))
    var cmin = min(r, min(g, b))
    var diff = cmax-cmin
    var h=0
    var s=0
    var v=0
    if cmax == cmin:
        h = 0
    elif cmax == r:
        h = int(60 * ((g - b) / diff) + 360) % 360
    elif cmax == g:
        h = int(60 * ((b - r) / diff) + 120) % 360
    elif cmax == b:
        h = int(60 * ((r - g) / diff) + 240) % 360
    if cmax == 0:
        s = 0
    else:
        s = (diff / cmax)
    v = cmax
    h=h/360.0
    return [h,s,v]

func _ready():
    color_list_ui=get_node("ScrollContainer/color_list")
    avatar=get_node("Panel/avatar")
    color_bar=get_node("color_bar")
    bar_w=color_bar.get_rect().size.x
    var image=Image.new()
    image.create( 360, 1, false, Image.FORMAT_RGB8)
    image.lock()
    for h in range(0, 360):
        # var rgb = hsv_2_rgb(h,1,1)
        var rgb = Color.from_hsv(h/360.0, 1.0, 1.0, 1.0)
        image.set_pixel(h, 0, rgb)
    image.unlock()
    var imageTexture = ImageTexture.new()
    imageTexture.create_from_image(image)
    color_bar.texture = imageTexture
    var tar_img=Image.new()
    tar_img.load("/home/rabienrose/Documents/code/modeling_the_world/client/binary/avatar/4_0.png")
    var img_w=tar_img.get_size().x
    var img_h=tar_img.get_size().y
    tar_img.lock()
    var h_stats=[]
    for i in range(360):
        h_stats.append({"color_id":-1,"px":[]}) 
    fix_list=[]
    for i in range(img_w):
        for j in range(img_h):
            var c =tar_img.get_pixel(i,j)
            if c.a==0:
                continue
            if c.r==0 and c.g==0 and c.b==0:
                fix_list.append([i,j,0])
                continue
            if c.r==1 and c.g==1 and c.b==1:
                fix_list.append([i,j,1])
                continue
            var hsv = rgb_2_hsv(c.r, c.g, c.b)
            var h_int = floor(hsv[0]*360)
            h_stats[h_int]["color_id"]=h_int
            h_stats[h_int]["px"].append([i,j,hsv[1],hsv[2]])
    tar_img.unlock()
    h_stats_trim=[]
    for i in range(len(h_stats)):
        if h_stats[i]["color_id"]!=-1:
            h_stats_trim.append(h_stats[i])
            show_a_dot(i/360.0, i)
            add_button(i, h_stats[i]["px"].size())

func on_highlight_px(color_id):
    var tmp_sel_node=null
    for color_marker in color_bar.get_children():
        if color_id==color_marker.color_id:
            tmp_sel_node=color_marker
        else:
            color_marker.set_highlight(false)
    if tmp_sel_node!=null:
        color_bar.remove_child(tmp_sel_node)
        tmp_sel_node.set_highlight(true)
        color_bar.add_child(tmp_sel_node)
        var tar_img=Image.new()
        tar_img.load("/home/rabienrose/Documents/code/modeling_the_world/client/binary/avatar/4_0.png")
        tar_img.lock()
        for item in h_stats_trim:
            if item["color_id"]==color_id:
                for c in item["px"]:
                    tar_img.set_pixel(c[0], c[1], Color(1.0,0.0,0.0,1.0))
        tar_img.unlock()
        var imageTexture = ImageTexture.new()
        imageTexture.create_from_image(tar_img)
        imageTexture.set_flags(0)
        avatar.texture = imageTexture



func add_button(h, count):
    var color_btn_new = load("res://component/pixel_avatar/color_btn.tscn").instance()
    color_list_ui.add_child(color_btn_new)
    color_btn_new.on_create(h, count, "Modify", self)

func show_a_dot(posi, color_id):
    var dot_node=color_marker_path.instance()
    dot_node.position.x=posi*bar_w
    dot_node.position.y=25
    color_bar.add_child(dot_node)
    dot_node.on_create(color_id)
    
            



