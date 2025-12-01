class_name InputPort
extends Port


"""
接收原料
"""

var _output_port: OutputPort

## 出口綁定
func bind_output_port(output_port: OutputPort):
	_output_port = output_port

func get_target_line()-> TransportLine:
	return _output_port.get_line() if _output_port else null
