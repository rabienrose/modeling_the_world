extends Control

var scrollbar
var http_request
var list_container

func _ready():
    scrollbar=get_node("ScrollContainer")
    http_request=get_node("HTTPRequest")
    list_container=scrollbar.get_node("VBoxContainer")
    http_request.connect("request_completed", self, "_on_request_completed")
    http_request.request("http://47.100.139.184:8000/query_video_list")


func _on_request_completed(result, response_code, headers, body):
    var videos_json = JSON.parse(body.get_string_from_utf8()).result
    for video_info in videos_json:
        var video_item = load("res://video_item.tscn").instance()
        list_container.add_child(video_item)
        video_item.on_create(video_info)
