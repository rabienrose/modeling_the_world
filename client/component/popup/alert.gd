extends AcceptDialog

export var font_res:Resource

func set_alert_text(text):
    dialog_text=text

func _ready():
    var text_ui = get_label()
    text_ui.set("custom_fonts/font", font_res)
    text_ui.anchor_right=1
    text_ui.anchor_left=0
    text_ui.align=Label.ALIGN_CENTER
    var ok_ui = get_ok()
    ok_ui.set("custom_fonts/font", font_res)
    ok_ui.rect_min_size=Vector2(300,100)
    get_close_button().visible=false
    add_constant_override("title_height" ,0)
