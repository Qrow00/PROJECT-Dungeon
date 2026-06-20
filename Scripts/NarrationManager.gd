extends Node
class_name NarrationManager

signal narration_finished

var active_tween: Tween = null
var is_narrating: bool = false
var queue: Array = []

func narrate(label: Label, text: String, speed: float = 0.03):
	if active_tween and active_tween.is_running():
		queue.append({ "label": label, "text": text, "speed": speed })
		return
	_is_narrating(label, text, speed)

func narrate_instant(label: Label, text: String):
	if active_tween and active_tween.is_running():
		active_tween.kill()
	queue.clear()
	label.text = text
	is_narrating = false
	narration_finished.emit()

func skip_current():
	if active_tween and active_tween.is_running():
		active_tween.kill()
	if is_narrating:
		is_narrating = false
		narration_finished.emit()

func _is_narrating(label: Label, text: String, speed: float):
	is_narrating = true
	label.text = ""
	var chars = text.length()
	if chars == 0:
		is_narrating = false
		narration_finished.emit()
		return

	active_tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	var step = 1.0 / max(chars, 1)
	for i in range(chars):
		var idx = i
		active_tween.tween_callback(func(): label.text = text.substr(0, idx + 1))
		active_tween.tween_interval(speed)

	active_tween.tween_callback(func(): _on_narration_done())

func _on_narration_done():
	is_narrating = false
	active_tween = null
	narration_finished.emit()
	if queue.size() > 0:
		var next = queue.pop_front()
		_is_narrating(next.label, next.text, next.speed)
