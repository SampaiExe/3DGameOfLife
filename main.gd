extends Node3D

@export var startingCells: int = 1400
@export var cellMat: Material

var grids = [{}, {}] #Alive Cells, Dead Cells
var cells = {}
var aliveColor: Color

var deadColor: Color = Color.WHITE
var mat: Material

var gridSize = 21

var zoom = 1.0
const ZOOM_STEP = 1

var yaw = 0.0
var pitch = 0.0
var mouseSensitivity = 0.003

@export var birth := [6]
@export var survivial := [4, 5, 6]

func _ready() -> void:
	$Cell.hide()
	init_random_gamestate(startingCells)
	mat = $Cell.get_active_material(0)
	#aliveColor = mat.get("albedo_color")
	pass

var moveSpeed = 10.0
func _process(delta):
	var input_vec := Vector3.ZERO
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if Input.is_action_pressed("forward"):  input_vec.z -= 1
		if Input.is_action_pressed("backward"): input_vec.z += 1
		if Input.is_action_pressed("left"):     input_vec.x -= 1
		if Input.is_action_pressed("right"):    input_vec.x += 1
		if Input.is_action_pressed("up"):       input_vec.y += 1
		if Input.is_action_pressed("down"):     input_vec.y -= 1
		
		input_vec = input_vec.normalized()
		$Camera3D.global_translate(($Camera3D.global_transform.basis * input_vec) * moveSpeed * delta)

func init_random_gamestate(numCells: int):
	for cell in numCells:
		var x = randi() % gridSize
		var y = randi() % gridSize
		var z = randi() % gridSize
		if not cells.has(Vector3(x, y, z)): 
			add_new_cell(Vector3(x, y, z))
	pass



func _unhandled_input(event):
	if event.is_action_pressed("reset"):
		restart()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clamp(zoom + ZOOM_STEP, 0.1, 8.0)
			$Camera3D.fov += ZOOM_STEP
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clamp(zoom + -ZOOM_STEP, 0.1, 8.0)
			$Camera3D.fov -= ZOOM_STEP
			
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var delta = event.relative

		yaw -= delta.x * mouseSensitivity
		pitch -= delta.y * mouseSensitivity
		pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))

		$Camera3D.rotation = Vector3(pitch, yaw, 0)
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			var pan_speed = 0.01
			var delta = event.relative
			var right = global_transform.basis.x
			var up = global_transform.basis.y
			$Camera3D.global_translate((-right * delta.x + up * delta.y) * pan_speed)
	
	
func start_stop():
	if $Timer.is_stopped() and cells.size() > 0:
		$Timer.start()
		$c/Running.show()
		$c/Stopped.hide()
	else:
		$Timer.stop()
		$c/Running.hide()
		$c/Stopped.show()
		
var toCheck = {}
func get_alive_cells(pos: Vector3, first_pass = true):
	var live_cells = 0
	
	for y in [-1, 0, 1]:
		for x in [-1, 0, 1]:
			for z in [-1, 0, 1]:
				if x != 0 || y != 0 || z != 0:
					var np = pos + Vector3(x, y, z)
					if grids[0].has(np):
						if grids[0][np]:
							live_cells += 1
					else:
						if first_pass:
							toCheck[np] = true
	return live_cells

func add_new_cells():
	for pos in toCheck.keys():
		var n = get_alive_cells(pos, false)
		if birth.has(n) and not grids[1].has(pos):
			add_new_cell(pos)
	toCheck.clear()

func regenerate():
	for key in cells.keys():
		var n = get_alive_cells(key)
		if grids[0][key]: # Alive
			grids[1][key] = (survivial.has(n))
		else: # Dead
			grids[1][key] = (birth.has(n))

func add_new_cell(pos: Vector3):
	if cells.has(pos):
		return
	var cell = $Cell.duplicate()
	cell.set("material_override", cellMat)
	cell.position = pos
	add_child(cell)
	cell.show()
	cells[pos] = cell
	grids[1][pos] = true

func update_cells():
	var to_delete = []
	for key in cells.keys():
		var _mat = cells[key].get_active_material(0)
		if grids[1][key]: # Alive
			pass
		else: # Dead
			to_delete.append(key)
	# Remove dead nodes
	for key in to_delete:
		cells[key].queue_free()
		cells.erase(key)
			
func _on_timer_timeout() -> void:
	grids.reverse()
	print(len(grids[0]))
	grids[1].clear()
	regenerate()
	add_new_cells()
	update_cells()
	
func restart():
	$Timer.stop()
	for key in cells.keys():
		cells[key].queue_free()
		
	cells.clear()
	grids[0].clear()
	grids[1].clear()
	init_random_gamestate(startingCells)
	$Timer.start()
