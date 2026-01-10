extends GutTest

## ComponentData 單元測試
## 測試組件資料類的工廠方法與屬性


# ==============================================================================
# HealthComponentData 測試
# ==============================================================================

# 目的：驗證 HealthComponentData 初始化時，max_hp 屬性的預設值是否為 100.0
func test_health_data_default_max_hp():
	var data = HealthComponentData.new()
	assert_eq(data.max_hp, 100.0, "預設 max_hp 應為 100")


# 目的：驗證此類別能正確接收並儲存建構子傳入的自定義 max_hp 參數
func test_health_data_custom_max_hp():
	var data = HealthComponentData.new(250.0)
	assert_eq(data.max_hp, 250.0)


# 目的：驗證 get_property() 回傳的屬性名稱字串是否正確映射到 "__health_component"
func test_health_data_get_property():
	var data = HealthComponentData.new()
	assert_eq(data.get_property(), "__health_component")


# 目的：驗證 get_component() 方法是否實例化正確的類型 (HealthComponent)
func test_health_data_get_component_type():
	var data = HealthComponentData.new()
	var component = data.get_component()
	assert_not_null(component)
	assert_true(component is HealthComponent)
	component.free() # 清理


# ==============================================================================
# ComponentDB 工廠方法測試
# ==============================================================================

# 目的：驗證 ComponentDB 工廠方法 create_rect_body 是否產生正確的 BodyComponentData
func test_create_rect_body():
	var data = ComponentDB.create_rect_body(64.0, 32.0)
	assert_not_null(data)
	assert_true(data is BodyComponentData)


# 目的：驗證 ComponentDB 工廠方法 create_circle_body 是否產生正確的 BodyComponentData
func test_create_circle_body():
	var data = ComponentDB.create_circle_body(16.0)
	assert_not_null(data)
	assert_true(data is BodyComponentData)


func test_health_static_constant():
	var data = ComponentDB.HEALTH
	assert_not_null(data)
	assert_eq(data.max_hp, 100.0)
