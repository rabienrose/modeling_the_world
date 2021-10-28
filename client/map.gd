extends TileMap

var init_view_center=[113.251941, 23.152987]
var init_center_tile=null
var cur_center_tile=null
var zoom_lev=16
var tile_download_tasks={}
var http_request
var cache_folder="user://tiles/"
var cur_download_tilename=""
var downloading=false
var pressed=false
var dragged=false
var cam=null

func sec(v):
    return 1/cos(v)

func sinh(v):
    return log(v + sqrt(v*v + 1))

func lnglon_2_tile_id(lng, lat, lev):
    var n = pow(2, lev)
    var lat_rad=lat/180*3.1415926
    var xtile = n * ((lng + 180) / 360)
    var ytile = n * (1 - (log(tan(lat_rad) + sec(lat_rad)) / 3.1415926)) / 2
    return [int(xtile), int(ytile)]

func tile_id_2_lnglon(xtile, ytile, lev):
    var n = pow(2, lev)
    var lon_deg = xtile / n * 360.0 - 180.0
    var lat_rad = atan(sinh(3.1415926 * (1 - 2 * ytile / n)))
    var lat_deg = lat_rad * 180.0 / 3.1415926
    return [lon_deg, lat_deg]

func _process(delta):
    if downloading:
        return
    for task in tile_download_tasks:
        var tmp_split_str=task.split("_")
        var zoom=tmp_split_str[0]
        var xtile=tmp_split_str[1]
        var ytile=tmp_split_str[2]
        var tile_img_url="https://tile.openstreetmap.org/"+zoom+"/"+xtile+"/"+ytile+".png"
        print(tile_img_url)
        cur_download_tilename=task
        http_request.request(tile_img_url)
        downloading=true
        break

func update_tile(world_tile_pos):
    for i in range(world_tile_pos[0]-3, world_tile_pos[0]+3):
        for j in range(world_tile_pos[1]-3, world_tile_pos[1]+3):
            var cell_id = get_cell(i-init_center_tile[0], j-init_center_tile[0]) 
            if cell_id<0:
                var tile_img_name=str(zoom_lev)+"_"+str(i)+"_"+str(j)
                var file2Check = File.new()
                var doFileExists = file2Check.file_exists(cache_folder+tile_img_name+".png")
                if doFileExists:
                    load_from_disk(tile_img_name)
                    continue
                if tile_img_name in tile_download_tasks:
                    continue
                tile_download_tasks[tile_img_name]=1

func _ready():
    cam=get_node("Camera2D")
    var dir = Directory.new();
    if not dir.dir_exists(cache_folder):
        dir.make_dir(cache_folder)
    var ts = TileSet.new()
    http_request=get_node("HTTPRequest")
    http_request.connect("request_completed", self, "_on_request_completed")
    tile_set=ts
    init_center_tile = lnglon_2_tile_id(init_view_center[0], init_view_center[1], zoom_lev)
    cur_center_tile=Vector2(0,0)
    update_tile(init_center_tile)
    

func save_image(data, file_name):
    var file = File.new();
    var path = cache_folder+file_name;
    file.open(path, File.WRITE);
    file.store_buffer(data);
    file.close();

func load_from_disk(tile_name):
    var img = Image.new()
    var loaded = img.load(cache_folder+tile_name+".png")
    if loaded == OK: 
        var tex = ImageTexture.new()
        tex.create_from_image(img,0)
        var id = tile_set.get_last_unused_tile_id()
        tile_set.create_tile(id)
        tile_set.tile_set_name(id, tile_name)
        tile_set.tile_set_texture(id, tex)
        tile_set.tile_set_region(id, Rect2(0,0,255,255))
        var tmp_split_str=tile_name.split("_")
        # var zoom=tmp_split_str[0]
        var xtile=int(tmp_split_str[1])
        var ytile=int(tmp_split_str[2])
        var tile_c=Vector2(xtile-init_center_tile[0],ytile-init_center_tile[1])
        # print(tile_c,":",id,":",tile_name)
        set_cellv(tile_c, id)

func request_new_tile():
    var cell_pos = world_to_map(cam.position)
    if cell_pos.x==cur_center_tile.x and cell_pos.y==cur_center_tile.y:
        return
    cur_center_tile=cell_pos
    update_tile(Vector2(cur_center_tile.x+init_center_tile[0], cur_center_tile.y+init_center_tile[1]))
        
func _unhandled_input(event):
    if event is InputEventMouseButton:
        if event.pressed:
            pressed=true
            dragged=false
        else:
            if dragged:
                request_new_tile()
            pressed=false
    if event is InputEventMouseMotion:
        if pressed:
            dragged=true
            cam.position=cam.position-event.relative

func get_zoom_level():
    return zoom_lev

func set_zoom_level(level):
    var temp_lnglon = tile_id_2_lnglon(cur_center_tile.x+init_center_tile[0],cur_center_tile.y+init_center_tile[1],zoom_lev)
    zoom_lev=level
    init_center_tile=lnglon_2_tile_id(temp_lnglon[0], temp_lnglon[1], zoom_lev)
    tile_download_tasks.clear()
    clear()
    update_tile([cur_center_tile[0]+init_center_tile[0], cur_center_tile[1]+init_center_tile[1]])

func move_cam_pos(r_pos):
    cam.position=cam.position-r_pos/3

func jump_to(new_lnglat):
    var tile_pos = lnglon_2_tile_id(new_lnglat[0], new_lnglat[1], zoom_lev)
    var w_pos = map_to_world(Vector2(tile_pos[0]-init_center_tile[0], tile_pos[1]-init_center_tile[1]))
    cam.position=w_pos
    update_tile(tile_pos)

func _on_request_completed(result, response_code, headers, body):
    if result == HTTPRequest.RESULT_SUCCESS:
        save_image(body, cur_download_tilename+".png")
        load_from_disk(cur_download_tilename)
        tile_download_tasks.erase(cur_download_tilename)
        downloading=false
