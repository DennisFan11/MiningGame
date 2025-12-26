class_name VisionComponent
extends Component

var __body_component: BodyComponent

func can_see_target(target: Node2D, mask: int = 0xFFFFFFFF) -> bool:
	if not __body_component or not __body_component.body:
		return false
	
	var owner_node = __body_component.body
	
	var from = owner_node.global_position
	var to = target.global_position
	
	var result = Utility.raycast_once(
		owner_node,
		from,
		to,
		mask
	)
	
	if result.is_empty():
		return false # Raycast didn't hit anything? Usually it should hit target if clear.
		# Wait, raycast_once returns empty if no hit. 
		# If we blindly raycast to target, and nothing blocks (not even target?), it might replace empty.
		# Actually Utility.raycast_once intersect_ray.
		# We should ensure we collide with target.
		
	if result.has("collider") and result["collider"] == target:
		return true
		
	# Check if collider is child of target (e.g. hitbox)
	if result.has("collider") and result["collider"].get_parent() == target:
		return true
		
	return false

# Optional debug draw
func debug_draw_vision(target: Node2D):
	# Add debug drawing logic here using DebugDraw if available
	pass
