extends Node

var signal_name
var sender
var task_id

func on_create(signal_name, sender,task_id):
    self.signal_name=signal_name
    self.sender=sender
    self.task_id=task_id

func callback(result, response_code, headers, body):
    sender.emit_signal(signal_name, body, task_id)
    queue_free()
    
