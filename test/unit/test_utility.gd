extends GutTest

## Utility.gd 單元測試
## 針對純函數進行測試，無需依賴注入


# ==============================================================================
# parse_address_string 測試
# ==============================================================================

func test_parse_address_empty_string_returns_defaults():
	var result = Utility.parse_address_string("", 17777, "127.0.0.1")
	assert_true(result.valid, "空字串應該回傳 valid")
	assert_eq(result.ip, "127.0.0.1", "IP 應該是預設值")
	assert_eq(result.port, 17777, "Port 應該是預設值")


func test_parse_address_ipv4_with_port():
	var result = Utility.parse_address_string("192.168.1.1:8080", 17777, "127.0.0.1")
	assert_true(result.valid)
	assert_eq(result.ip, "192.168.1.1")
	assert_eq(result.port, 8080)


func test_parse_address_ws_protocol():
	var result = Utility.parse_address_string("ws://localhost:9000", 17777, "127.0.0.1")
	assert_true(result.valid)
	assert_eq(result.protocol, 1, "ws:// 應該設定 protocol 為 TCP (1)")
	assert_eq(result.port, 9000)


func test_parse_address_wss_protocol():
	var result = Utility.parse_address_string("wss://example.com:443", 17777, "127.0.0.1")
	assert_true(result.valid)
	assert_eq(result.protocol, 1, "wss:// 應該設定 protocol 為 TCP (1)")


func test_parse_address_udp_protocol():
	var result = Utility.parse_address_string("udp://localhost:8080", 17777, "127.0.0.1")
	assert_true(result.valid)
	assert_eq(result.protocol, 0, "udp:// 應該設定 protocol 為 UDP (0)")


func test_parse_address_ipv6_bracket_format():
	var result = Utility.parse_address_string("[::1]:8080", 17777, "127.0.0.1")
	assert_true(result.valid)
	assert_eq(result.ip, "::1")
	assert_eq(result.port, 8080)


func test_parse_address_invalid_port_returns_invalid():
	var result = Utility.parse_address_string("localhost:abc", 17777, "127.0.0.1")
	assert_false(result.valid, "非數字 port 應該回傳 invalid")


func test_parse_address_port_out_of_range_high():
	var result = Utility.parse_address_string("localhost:70000", 17777, "127.0.0.1")
	assert_false(result.valid, "Port 超過 65535 應該回傳 invalid")


func test_parse_address_port_out_of_range_zero():
	var result = Utility.parse_address_string("localhost:0", 17777, "127.0.0.1")
	assert_false(result.valid, "Port 為 0 應該回傳 invalid")


# ==============================================================================
# min_custom 測試
# ==============================================================================

func test_min_custom_empty_array_returns_null():
	var result = Utility.min_custom([], func(a, b): return a < b)
	assert_null(result)


func test_min_custom_single_element():
	var arr = [42]
	var result = Utility.min_custom(arr, func(a, b): return a < b)
	assert_eq(result, 42)


func test_min_custom_finds_minimum():
	var arr = [5, 3, 8, 1, 9]
	var result = Utility.min_custom(arr, func(a, b): return a < b)
	assert_eq(result, 1)


func test_min_custom_with_custom_comparator():
	var arr = [ {"value": 5}, {"value": 3}, {"value": 8}]
	var result = Utility.min_custom(arr, func(a, b): return a.value < b.value)
	assert_eq(result.value, 3)
