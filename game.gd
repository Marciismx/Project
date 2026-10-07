extends Node2D

const WorldScript = preload("res://scripts/world.gd")
const ProgressScript = preload("res://scripts/progress.gd")
const HUDScript = preload("res://scripts/hud.gd")
var progress = ProgressScript.new()
var world = WorldScript.new()
var hud: CanvasLayer
var camera = Camera2D.new()
var player = Vector2(1024,864)
var facing = Vector2.DOWN
var hp: float = 100
var area: String = "surface"
var clock: float = 0
var attack_timer: float = 0
var attack_cooldown: float = 0
var roll_timer: float = 0
var roll_cooldown: float = 0
var roll_direction = Vector2.ZERO
var hurt_timer: float = 0
var gather_target: int = -1
var gather_timer: float = 0
var nearest: int = -1
var save_timer: float = 0
var worker_save_timer: float = 0
var panel: String = ""
var is_moving: bool = false
var notice: String = ""
var notice_timer: float = 0
var particles: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var boss: Dictionary = {}
var map_open: bool = false
var show_help: bool = true
var paused: bool = false
var smoke_mode: bool = false
var screenshot_mode: bool = false
var font: Font = ThemeDB.fallback_font
var session_error: bool = false
const NAMES = {"wood":"Wood","ore":"Iron ore","fish":"Fish","herb":"Herbs","crystal":"Crystal","plank":"Planks","potion":"Potions"}

func _ready() -> void:
	get_tree().auto_accept_quit = false
	var args = OS.get_cmdline_user_args()
	smoke_mode = "--smoke" in args
	screenshot_mode = "--screenshot" in args
	var earned: Dictionary = {}
	if not smoke_mode and not screenshot_mode:
		earned = progress.load_game()
	player = progress.player_position
	area = progress.area
	world.z_index=-10
	add_child(world)
	world.build(area)
	if not world.can_stand(player):
		player = Vector2(280,1060) if area == "mine" else Vector2(1024,864)
	camera.position = player + Vector2(85,0)
	camera.zoom = Vector2(1.25,1.25)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = WorldMap.W * 32
	camera.limit_bottom = WorldMap.H * 32
	add_child(camera)
	hud = HUDScript.new()
	hud.game = self
	add_child(hud)
	spawn_enemies()
	if not earned.is_empty():
		var text = "Welcome back! Your workers collected: "
		for item in earned:
			text += "%d %s  " % [earned[item], NAMES[item]]
		toast(text,10)
	else:
		toast("Welcome to Riverdorp. Gather wood, explore the mine, and visit the forge.",8)
	if not progress.status_message.is_empty():
		toast(progress.status_message,10)
	if not smoke_mode and not screenshot_mode:
		save_now()
	if smoke_mode:
		call_deferred("run_smoke")
	elif screenshot_mode:
		show_help = false
		call_deferred("capture_preview")

func toast(message: String, seconds: float = 4) -> void:
	notice = message
	notice_timer = seconds

func save_now() -> void:
	if smoke_mode or screenshot_mode:
		return
	progress.area = area
	progress.player_position = player
	if not progress.save_game():
		toast(progress.status_message,8)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_now()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree():
		save_now()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:
				if show_help:
					show_help=false
				elif panel!="":
					panel=""
				elif map_open:
					map_open=false
				else:
					paused=not paused
				gather_target=-1
			KEY_H:
				show_help=not show_help
				gather_target=-1
			KEY_M:
				if not show_help and not paused:
					map_open=not map_open
					panel=""
					gather_target=-1
			KEY_I:
				if not show_help and not paused:
					panel="" if panel=="inventory" else "inventory"
					map_open=false
					gather_target=-1
			KEY_E:
				if not blocking_ui(): interact()
			KEY_SPACE:
				if not blocking_ui(): attack()
			KEY_SHIFT:
				if not blocking_ui(): roll()
			KEY_Q:
				if not blocking_ui(): use_potion()
			KEY_F5:
				save_now()
				toast("Progress saved.")
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not blocking_ui():
		if event.position.x < 1000 and event.position.y > 80 and event.position.y < 640:
			facing = (get_global_mouse_position()-player).normalized()
			attack()

func blocking_ui() -> bool:
	return show_help or paused or map_open or panel!=""

func direction_input() -> Vector2:
	var x = int(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-int(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	var y = int(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-int(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	return Vector2(x,y).normalized()

func _process(delta: float) -> void:
	delta = minf(delta,0.1)
	clock += delta
	notice_timer = maxf(0,notice_timer-delta)
	save_timer += delta
	worker_save_timer += delta
	# Workers also run while viewing inventory/help. Combat is explicitly paused.
	progress.simulate_workers(delta)
	if save_timer > 15:
		save_timer=0
		save_now()
	for particle in particles:
		particle.life-=delta
		particle.pos.y-=delta*22
	particles = particles.filter(func(p): return p.life>0)
	for obj in world.objects:
		if obj.has("cooldown"):
			obj.cooldown=maxf(0,obj.cooldown-delta)
	if not blocking_ui():
		attack_timer=maxf(0,attack_timer-delta)
		attack_cooldown=maxf(0,attack_cooldown-delta)
		roll_cooldown=maxf(0,roll_cooldown-delta)
		hurt_timer=maxf(0,hurt_timer-delta)
		roll_timer=maxf(0,roll_timer-delta)
		var dir = direction_input()
		is_moving=dir.length()>0
		if is_moving:
			facing=dir
			gather_target=-1
		var movement = dir*150*delta
		if roll_timer>0:
			movement=roll_direction*460*delta
		move_player(movement)
		find_nearest()
		update_gather(delta)
		update_enemies(delta)
		if area=="surface" and player.distance_to(Vector2(1150,850))<180:
			hp=minf(100,hp+delta*9)
	else:
		is_moving=false
	camera.position=player+Vector2(85,0)
	queue_redraw()
	hud.refresh()

func move_player(motion: Vector2) -> void:
	# Substeps avoid tunnelling through tile walls during dodge.
	var steps = maxi(1,int(ceil(motion.length()/5.0)))
	var step = motion/steps
	for i in range(steps):
		if world.can_stand(player+Vector2(step.x,0)):
			player.x+=step.x
		if world.can_stand(player+Vector2(0,step.y)):
			player.y+=step.y

func find_nearest() -> void:
	nearest=-1
	var distance: float = 67
	for i in range(world.objects.size()):
		var obj = world.objects[i]
		if obj.kind in ["house","dock","ruins","ancient_tree"]:
			continue
		var d = player.distance_to(obj.pos)
		if d<distance:
			distance=d
			nearest=i

func interact() -> void:
	if nearest<0:
		toast("Move closer to a marked tree, ore vein, fishing spot or building.")
		return
	var obj = world.objects[nearest]
	match obj.kind:
		"portal":
			travel(obj.destination)
		"forge":
			panel="craft"
		"camp":
			panel="workers"
		"shrine":
			hp=100
			toast("The woodland shrine restores your health.")
		_:
			if obj.has("item"):
				gather_target=-1 if gather_target==nearest else nearest
				gather_timer=0

func travel(destination: String) -> void:
	area=destination
	world.build(area)
	player=Vector2(285,1050) if area=="mine" else Vector2(1152,345)
	gather_target=-1
	nearest=-1
	camera.position=player+Vector2(85,0)
	camera.reset_smoothing()
	spawn_enemies()
	save_now()
	toast("Underground mines • head east to find the Crystal Weaver." if area=="mine" else "The mountain air feels fresh. Follow the road south to Riverdorp.",6)

func update_gather(delta: float) -> void:
	if gather_target<0 or gather_target>=world.objects.size():
		return
	var obj = world.objects[gather_target]
	if player.distance_to(obj.pos)>72:
		gather_target=-1
		return
	if obj.cooldown>0:
		return
	gather_timer+=delta
	var duration = gather_duration(obj)
	if gather_timer>=duration:
		gather_timer=0
		progress.add(obj.item)
		progress.xp[obj.skill]+=5
		progress.total_gathered+=1
		obj.cooldown=0.5
		float_text(obj.pos,"+1 "+NAMES[obj.item],Color("bfe1a0"))

func gather_duration(obj: Dictionary) -> float:
	return maxf(0.8, (3.5 if obj.item=="crystal" else 2.2) - (progress.level(obj.skill)-1)*0.1)

func craft(recipe: String) -> void:
	match recipe:
		"plank":
			if progress.spend({"wood":3}):
				progress.add("plank")
				toast("Crafted one plank.")
			else: toast("You need 3 wood.")
		"potion":
			if progress.spend({"fish":1,"herb":2}):
				progress.add("potion")
				toast("Brewed a healing potion.")
			else: toast("You need 1 fish and 2 herbs.")
		"sword":
			if progress.sword_level>=3:
				toast("Your sword is fully upgraded for this prototype.")
			elif progress.spend({"wood":5*progress.sword_level,"ore":5*progress.sword_level}):
				progress.sword_level+=1
				toast("Sword upgraded! Damage: %d." % damage())
			else: toast("Gather more wood and iron ore for this upgrade.")
	save_now()

func hire(item: String) -> void:
	if progress.workers[item]:
		return
	var cost = {"wood":8,"ore":3} if item=="wood" else {"plank":3,"ore":5}
	if progress.spend(cost):
		progress.workers[item]=true
		toast("Worker hired: 1 %s every 12 seconds, including up to 8 hours offline." % NAMES[item],7)
	else:
		toast("Not enough supplies to hire this worker.")
	save_now()

func use_potion() -> void:
	if hp>=100:
		toast("Your health is already full.")
	elif progress.spend({"potion":1}):
		hp=minf(100,hp+50)
		float_text(player,"+50 HP",Color("8ee3b5"))
		save_now()
	else:
		toast("No potions. Craft at the forge or rest in Riverdorp.")

func damage() -> int:
	return 12+progress.sword_level*8

func attack() -> void:
	if attack_cooldown>0 or roll_timer>0:
		return
	gather_target=-1
	attack_timer=0.18
	attack_cooldown=0.42
	for enemy in enemies:
		if enemy.hp>0 and enemy.pos.distance_to(player)<60:
			var direction = (enemy.pos-player).normalized()
			if direction.dot(facing)>-0.25:
				enemy.hp-=damage()
				float_text(enemy.pos,str(damage()),Color("f7d699"))
				if enemy.hp<=0:
					progress.xp.combat+=10
					progress.add("herb")
					enemy.respawn=25.0
	if area=="mine" and boss.get("hp",0)>0 and boss.pos.distance_to(player)<100:
		if (boss.pos-player).normalized().dot(facing)>-0.25:
			boss.hp-=damage()
			float_text(boss.pos,str(damage()),Color("f7d699"))
			if boss.hp<=0:
				boss_defeated()

func roll() -> void:
	if roll_cooldown>0:
		return
	roll_direction=direction_input()
	if roll_direction==Vector2.ZERO:
		roll_direction=facing
	roll_timer=0.25
	roll_cooldown=1.35
	gather_target=-1

func hurt(amount: float) -> void:
	if roll_timer>0 or hurt_timer>0:
		return
	hp-=amount
	hurt_timer=0.75
	gather_target=-1
	float_text(player,"-"+str(int(amount)),Color("f09999"))
	if hp<=0:
		hp=100
		panel=""
		travel("surface")
		player=Vector2(1050,870)
		toast("You were rescued and returned to Riverdorp. No items lost.",6)
		save_now()

func spawn_enemies() -> void:
	enemies.clear()
	boss={}
	if area=="surface":
		for p in [Vector2(1470,1020),Vector2(1560,1060),Vector2(1740,830),Vector2(1900,720)]:
			enemies.append({"pos":p,"home":p,"hp":50,"hit":0.0,"respawn":0.0})
	else:
		boss={"pos":Vector2(1810,655),"home":Vector2(1810,655),"hp":340,"timer":2.0,"windup":0.0,"target":Vector2.ZERO,"respawn":0.0,"phase":0}

func update_enemies(delta: float) -> void:
	for enemy in enemies:
		if enemy.hp<=0:
			enemy.respawn-=delta
			if enemy.respawn<=0:
				enemy.hp=50
				enemy.pos=enemy.home
			continue
		enemy.hit=maxf(0,enemy.hit-delta)
		var d = enemy.pos.distance_to(player)
		if d<175 and d>22:
			var next = enemy.pos+(player-enemy.pos).normalized()*39*delta
			if world.can_stand(next): enemy.pos=next
		elif d>250:
			enemy.pos=enemy.pos.move_toward(enemy.home,30*delta)
		if d<27 and enemy.hit<=0:
			enemy.hit=1.1
			hurt(9)
	if area!="mine" or boss.is_empty():
		return
	if boss.hp<=0:
		boss.respawn-=delta
		if boss.respawn<=0:
			spawn_enemies()
		return
	if boss.windup>0:
		boss.windup-=delta
		if boss.windup<=0:
			var radius = 83.0 if boss.phase%2==0 else 107.0
			if player.distance_to(boss.target)<radius:
				hurt(28)
			# hurt() can change the area and replace boss on player death.
			if area!="mine" or boss.is_empty(): return
			float_text(boss.target,"SHATTER",Color("e1a0ee"))
			boss.timer=1.7
	else:
		var distance = player.distance_to(boss.pos)
		if distance<380:
			boss.timer-=delta
			if boss.timer<=0:
				boss.phase+=1
				boss.target=player if boss.phase%2==0 else boss.pos
				boss.windup=1.05
			elif distance>76:
				var next = boss.pos+(player-boss.pos).normalized()*30*delta
				if world.can_stand(next): boss.pos=next

func boss_defeated() -> void:
	boss.hp=0
	boss.windup=0
	boss.respawn=60.0
	progress.boss_kills+=1
	progress.xp.combat+=100
	progress.add("crystal",5)
	if not progress.cloak:
		progress.cloak=true
		progress.equipped_cloak=true
		toast("ACTIVE REWARD • Weaver's Mantle unlocked! +5 crystal. View it in your inventory.",10)
	else:
		toast("Crystal Weaver defeated! +5 crystal and 100 combat XP.",7)
	save_now()

func float_text(pos: Vector2, text: String, color: Color) -> void:
	particles.append({"pos":pos-Vector2(0,30),"text":text,"color":color,"life":1.25})

func region() -> String:
	if area=="mine": return "CRYSTAL HOLLOWS" if player.x>1430 else "UNDERGROUND MINES"
	if player.y<330: return "IJZERBERGEN"
	if player.x>1660 and player.y>1050: return "NEVELMOERAS"
	if player.x>1430 and player.y<900: return "BETOVERD WOUD"
	if player.x<400: return "ZUIDHAVEN"
	if player.y>1050: return "GROENE VELDEN"
	return "RIVERDORP"

func objective() -> String:
	if progress.sword_level==1:
		return "A stronger start\nGather 5 wood + 5 iron ore.\nUpgrade your sword at the forge."
	if progress.boss_kills==0:
		return "Into the crystal depths\nEnter the mine in the north.\nDefeat the Crystal Weaver."
	return "First expedition complete\nWeaver's Mantle unlocked.\nBuild your idle production."

func _draw() -> void:
	for enemy in enemies:
		if enemy.hp>0:
			draw_slime(enemy)
	if area=="mine" and not boss.is_empty():
		draw_boss()
	if nearest>=0 and nearest<world.objects.size() and not blocking_ui():
		var obj = world.objects[nearest]
		draw_arc(obj.pos+Vector2(0,4),25,0,TAU,24,Color("eacb8b"),1.5)
		if gather_target==nearest:
			draw_arc(obj.pos+Vector2(0,4),29,-PI/2,-PI/2+TAU*clampf(gather_timer/gather_duration(obj),0,1),32,Color("bce3bb"),3)
	draw_player()
	for p in particles:
		var c: Color = p.color
		c.a=minf(1,p.life*2)
		draw_string(font,p.pos,p.text,HORIZONTAL_ALIGNMENT_CENTER,-1,13,c)

func draw_player() -> void:
	var p = player.round()
	var bob = int(sin(clock*15)*2) if is_moving else 0
	if roll_timer>0: bob=-3
	draw_set_transform(p)
	draw_rect(Rect2(-10,2,22,6),Color(0,0,0,0.22))
	if hurt_timer>0 and int(clock*14)%2==0:
		draw_set_transform(Vector2.ZERO)
		return
	if progress.equipped_cloak:
		draw_colored_polygon(PackedVector2Array([Vector2(-8,-20),Vector2(8,-20),Vector2(12,0),Vector2(-12,0)]),Color("9a81d0"))
		draw_line(Vector2(-8,-19),Vector2(-11,-1),Color("d8bc83"),2)
	draw_rect(Rect2(-7,-3,5,10+bob),Color("363e43"))
	draw_rect(Rect2(3,-3,5,10-bob),Color("363e43"))
	draw_rect(Rect2(-8,-18,17,17),Color("4a9290"))
	draw_rect(Rect2(-8,-3,17,3),Color("c4a66d"))
	draw_rect(Rect2(-11,-16,4,12),Color("ca9d77"))
	draw_rect(Rect2(9,-16,4,12),Color("ca9d77"))
	draw_rect(Rect2(-7,-29,14,13),Color("dab68a"))
	draw_rect(Rect2(-8,-32,16,6),Color("51403b"))
	draw_rect(Rect2(-8,-28,4,7),Color("51403b"))
	draw_rect(Rect2(2 if facing.x>=0 else -5,-24,2,2),Color("27353b"))
	if attack_timer>0:
		var a = facing.angle()
		draw_arc(Vector2(0,-9),43,a-1.0,a+1.0,18,Color("f6e2ac"),4)
		draw_line(Vector2(0,-9),Vector2(0,-9)+facing*42,Color("d8e0dd"),4)
	else:
		draw_line(Vector2(12,-10),Vector2(21,-28),Color("bacacb"),3)
		draw_line(Vector2(10,-14),Vector2(18,-10),Color("b99b62"),3)
	draw_set_transform(Vector2.ZERO)

func draw_slime(enemy: Dictionary) -> void:
	var p: Vector2 = enemy.pos.round()
	draw_set_transform(p)
	var bob = sin(clock*4+p.x)*2
	draw_rect(Rect2(-14,3,28,6),Color(0,0,0,0.18))
	draw_rect(Rect2(-12,-12+bob,24,17),Color("75a878"))
	draw_rect(Rect2(-8,-17+bob,16,10),Color("96c38a"))
	for x in [-5,5]: draw_rect(Rect2(x,-8+bob,3,3),Color("253f44"))
	if enemy.hp<50:
		draw_rect(Rect2(-16,-26,32,3),Color("263b3e"))
		draw_rect(Rect2(-16,-26,32*maxf(0,enemy.hp)/50,3),Color("d9a095"))
	draw_set_transform(Vector2.ZERO)

func draw_boss() -> void:
	if boss.hp<=0:
		draw_string(font,boss.pos-Vector2(60,10),"Reforms in %ds" % int(boss.respawn),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("bcabcb"))
		return
	if boss.windup>0:
		var r = 83.0 if boss.phase%2==0 else 107.0
		draw_circle(boss.target,r,Color(0.76,0.25,0.44,0.17))
		draw_arc(boss.target,r,0,TAU,64,Color("e17995"),3)
		draw_arc(boss.target,r*(1.0-boss.windup/1.05),0,TAU,48,Color("e6a5bf"),2)
	draw_set_transform(boss.pos.round())
	for side in [-1,1]:
		for i in range(4):
			var y: float = i*15-24
			var leg = PackedVector2Array([Vector2(side*15,y),Vector2(side*(44+sin(clock*4+i)*4),y-12),Vector2(side*60,y+22)])
			draw_polyline(leg,Color("655182"),7)
			draw_polyline(leg,Color("b8a0db"),2)
	draw_circle(Vector2(0,-8),29,Color("65547f"))
	draw_circle(Vector2(0,18),20,Color("7e6195"))
	for x in [-14,0,14]:
		draw_colored_polygon(PackedVector2Array([Vector2(x-7,0),Vector2(x-7,-20),Vector2(x,-40-abs(x)/2),Vector2(x+7,-20),Vector2(x+7,0)]),Color("a487d9"))
		draw_line(Vector2(x,-35),Vector2(x,-2),Color("d8c5f2"),2)
	for x in [-9,9]: draw_circle(Vector2(x,20),4,Color("f0c1a2"))
	draw_set_transform(Vector2.ZERO)

func capture_preview() -> void:
	for scene in ["village","help","craft","mine","map"]:
		show_help=scene=="help"
		panel="craft" if scene=="craft" else ""
		map_open=scene=="map"
		if scene=="mine":
			travel("mine")
			player=Vector2(1710,700)
			camera.position=player+Vector2(85,0)
			camera.reset_smoothing()
		if scene=="map":
			travel("surface")
		hud.refresh()
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/emberveil-"+scene+".png")
	get_tree().quit()

func run_smoke() -> void:
	await get_tree().process_frame
	assert(world.can_stand(player),"Spawn must be walkable")
	assert(world.tile_kind(1,1)=="water")
	player=Vector2(870,969)
	find_nearest()
	assert(nearest>=0 and world.objects[nearest].item=="wood")
	interact()
	assert(gather_target==nearest)
	var before=progress.inventory.wood
	update_gather(3.0)
	assert(progress.inventory.wood==before+1)
	interact()
	assert(gather_target==-1)
	roll_timer=0.2
	hurt(20)
	assert(hp==100,"Dodge must prevent damage")
	roll_timer=0
	hurt_timer=0
	hurt(20)
	assert(hp==80)
	use_potion()
	assert(hp==100 and progress.inventory.potion==1)
	progress.inventory.wood=20
	progress.inventory.ore=20
	craft("sword")
	assert(progress.sword_level==2)
	assert(progress.inventory.wood==15)
	hire("wood")
	assert(progress.workers.wood)
	var old = progress.inventory.wood
	progress.simulate_workers(24)
	assert(progress.inventory.wood==old+2)
	travel("mine")
	assert(world.can_stand(player),"Mine entrance must be walkable")
	assert(boss.hp==340)
	player=boss.pos-Vector2(80,0)
	facing=Vector2.RIGHT
	attack_cooldown=0
	attack()
	assert(boss.hp==340-damage())
	boss.hp=1
	attack_cooldown=0
	attack()
	assert(progress.cloak and progress.boss_kills==1)
	var rewards = progress.inventory.crystal
	progress.simulate_workers(3600)
	assert(progress.inventory.crystal==rewards,"Idle must never award active rewards")
	hp=10
	roll_timer=0
	hurt_timer=0
	hurt(20)
	assert(area=="surface" and hp==100)
	assert(world.can_stand(player))
	print("SMOKE PASSED: spawn, crafting, workers, travel, combat, active rewards, respawn")
	get_tree().quit()
