#class_name Utility
extends Node2D





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
	global_polygon:PackedVector2Array,
	mask:int
	)-> Array[Node2D]:
		
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
	)-> Array[Node2D]:
		
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



## 回傳 Dictionary（命中時包含 position, normal, collider, collider_id 等）
## 若未命中回傳空 Dictionary {}
## 參數：
## - caller_node: 用來取得 world_2d 的 Node（通常傳 self）
## - from: 全域起點（Vector2）
## - to: 全域終點（Vector2）
## - exclude_self: 是否自動把 caller_node 加入排除清單（預設 true）
##
## 与一个给定空间中的一个射线相交。射线位置和其他参数通过 PhysicsRayQueryParameters2D 定义。返回的对象是一个包含以下字段的字典：
## collider：该碰撞对象。
## collider_id：该碰撞对象的 ID。
## normal：在相交点处该对象的表面法线；如果射线从形状内部开始，并且 PhysicsRayQueryParameters2D.hit_from_inside 为 true，则为 Vector2(0, 0)。
## position：该相交点。
## rid：该相交对象的 RID。
## shape：该碰撞形状的形状索引。
## 如果射线没有与任何东西相交，则返回一个空字典。
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
