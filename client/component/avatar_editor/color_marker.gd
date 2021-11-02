extends Sprite

var color_id

export var dot_tex:Resource
export var dot_h_tex:Resource

func _ready():
    texture=dot_tex

func set_highlight(b_true):
    if b_true:
        texture=dot_h_tex
    else:
        texture=dot_tex

func on_create(color_id):
    self.color_id=color_id
