extends GutTest

## IFF Node 單元測試

func test_iff_constants():
	# 測試 flag 位元運算
	assert_eq(IFF.TARGET.BE_SCANNED, 1)
	assert_eq(IFF.TARGET.SCAN_ALLY, 2)
	assert_eq(IFF.TARGET.SCAN_WALL, 4)
	assert_eq(IFF.TARGET.SCAN_ENEMY, 8)
	
	# 組合 flags
	var combined = IFF.TARGET.BE_SCANNED | IFF.TARGET.SCAN_ENEMY
	assert_eq(combined, 9)
	assert_true(combined & IFF.TARGET.BE_SCANNED != 0)
	assert_true(combined & IFF.TARGET.SCAN_ENEMY != 0)
	assert_false(combined & IFF.TARGET.SCAN_ALLY != 0)

func test_iff_setup():
	var iff = IFF.new()
	add_child_autofree(iff)
	
	var team = BitmaskManager.TEAM.PLAYER
	var target = IFF.TARGET.BE_SCANNED | IFF.TARGET.SCAN_ENEMY
	var radius = 120.0
	
	iff.setup(team, target, radius)
	
	assert_eq(iff.team, team)
	assert_eq(iff.target, target)
	assert_eq(iff.radius, radius)

func test_iff_property_changes():
	var iff = IFF.new()
	add_child_autofree(iff)
	iff.setup(BitmaskManager.TEAM.IDLE, 0, 64.0)
	
	iff.team = BitmaskManager.TEAM.ENEMY
	assert_eq(iff.team, BitmaskManager.TEAM.ENEMY)
	
	iff.radius = 50.0
	assert_eq(iff.radius, 50.0)
	# Verify collision shape radius if possible, but that requires access to internal area/shape
