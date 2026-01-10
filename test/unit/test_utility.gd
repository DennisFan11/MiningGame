extends GutTest

## Utility.gd 單元測試
## 針對純函數進行測試，無需依賴注入


# ==============================================================================
# parse_address_string 測試
# ==============================================================================

# 目的：驗證當輸入空字串時，是否回傳預設的 IP 和 Port
func test_parse_address_empty_string_returns_defaults():
	var result = Utility.parse_address_string("", 17777, "127.0.0.1")
	assert_true(result.valid, "空字串應該回傳 valid")
	assert_eq(result.ip, "127.0.0.1", "IP 應該是預設值")
	assert_eq(result.port, 17777, "Port 應該是預設值")


# 目的：驗證能正確解析標準的 IPv4:Port 格式
func test_parse_address_ipv4_with_port():
	var result = Utility.parse_address_string("192.168.1.1:8080", 17777, "127.0.0.1")
	assert_true(result.valid)
	assert_eq(result.ip, "192.168.1.1")
	assert_eq(result.port, 8080)


# 目的：驗證能正確識別 ws:// 協議前綴並將其對應到 TCP (1)
func test_parse_address_ws_protocol():
	var result = Utility.parse_address_string("ws://localhost:9000", 17777, "127.0.0.1")
	assert_true(result.valid)
	assert_eq(result.protocol, 1, "ws:// 應該設定 protocol 為 TCP (1)")
	assert_eq(result.port, 9000)


# 目的：驗證能正確識別 wss:// 協議前綴並將其對應到 TCP (1)
func test_parse_address_wss_protocol():
	var result = Utility.parse_address_string("wss://example.com:443", 17777, "127.0.0.1")
	assert_true(result.valid)
	assert_eq(result.protocol, 1, "wss:// 應該設定 protocol 為 TCP (1)")


# 目的：驗證能正確識別 udp:// 協議前綴並將其對應到 UDP (0)
func test_parse_address_udp_protocol():
	var result = Utility.parse_address_string("udp://localhost:8080", 17777, "127.0.0.1")
	assert_true(result.valid)
	assert_eq(result.protocol, 0, "udp:// 應該設定 protocol 為 UDP (0)")


# 目的：驗證能正確解析方括號包覆的 IPv6 地址
func test_parse_address_ipv6_bracket_format():
	var result = Utility.parse_address_string("[::1]:8080", 17777, "127.0.0.1")
	assert_true(result.valid)
	assert_eq(result.ip, "::1")
	assert_eq(result.port, 8080)


# 目的：驗證當 Port 為非數字時，回傳結果應標記為無效 (valid=false)
func test_parse_address_invalid_port_returns_invalid():
	var result = Utility.parse_address_string("localhost:abc", 17777, "127.0.0.1")
	assert_false(result.valid, "非數字 port 應該回傳 invalid")


# 目的：驗證當 Port 超過 65535 時，回傳結果應標記為無效
func test_parse_address_port_out_of_range_high():
	var result = Utility.parse_address_string("localhost:70000", 17777, "127.0.0.1")
	assert_false(result.valid, "Port 超過 65535 應該回傳 invalid")


# 目的：驗證當 Port 為 0 時（通常為非法或系統保留），回傳結果應標記為無效
func test_parse_address_port_out_of_range_zero():
	var result = Utility.parse_address_string("localhost:0", 17777, "127.0.0.1")
	assert_false(result.valid, "Port 為 0 應該回傳 invalid")


# ==============================================================================
# min_custom 測試
# ==============================================================================

# 目的：驗證 min_custom 在輸入空陣列時應安全回傳 null
func test_min_custom_empty_array_returns_null():
	var result = Utility.min_custom([], func(a, b): return a < b)
	assert_null(result)


# 目的：驗證單一元素的陣列應回傳該元素
func test_min_custom_single_element():
	var arr = [42]
	var result = Utility.min_custom(arr, func(a, b): return a < b)
	assert_eq(result, 42)


# 目的：驗證能根據標準數值大小比較找出最小值
func test_min_custom_finds_minimum():
	var arr = [5, 3, 8, 1, 9]
	var result = Utility.min_custom(arr, func(a, b): return a < b)
	assert_eq(result, 1)


# 目的：驗證能使用自定義的 Comparator 函數處理物件類型的比較
func test_min_custom_with_custom_comparator():
	var arr = [ {"value": 5}, {"value": 3}, {"value": 8}]
	var result = Utility.min_custom(arr, func(a, b): return a.value < b.value)
	assert_eq(result.value, 3)
