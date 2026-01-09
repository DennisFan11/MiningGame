extends GutTest

## CooldownTimer 單元測試
## 測試計時器邏輯，無外部依賴


func test_is_ready_initially_true():
	var timer = CooldownTimer.new()
	assert_true(timer.is_ready(), "初始狀態應該是 ready")


func test_trigger_sets_not_ready():
	var timer = CooldownTimer.new()
	timer.trigger(10.0) # 10 秒冷卻
	assert_false(timer.is_ready(), "觸發後應該進入冷卻")


func test_get_left_time_after_trigger():
	var timer = CooldownTimer.new()
	timer.trigger(5.0)
	var left = timer.get_left_time()
	# 剛觸發，剩餘時間應該接近 5 秒（允許少量誤差）
	assert_almost_eq(left, 5.0, 0.1, "剩餘時間應該接近 5 秒")


func test_get_left_time_not_negative():
	var timer = CooldownTimer.new()
	# 不觸發，剩餘時間應該是 0
	assert_eq(timer.get_left_time(), 0.0, "未觸發時剩餘時間應為 0")


func test_get_progress_initially_one():
	var timer = CooldownTimer.new()
	assert_eq(timer.get_progress(), 1.0, "初始進度應為 1.0 (ready)")


func test_get_progress_after_trigger_is_zero():
	var timer = CooldownTimer.new()
	timer.trigger(10.0)
	var progress = timer.get_progress()
	# 剛觸發，進度應該接近 0
	assert_almost_eq(progress, 0.0, 0.05, "剛觸發時進度應接近 0")


func test_get_progress_with_zero_cd():
	var timer = CooldownTimer.new()
	timer.trigger(0.0) # 0 秒冷卻
	# 根據程式碼邏輯，cd_time <= 0 時 is_ready() 決定返回值
	assert_eq(timer.get_progress(), 1.0, "零冷卻時進度應為 1.0")
