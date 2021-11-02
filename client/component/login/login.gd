extends Control

export var main_scene:Resource

var account_edit
var password_edit
var alert_ui
var is_regist_succ=false
var http

func _ready():
    alert_ui=get_node("alert")
    account_edit=get_node("CenterContainer/VBoxContainer/GridContainer/TextEdit_account")
    password_edit=get_node("CenterContainer/VBoxContainer/GridContainer/TextEdit_pw") 
    alert_ui.connect("confirmed", self, "on_comfirm_regist")
    http=get_node("HTTPRequest")

func _on_Button_reg_button_down():
    http.connect("request_completed",self,"regist_response")
    var account=account_edit.text
    var password=password_edit.text
    if account=="" or password=="":
        alert_ui.set_alert_text("账号密码为空")
        alert_ui.popup_centered_minsize()
        return
    var request_data={"account":account, "password":password}
    var request_data_str = JSON.print(request_data)
    var headers = ["Content-Type: application/json"]
    var error = http.request(Global.root_url+"regist", headers, false, HTTPClient.METHOD_POST, request_data_str)
    if error != OK:
        alert_ui.set_alert_text("连接失败6")
        alert_ui.popup_centered_minsize()


func _on_Button_login_button_down():
    http.connect("request_completed",self,"login_response")
    var account=account_edit.text
    var password=password_edit.text
    if account=="" or password=="":
        alert_ui.set_alert_text("账号密码为空")
        alert_ui.popup_centered_minsize()
        return
    var request_data={"account":account, "password":password}
    var request_data_str = JSON.print(request_data)
    var headers = ["Content-Type: application/json"]
    var error = http.request(Global.root_url+"login", headers, false, HTTPClient.METHOD_POST, request_data_str)
    if error != OK:
        alert_ui.set_alert_text("连接失败5")
        alert_ui.popup_centered_minsize()

func regist_response(result, response_code, headers, body):
    if result == HTTPRequest.RESULT_SUCCESS:
        var body_data = JSON.parse(body.get_string_from_utf8()).result
        if body_data==null:
            alert_ui.set_alert_text("连接失败4")
            alert_ui.popup_centered_minsize()
            return
        if "err" in body_data:
            alert_ui.set_alert_text(body_data["err"])
            alert_ui.popup_centered_minsize()
        else:
            alert_ui.set_alert_text("注册成功")
            alert_ui.popup_centered_minsize()
            Global.token=body_data["token"]
            var token_file=File.new()
            token_file.open(Global.token_file, File.WRITE)
            token_file.store_string(Global.token)
            is_regist_succ=true
    else:
        alert_ui.set_alert_text("连接失败3")
        alert_ui.popup_centered_minsize()

func on_comfirm_regist():
    if is_regist_succ:
        get_tree().change_scene_to(main_scene)

func login_response(result, response_code, headers, body):
    if result == HTTPRequest.RESULT_SUCCESS:
        var body_data = JSON.parse(body.get_string_from_utf8()).result
        if body_data==null:
            alert_ui.set_alert_text("连接失败1")
            alert_ui.popup_centered_minsize()
            return
        if not "err" in body_data:
            Global.token=body_data["token"]
            get_tree().change_scene_to(main_scene)
            var token_file=File.new()
            token_file.open(Global.token_file, File.WRITE)
            token_file.store_string(Global.token)
        else:
            alert_ui.set_alert_text(body_data["err"])
            alert_ui.popup_centered_minsize()
    else:
        alert_ui.set_alert_text("连接失败2")
        alert_ui.popup_centered_minsize()

