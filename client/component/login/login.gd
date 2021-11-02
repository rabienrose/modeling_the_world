extends Control

var account_edit
var password_edit
var http

func _ready():
    account_edit=get_node("CenterContainer/VBoxContainer/GridContainer/TextEdit_account")
    password_edit=get_node("CenterContainer/VBoxContainer/GridContainer/TextEdit_pw") 
    http=get_node("HTTPRequest")
    http.connect("request_completed",self,"_completed");


func _on_Button_reg_button_down():
    http.request()


func _on_Button_login_button_down():
    pass # Replace with function body.

func _completed(result, response_code, headers, body):
    if result == HTTPRequest.RESULT_SUCCESS:
        pass
