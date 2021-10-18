extends Node2D
var thread

# The thread will start here.
func _ready():
    thread = Thread.new()
    thread.start(self, "_thread_function", "Wafflecopter")


# Run here and exit.
# The argument is the userdata passed from start().
# If no argument was passed, this one still needs to
# be here and it will be null.
func _thread_function(userdata):
    print("aaaaa")
    var a=0
    for i in range(1000000000):
        a=a+1
    print("bbbbb")

# Thread must be disposed (or "joined"), for portability.
func _exit_tree():
    thread.wait_to_finish()


func _on_Button_button_down():
    pass
