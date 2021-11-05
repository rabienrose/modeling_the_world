extends Node
onready var http  = HTTPRequest.new()

func download_small_file(request_name, signal_name, sender, task_id):
    var http_request = HTTPRequest.new()
    http_request.name=task_id
    add_child(http_request)
    var task_s = load("res://global/download_task.gd")
    http_request.set_script(task_s)
    http_request.on_create(signal_name, sender, task_id)
    http_request.connect("request_completed", http_request, "callback")
    http_request.request(Global.root_url+request_name)

