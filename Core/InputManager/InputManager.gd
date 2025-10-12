# InputManager.gd
extends Node

## (鍵盤/滑鼠 與 搖桿) 的即時切換
signal on_input_switch(type: InputDevice)

enum InputDevice { KEYBOARD_MOUSE, JOYPAD }

var current_device : InputDevice = InputDevice.KEYBOARD_MOUSE


func _input(event):
	if event is InputEventKey or event is InputEventMouse:
		if current_device != InputDevice.KEYBOARD_MOUSE:
			current_device = InputDevice.KEYBOARD_MOUSE
			_on_device_changed(current_device)

	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if current_device != InputDevice.JOYPAD:
			current_device = InputDevice.JOYPAD
			_on_device_changed(current_device)

func _on_device_changed(device: InputDevice):
	match device:
		InputDevice.KEYBOARD_MOUSE:
			print("切換到鍵盤滑鼠")
			# 可以更新 UI 提示，例如顯示 WASD / 滑鼠圖示
		InputDevice.JOYPAD:
			print("切換到搖桿")
			# 可以更新 UI 提示，例如顯示 A / B / 搖桿圖示
	on_input_switch.emit(device)
