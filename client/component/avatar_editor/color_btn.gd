extends HBoxContainer

var h_ui
var count_ui
var class_ui
var color_id
var host

func _ready():
    h_ui=get_node("h")
    count_ui=get_node("count")
    class_ui=get_node("class")

func on_create(h, count, p_class, parent):
    color_id=h
    var c=Color.from_hsv(h/360.0,1.0,1.0)
    h_ui.text=str(h)
    h_ui.add_color_override("font_color", c)
    count_ui.text=str(count)
    count_ui.add_color_override("font_color", c)
    class_ui.text=p_class
    class_ui.add_color_override("font_color", c)
    host=parent

func _on_Node2D_gui_input(event):
    if event is InputEventMouseButton:
        if event.pressed:
            host.on_highlight_px(color_id)
