class_name WorldMap
extends Node2D

const TILE = 32
const W = 72
const H = 52
var area: String = "surface"
var objects: Array[Dictionary] = []
var decorations: Array[Dictionary] = []
var font: Font = ThemeDB.fallback_font

func river_x(y: int) -> int:
	return 25 + int(sin(float(y) * 0.15) * 3)

func tile_kind(x: int, y: int) -> String:
	if x < 1 or y < 1 or x >= W - 1 or y >= H - 1:
		return "wall" if area == "mine" else "water"
	if area == "mine":
		var rooms = [Rect2i(3, 21, 17, 19), Rect2i(24, 12, 18, 24), Rect2i(46, 9, 22, 24)]
		for room in rooms:
			if room.has_point(Vector2i(x, y)):
				return "cave"
		if Rect2i(18, 26, 10, 5).has_point(Vector2i(x,y)) or Rect2i(40, 20, 9, 5).has_point(Vector2i(x,y)):
			return "cave"
		return "wall"
	if x < 6:
		return "water"
	if x < 10:
		return "sand"
	var rx = river_x(y)
	if absi(x-rx) <= 1:
		if y in [17,18,27,28,39,40]:
			return "bridge"
		return "water"
	if y < 10:
		return "snow"
	if x > 52 and y > 34:
		if (x * 13 + y * 7) % 23 < 5:
			return "water"
		return "marsh"
	if x > 43 and y < 28:
		return "forest"
	if (x >= 30 and x <= 42 and y >= 23 and y <= 31) or (absi(y-27)<=1) or (absi(x-36)<=1) or (x>36 and absi(y-17)<=1):
		return "path"
	return "grass"

func walkable(point: Vector2) -> bool:
	var tile = tile_kind(int(point.x / TILE), int(point.y / TILE))
	if tile in ["water", "wall"]:
		return false
	for obj in objects:
		if obj.kind == "house" and Rect2(obj.pos - Vector2(42, 50), Vector2(84, 57)).has_point(point):
			return false
	return true

func can_stand(point: Vector2) -> bool:
	return walkable(point + Vector2(-8, 0)) and walkable(point + Vector2(8, 0)) and walkable(point + Vector2(0, 6))

func build(new_area: String) -> void:
	area = new_area
	objects.clear()
	decorations.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = 70431 if area == "surface" else 9741
	if area == "surface":
		add_object("house", "The Copper Kettle", Vector2(1040, 715), {"roof": Color("b16849")})
		add_object("house", "Riverbank", Vector2(1260, 715), {"roof": Color("587a9e")})
		add_object("house", "The Workshop", Vector2(1350, 955), {"roof": Color("577c75")})
		add_object("forge", "Forge • crafting", Vector2(1180, 825))
		add_object("camp", "Worker board", Vector2(1050, 953))
		add_object("portal", "Enter the mines", Vector2(1152, 285), {"destination": "mine"})
		add_object("shrine", "Woodland shrine", Vector2(1870, 545))
		add_object("ancient_tree", "The Elder Tree", Vector2(1830, 420))
		add_object("ruins", "Vergeten Vesting", Vector2(2070, 920))
		add_object("house", "Harbor inn", Vector2(395,1230), {"roof":Color("607b91")})
		add_object("dock", "Southhaven", Vector2(310, 1250))
		for p in [Vector2(870,940),Vector2(905,1000),Vector2(1500,780),Vector2(1550,820),Vector2(1640,700),Vector2(1820,630),Vector2(650,1100)]:
			add_object("tree", "Oak • woodcutting", p, {"item": "wood", "skill": "woodcutting", "cooldown": 0.0})
		for p in [Vector2(1055,370),Vector2(1250,350),Vector2(1350,420)]:
			add_object("ore", "Iron • mining", p, {"item": "ore", "skill": "mining", "cooldown": 0.0})
		for p in [Vector2(775,865),Vector2(280,1220)]:
			add_object("fish", "Fishing spot", p, {"item": "fish", "skill": "fishing", "cooldown": 0.0})
		for p in [Vector2(1640,610),Vector2(1750,790),Vector2(920,1120),Vector2(2010,1250)]:
			add_object("herb", "Wild herbs", p, {"item": "herb", "skill": "woodcutting", "cooldown": 0.0})
		for i in range(330):
			var p = Vector2(rng.randi_range(10,W-3)*32+16, rng.randi_range(10,H-3)*32+16)
			var tile = tile_kind(int(p.x/32),int(p.y/32))
			if tile in ["grass","forest"] and not Rect2(790,620,650,430).has_point(p):
				decorations.append({"pos":p,"kind":"tree","variant":rng.randi_range(0,2)})
		for x in range(13,22):
			for y in range(34,39):
				decorations.append({"pos":Vector2(x*32+16,y*32+16),"kind":"crop","variant":0})
	else:
		add_object("portal", "Return to Riverdorp", Vector2(220,1040), {"destination": "surface"})
		add_object("forge", "Underground forge", Vector2(400,1110))
		for p in [Vector2(280,830),Vector2(425,790),Vector2(530,990),Vector2(830,740),Vector2(960,480),Vector2(1200,580)]:
			add_object("ore", "Iron • mining", p, {"item":"ore","skill":"mining","cooldown":0.0})
		for p in [Vector2(1100,850),Vector2(1300,650),Vector2(1570,380),Vector2(2070,880)]:
			add_object("crystal", "Crystal • mining", p, {"item":"crystal","skill":"mining","cooldown":0.0})
		for i in range(95):
			var p = Vector2(rng.randi_range(2,W-3)*32+16,rng.randi_range(2,H-3)*32+16)
			if tile_kind(int(p.x/32),int(p.y/32)) == "wall":
				decorations.append({"pos":p,"kind":"stone","variant":rng.randi_range(0,2)})
	queue_redraw()

func add_object(kind: String, title: String, pos: Vector2, extra: Dictionary = {}) -> void:
	var item: Dictionary = {"kind":kind,"title":title,"pos":pos}
	item.merge(extra)
	objects.append(item)

func _draw() -> void:
	for y in range(H):
		for x in range(W):
			var kind = tile_kind(x,y)
			var n = (x*73+y*37+x*y*3)%17
			var c: Color
			match kind:
				"grass": c=Color("466e48")
				"forest": c=Color("304e48")
				"path": c=Color("ae9469")
				"water": c=Color("285d72")
				"sand": c=Color("c2ad77")
				"bridge": c=Color("8e694a")
				"snow": c=Color("a5bcb5")
				"marsh": c=Color("405957")
				"cave": c=Color("343542")
				_: c=Color("171f2b")
			c = c.lightened(float(n) * 0.003)
			var p = Vector2(x*TILE,y*TILE)
			draw_rect(Rect2(p,Vector2(TILE,TILE)),c)
			if kind == "water":
				draw_line(p+Vector2(n,12),p+Vector2(n+11,12),Color("39798a"),2)
			elif kind == "bridge":
				for i in [2,10,18,26]:
					draw_line(p+Vector2(i,0),p+Vector2(i,32),Color("604b39"),2)
			elif kind == "wall":
				if tile_kind(x,y+1)=="cave":
					draw_rect(Rect2(p+Vector2(0,20),Vector2(32,12)),Color("555463"))
					draw_line(p+Vector2(0,21),p+Vector2(32,21),Color("71717b"),2)
			elif kind == "path":
				for i in range(3):
					var q = p+Vector2((n*3+i*11)%28,(n*7+i*9)%29)
					draw_rect(Rect2(q,Vector2(5+n%5,2)),c.darkened(0.05))
			elif kind in ["grass","forest","marsh"]:
				var q=p+Vector2(4+n,8+n%13)
				draw_line(q,q-Vector2(2,3),c.lightened(0.12),1)
				draw_line(q+Vector2(3,0),q+Vector2(4,-4),c.lightened(0.08),1)
				if n==2:
					draw_rect(Rect2(p+Vector2(22,24),Vector2(2,2)),Color("c4c687"))
			elif n < 5:
				draw_rect(Rect2(p+Vector2(n*4+3,14),Vector2(3,2)),c.lightened(0.12))
	for deco in decorations:
		if deco.kind == "tree":
			draw_tree(deco.pos, deco.variant, false)
		elif deco.kind == "crop":
			draw_rect(Rect2(deco.pos-Vector2(15,14),Vector2(30,28)),Color("67543e"))
			for i in range(3):
				draw_line(deco.pos+Vector2(i*8-8,6),deco.pos+Vector2(i*8-8,-8),Color("bbaa5f"),3)
		else:
			draw_circle(deco.pos,7+deco.variant*3,Color("252b39"))
	if area == "surface":
		draw_location(Vector2(1090,620), "R I V E R D O R P")
		draw_location(Vector2(1700,300), "B E T O V E R D   W O U D")
		draw_location(Vector2(1020,150), "I J Z E R B E R G E N")
		draw_location(Vector2(415,1050), "G R O E N E   V E L D E N")
		draw_location(Vector2(1800,1220), "N E V E L M O E R A S")
	else:
		draw_location(Vector2(180,710), "O N D E R G R O N D S E   M I J N E N")
		draw_location(Vector2(1580,355), "T H E   C R Y S T A L   W E A V E R")
		for x in range(180, 820, 24):
			draw_line(Vector2(x,900),Vector2(x,927),Color("746047"),4)
		draw_line(Vector2(180,905),Vector2(810,905),Color("88848a"),3)
		draw_line(Vector2(180,922),Vector2(810,922),Color("88848a"),3)
	for obj in objects:
		draw_object(obj)

func draw_location(pos: Vector2, title: String) -> void:
	draw_string(font,pos+Vector2(1,2),title,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("132c2b"))
	draw_string(font,pos,title,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("dfd8ac"))

func draw_tree(p: Vector2, variant: int, harvestable: bool) -> void:
	draw_set_transform(p)
	draw_rect(Rect2(-22,3,44,9),Color(0.02,0.05,0.06,0.25))
	draw_rect(Rect2(-4,-9,8,17),Color("654b37"))
	var c = Color("467447") if variant != 2 else Color("426f63")
	if area == "surface" and p.x>1400 and p.y<890:
		c=Color("605779") if variant==2 else Color("3c7166")
	draw_rect(Rect2(-19,-36,38,25),c.darkened(0.23))
	draw_rect(Rect2(-14,-47,29,30),c)
	draw_rect(Rect2(-7,-53,17,17),c.lightened(0.10))
	draw_rect(Rect2(-15,-36,10,6),c.lightened(0.1))
	for i in range(10):
		var a=Vector2(-12+(i*13)%26,-42+(i*7)%22)
		draw_rect(Rect2(a,Vector2(4,3)),c.lightened(0.12) if i%2==0 else c.darkened(0.1))
	draw_rect(Rect2(-2,-7,2,12),Color("9a7951"))
	if harvestable:
		draw_circle(Vector2(0,12),3,Color("d8b975"))
	draw_set_transform(Vector2.ZERO)

func draw_ellipse_shadow(pos: Vector2, size: Vector2) -> void:
	draw_set_transform_matrix(get_transform_for_shadow(pos,size))
	draw_circle(Vector2.ZERO,1,Color(0.02,0.05,0.06,0.3))
	draw_set_transform(Vector2.ZERO)

func get_transform_for_shadow(pos: Vector2, size: Vector2) -> Transform2D:
	return Transform2D(0,size,0,pos)

func draw_object(obj: Dictionary) -> void:
	var p: Vector2 = obj.pos
	var k: String = obj.kind
	if k == "tree":
		draw_tree(p,0,true)
		return
	draw_set_transform(p)
	match k:
		"house":
			draw_rect(Rect2(-46,-40,94,53),Color(0,0,0,0.20))
			draw_rect(Rect2(-40,-45,80,50),Color("c5b086"))
			draw_rect(Rect2(-40,-45,6,50),Color("5e483b"))
			draw_rect(Rect2(34,-45,6,50),Color("5e483b"))
			draw_rect(Rect2(-10,-22,20,27),Color("493d34"))
			for x in [-26,18]:
				draw_rect(Rect2(x,-26,11,12),Color("edc881"))
			var roof: Color = obj.get("roof",Color("a26148"))
			draw_colored_polygon(PackedVector2Array([Vector2(-49,-39),Vector2(-33,-78),Vector2(33,-78),Vector2(49,-39)]),roof)
			for y in [-70,-60,-50]:
				draw_line(Vector2(-35,y),Vector2(35,y),roof.darkened(0.2),2)
				for x in range(-30,31,13):
					draw_line(Vector2(x,y),Vector2(x-2,y-7),roof.lightened(0.12),1)
			draw_rect(Rect2(-42,-40,84,4),Color("59483d"))
			for y in [-33,-13,1]:
				draw_line(Vector2(-39,y),Vector2(39,y),Color("8d7859"),1)
			for x in [-22,23]:
				draw_line(Vector2(x,-26),Vector2(x,-14),Color("695d4e"),1)
			draw_rect(Rect2(20,-89,9,26),Color("777670"))
		"ore":
			draw_colored_polygon(PackedVector2Array([Vector2(-18,7),Vector2(-15,-12),Vector2(-4,-21),Vector2(12,-15),Vector2(20,5)]),Color("747f8b"))
			draw_rect(Rect2(-10,-12,8,6),Color("b98b60"))
			draw_rect(Rect2(4,-7,8,5),Color("d1a575"))
		"crystal":
			for x in [-12,0,11]:
				draw_colored_polygon(PackedVector2Array([Vector2(x-6,4),Vector2(x-6,-12),Vector2(x,-30+abs(x)),Vector2(x+5,-12),Vector2(x+5,4)]),Color("957cce"))
				draw_line(Vector2(x,-23+abs(x)),Vector2(x,0),Color("d6b5f4"),2)
		"fish":
			draw_arc(Vector2.ZERO,17,0,TAU,16,Color("a0d9d5"),2)
			draw_line(Vector2(-9,0),Vector2(8,0),Color("f0d49a"),4)
			draw_line(Vector2(-9,0),Vector2(-15,-5),Color("f0d49a"),3)
		"herb":
			for x in [-9,0,8]:
				draw_line(Vector2(x,5),Vector2(x-2,-12),Color("91ac79"),3)
				draw_rect(Rect2(x-5,-15,7,7),Color("ceb8d7"))
		"portal":
			draw_rect(Rect2(-29,-43,58,50),Color("687776"))
			draw_rect(Rect2(-21,-35,42,42),Color("111d28"))
			for x in [-25,23]:
				draw_rect(Rect2(x,-40,5,47),Color("a99061"))
			draw_rect(Rect2(-28,-43,56,6),Color("b89e70"))
			for x in [-38,36]:
				draw_rect(Rect2(x,-20,4,22),Color("72533a"))
				draw_circle(Vector2(x+2,-23),5,Color("f4be6a"))
		"forge":
			draw_rect(Rect2(-24,-30,48,36),Color("626d73"))
			draw_rect(Rect2(-14,-18,28,20),Color("b8683d"))
			draw_rect(Rect2(-9,-10,18,12),Color("f1ba6a"))
			draw_rect(Rect2(10,-53,12,25),Color("59616a"))
			draw_rect(Rect2(-38,8,30,9),Color("303e48"))
		"camp":
			for x in [-17,17]:
				draw_rect(Rect2(x,-30,4,41),Color("735944"))
			draw_rect(Rect2(-24,-35,48,29),Color("a17e53"))
			draw_rect(Rect2(-16,-30,15,17),Color("e0c991"))
			draw_rect(Rect2(4,-29,13,14),Color("d0b578"))
		"shrine":
			draw_circle(Vector2.ZERO,35,Color("577b78"))
			draw_arc(Vector2.ZERO,28,0,TAU,32,Color("9dccbb"),2)
			for x in [-23,23]:
				draw_rect(Rect2(x-5,-38,10,35),Color("7d9185"))
			draw_circle(Vector2(0,-12),8,Color("adc2ea"))
		"ancient_tree":
			draw_rect(Rect2(-64,-45,128,53),Color("283d3c"))
			draw_rect(Rect2(-20,-100,40,110),Color("685750"))
			draw_rect(Rect2(-10,-85,8,85),Color("8f7661"))
			for i in range(7):
				var x=(i%3)*45-60
				var y=-115-(i/3)*28
				draw_rect(Rect2(x,y,70,55),Color("56706e") if i%2==0 else Color("635c78"))
				for j in range(8):
					draw_rect(Rect2(x+(j*13)%61,y+(j*9)%43,4,4),Color("9c8caf"))
			draw_rect(Rect2(-12,-17,24,27),Color("243b3b"))
			draw_arc(Vector2(0,-16),12,PI,TAU,10,Color("c6a46f"),3)
		"ruins":
			for x in [-60,-20,20,60]:
				draw_rect(Rect2(x-13,-60,26,73),Color("66716f"))
				draw_rect(Rect2(x-16,-67,32,14),Color("87918a"))
				for y in range(-52,8,14):
					draw_line(Vector2(x-12,y),Vector2(x+12,y),Color("4a5958"),2)
			draw_rect(Rect2(-73,-61,147,12),Color("80877c"))
			draw_rect(Rect2(47,-55,10,28),Color("9c5d60"))
		"dock":
			draw_rect(Rect2(-53,-22,72,50),Color("866d50"))
			for x in range(-50,20,9):
				draw_line(Vector2(x,-22),Vector2(x,28),Color("4e4c41"),2)
	draw_set_transform(Vector2.ZERO)
