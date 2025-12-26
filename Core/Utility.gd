#class_name Utility
extends Node2D


func create_area(r: float) -> Area2D:
	var area = Area2D.new()
	var collide = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = r
	collide.shape = shape
	area.add_child(collide)
	return area


func min_custom(array: Array, com: Callable):
	if array.is_empty():
		return null
	
	var min_value = array[0]
	for i in range(1, array.size()):
		if com.call(array[i], min_value):
			min_value = array[i]
	return min_value


## 2D 物理空間查詢 返回碰撞的節點列表
func collide_query_polygon(
	global_polygon: PackedVector2Array,
	mask: int
	) -> Array[Node2D]:
	var shape_rid = PhysicsServer2D.convex_polygon_shape_create() # 凸多邊形
	PhysicsServer2D.shape_set_data(shape_rid, global_polygon)

	var params = PhysicsShapeQueryParameters2D.new()
	params.shape_rid = shape_rid
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.collision_mask = mask
	
	var result: Array[Node2D] = []
	for i in get_world_2d().direct_space_state.intersect_shape(params):
		result.append(i["collider"])
	
	PhysicsServer2D.free_rid(shape_rid)
	return result


func collide_query_circle(
	pos: Vector2,
	R: float,
	mask: int
	) -> Array[Node2D]:
	var shape_rid = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(shape_rid, R)

	var params = PhysicsShapeQueryParameters2D.new()
	params.transform = Transform2D(0, pos) # 設定位置
	params.shape_rid = shape_rid
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.collision_mask = mask
	
	var result: Array[Node2D] = []
	for i in get_world_2d().direct_space_state.intersect_shape(params):
		result.append(i["collider"])
	
	PhysicsServer2D.free_rid(shape_rid)
	return result


## 回傳 Dictionary（命中時包含 position, normal, collider, collider_id 等）[br]
## 若未命中回傳空 Dictionary {}[br]
## 參數：[br]
## - caller_node: 用來取得 world_2d 的 Node（通常傳 self）[br]
## - from: 全域起點（Vector2）[br]
## - to: 全域終點（Vector2）[br]
## - exclude_self: 是否自動把 caller_node 加入排除清單（預設 true）[br]
## [br]
## 与一个给定空间中的一个射线相交。射线位置和其他参数通过 PhysicsRayQueryParameters2D 定义。返回的对象是一个包含以下字段的字典：[br]
## collider：该碰撞对象。[br]
## collider_id：该碰撞对象的 ID。[br]
## normal：在相交点处该对象的表面法线；如果射线从形状内部开始，并且 PhysicsRayQueryParameters2D.hit_from_inside 为 true，则为 Vector2(0, 0)。[br]
## position：该相交点。[br]
## rid：该相交对象的 RID。[br]
## shape：该碰撞形状的形状索引。[br]
## 如果射线没有与任何东西相交，则返回一个空字典。[br]
func raycast_once(
		caller_node: Node2D,
		from: Vector2,
		to: Vector2,
		
		collision_mask: int = 0xFFFFFFFF,
		exclude_self: bool = true,
		collide_with_bodies: bool = true,
		collide_with_areas: bool = false
	) -> Dictionary:
	if caller_node == null:
		return {}
	var world := caller_node.get_world_2d()
	if world == null:
		return {}
	
	var params := PhysicsRayQueryParameters2D.new()
	params.from = from
	params.to = to
	params.collision_mask = collision_mask
	params.collide_with_bodies = collide_with_bodies
	params.collide_with_areas = collide_with_areas
	if exclude_self:
		# 加入 caller_node 與 owner（若有）以避免碰到自己
		var ex := []
		ex.append(caller_node)
		if caller_node.get_owner() != null:
			ex.append(caller_node.get_owner())
		params.exclude = ex
	var space := world.direct_space_state
	if space == null:
		return {}
	var res := space.intersect_ray(params)
	if res == null:
		return {}
	return res
#
# Network Utilities
#

static func parse_address_string(input: String, default_port: int, default_ip: String) -> Dictionary:
	var result = {"ip": default_ip, "port": default_port, "valid": false, "protocol": 0} # 0 = UDP (Simulated Enum)
	var working_input = input
	
	if working_input.is_empty():
		result.valid = true
		return result

	# Protocol 偵測 (Matches NetworkManager.Protocol enum: UDP=0, TCP=1)
	if working_input.begins_with("ws://"):
		result.protocol = 1 # TCP
		working_input = working_input.substr(5)
	elif working_input.begins_with("wss://"):
		result.protocol = 1 # TCP
		working_input = working_input.substr(6)
	elif working_input.begins_with("udp://"):
		result.protocol = 0 # UDP
		working_input = working_input.substr(6)
		
	var ip_part = working_input
	var port_part = ""
	
	# IPv6 [::1]:8080 格式處理
	if working_input.begins_with("["):
		var end_bracket = working_input.find("]")
		if end_bracket == -1:
			return result # 格式錯誤
			
		# 取出 [] 內的 IP
		ip_part = working_input.substr(1, end_bracket - 1)
		
		# 檢查是否有 Port
		if end_bracket < working_input.length() - 1:
			if working_input[end_bracket + 1] == ":":
				port_part = working_input.substr(end_bracket + 2)
			else:
				# 有東西在 ] 後面但不是 :，無效
				return result
	else:
		# 一般 IPv4 或 Hostname
		var last_colon = working_input.rfind(":")
		# 若只有一個冒號，且非 IPv6 (IPv6 至少兩個冒號)，才視為 Port 分隔
		# 但為了簡單，這裡假設如果有多個冒號且沒有 []，則視為純 IPv6
		if last_colon != -1 and working_input.count(":") == 1:
			ip_part = working_input.substr(0, last_colon)
			port_part = working_input.substr(last_colon + 1)
			
	# IP 驗證 (簡單檢查不能為空)
	if ip_part.is_empty():
		result.ip = default_ip
	else:
		result.ip = ip_part
		
	# Port 驗證
	if not port_part.is_empty():
		if port_part.is_valid_int():
			result.port = port_part.to_int()
		else:
			return result # Port 非數字
			
	# 最終範圍檢查
	if result.port < 1 or result.port > 65535:
		return result
		
	result.valid = true
	return result

static func parse_cmdline_args(default_port: int) -> Dictionary:
	var result = {"port": default_port, "protocol": 0} # 0 = UDP
	var args = OS.get_cmdline_args()
	for arg in args:
		if arg.begins_with("--port="):
			var port_str = arg.split("=")[1]
			if port_str.is_valid_int():
				result.port = port_str.to_int()
		elif arg == "--tcp" or arg == "--protocol=tcp":
			result.protocol = 1 # TCP
	return result
