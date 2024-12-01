@tool
extends Node3D
@onready var grid_map: GridMap = $GridMap
@export var start: bool = false : set = set_start
@export var border_Size:int = 20 : set = set_border_size
@export var max_room_size:int = 4
@export var min_room_size:int = 2
@export var roomNumber :int = 5
@export var roomMargin :int = 1
@export var maxRecursion :int = 15
@export_range(0,1) var survival_chance:float = 0.25
@export_multiline var custom_seed : String = "" : set = set_seed
var must_have = {
	"tree": {"id": 4, "width": 2, "height": 2},
	"house": {"id": 5, "width": 20, "height": 10},
	"castle": {"id": 6, "width": 10, "height": 10}
	}
var room_tiles: Array[PackedVector3Array] = []
var room_positions : PackedVector3Array = []
func set_seed(val:String)->void:
	custom_seed = val
	seed(val.hash())
func set_start(val:bool) ->void:
	if Engine.is_editor_hint():
		#room_tiles.clear()
		#room_positions.clear()
		#visualizeBorder()
		#make_room_new(must_have.size())
		generate()
func generate():
	print("generating...")
	room_tiles.clear()
	room_positions.clear()
	if custom_seed :set_seed(custom_seed)
	visualizeBorder()
	#make_room_new(must_have.size())
	for i in roomNumber:
		make_room(maxRecursion-3)
	
	print("room_positions",room_positions)
	var v3tov2 : PackedVector2Array = []
	var del_graph : AStar2D =  AStar2D.new()
	var mst_graph : AStar2D =  AStar2D.new()
	for p in room_positions:
		v3tov2.append(Vector2(p.x,p.z))
		del_graph.add_point(del_graph.get_available_point_id(),Vector2(p.x,p.z))
		mst_graph.add_point(mst_graph.get_available_point_id(),Vector2(p.x,p.z))
	var delaunay : Array = Array(Geometry2D.triangulate_delaunay(v3tov2))
	print("delaunay",delaunay)
	for i in delaunay.size()/3:
		var p1 : int = delaunay.pop_front()
		var p2 : int = delaunay.pop_front()
		var p3 : int = delaunay.pop_front()
		del_graph.connect_points(p1,p2)
		del_graph.connect_points(p2,p3)
		del_graph.connect_points(p1,p3)
		
	print("del_graph",del_graph)
	var visted_points : PackedInt32Array = []
	visted_points.append(randi()% room_positions.size())
	while visted_points.size() != mst_graph.get_point_count():
		var possible_connect : Array[PackedInt32Array] = []
		for vp in visted_points:
			for c in del_graph.get_point_connections(vp):
				if !visted_points.has(c):
					var con : PackedInt32Array = [vp,c]
					possible_connect.append(con)
					
		print("possible_connect",possible_connect)
		var connection :PackedInt32Array =  possible_connect.pick_random()
		for pc in possible_connect:
			if v3tov2[pc[0]].distance_squared_to(v3tov2[pc[1]]) <\
			v3tov2[connection[0]].distance_squared_to(v3tov2[connection[1]]):
				connection = pc
		visted_points.append(connection[1])
		mst_graph.connect_points(connection[0],connection[1])
		del_graph.disconnect_points(connection[0],connection[1])
	print("visted_points",visted_points)
	
	var hallway_graph: AStar2D = mst_graph
	for p in del_graph.get_point_ids():
		for c in del_graph.get_point_connections(p):
			if c>p:
				var kill:float = randf()
				if survival_chance> kill:
					hallway_graph.connect_points(p,c)
	create_hallway(hallway_graph);
	make_floor()

func create_hallway(hallway_graph:AStar2D):
	var hallways : Array[PackedVector3Array] = []
	for p in hallway_graph.get_point_ids():
		for c in hallway_graph.get_point_connections(p):
			if c>p:
				var room_from : PackedVector3Array = room_tiles[p]
				var room_to : PackedVector3Array = room_tiles[c]
				var tile_from : Vector3 = room_from[0]
				var tile_to : Vector3 = room_to[0]
				for t in room_from:
					if t.distance_squared_to(room_positions[c])<\
					tile_from.distance_squared_to(room_positions[c]):
						tile_from = t
				for t in room_to:
					if t.distance_squared_to(room_positions[p])<\
					tile_to.distance_squared_to(room_positions[p]):
						tile_to = t
				var hallway : PackedVector3Array = [tile_from,tile_to]
				hallways.append(hallway)
				#grid_map.set_cell_item(tile_from,3)
				#grid_map.set_cell_item(tile_to,3)
	
	var astar : AStarGrid2D = AStarGrid2D.new()
	astar.size = Vector2i.ONE * border_Size
	astar.update()
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	
	for t in grid_map.get_used_cells_by_item(4):
		astar.set_point_solid(Vector2i(t.x,t.z))
	var _t : int = 0
	for h in hallways:
		_t +=1
		var pos_from : Vector2i = Vector2i(h[0].x,h[0].z)
		var pos_to : Vector2i = Vector2i(h[1].x,h[1].z)
		var hall : PackedVector2Array = astar.get_point_path(pos_from,pos_to)
		
		for t in hall:
			var pos : Vector3i = Vector3i(t.x,0,t.y)
			if grid_map.get_cell_item(pos) <0:
				grid_map.set_cell_item(pos,0)
		if _t%16 == 15: await  get_tree().create_timer(0).timeout
	
	
	

	
	
	


func set_border_size(val:int)-> void:
	border_Size = val
	if Engine.is_editor_hint():
		visualizeBorder()
	
func visualizeBorder():
	print(border_Size)
	grid_map.clear()
	for i in range(-1,border_Size+1):
		grid_map.set_cell_item(Vector3i(i,0,-1),2)
		grid_map.set_cell_item(Vector3i(i,0,border_Size),2)
		grid_map.set_cell_item(Vector3i(border_Size,0,i),2)
		grid_map.set_cell_item(Vector3i(-1,0,i),2)
		
func make_room(rec:int):
	if rec < 1:
		return
	var wideth : int = (randi() % (max_room_size - min_room_size)) + min_room_size
	var height : int = (randi() % (max_room_size - min_room_size)) + min_room_size
	var start_pos : Vector3i
	start_pos.x = randi() % (border_Size - wideth +1)
	start_pos.z = randi() % (border_Size - height +1)
	
	var room : PackedVector3Array = []
	for r in range(-roomMargin,height+roomMargin):
		for c in range(-roomMargin,wideth+roomMargin):
			var pos : Vector3i = start_pos + Vector3i(c,0,r)
			if grid_map.get_cell_item(pos) == 1:
				make_room(rec-1)
				return
	for r in height:
		for c in wideth:
			var pos : Vector3i = start_pos + Vector3i(c,0,r)
			grid_map.set_cell_item(pos,1)
			room.append(pos)
	room_tiles.append(room)
	var avg_x :float = start_pos.x + float(wideth)/2
	var avg_z :float = start_pos.z + float(height)/2
	var pos : Vector3 = Vector3(avg_x,0,avg_z)
	room_positions.append(pos)
	
func make_room_new(size:int):
	if size < 1:
		print("size <1")
		return
	for i in must_have:
		var wideth : int = must_have[i]["width"]
		var height : int = must_have[i]["height"]
		var start_pos : Vector3i
		start_pos.x = randi() % (border_Size - wideth +1)
		start_pos.z = randi() % (border_Size - height +1)
		var room : PackedVector3Array = []
		for r in range(-roomMargin,height+roomMargin):
			for c in range(-roomMargin,wideth+roomMargin):
				var pos : Vector3i = start_pos + Vector3i(c,0,r)
				if grid_map.get_cell_item(pos) >= 2:
					return
		for r in height:
			for c in wideth:
				var pos : Vector3i = start_pos + Vector3i(c,0,r)
				grid_map.set_cell_item(pos,1)
		var pos_must : Vector3i = start_pos
		grid_map.set_cell_item(pos_must,must_have[i]["id"])
		print(pos_must)
		#print(pos_must,must_have[i]["id"])
		room.append(pos_must)
		room_tiles.append(room)
		var avg_x :float = start_pos.x + float(wideth)/2
		var avg_z :float = start_pos.z + float(height)/2
		var pos : Vector3 = Vector3(avg_x,0,avg_z)
		room_positions.append(pos_must)

func make_floor():
	for r in range(0,border_Size):
		for c in range(0,border_Size):
			var pos : Vector3i = Vector3i(c,0,r)
			if grid_map.get_cell_item(pos) == -1:
				grid_map.set_cell_item(pos,3)
