extends CanvasLayer

var game: Node2D
var root: Control
var region_label: Label
var health_label: Label
var health_bar: ProgressBar
var resources_label: Label
var objective_label: Label
var workers_label: Label
var skills_label: Label
var notice_label: Label
var hint_label: Label
var boss_bar: ProgressBar
var boss_name: Label
var gather_bar: ProgressBar
var modal: PanelContainer
var modal_body: VBoxContainer
var modal_key: String = "unset"
var map_view: Control
var dimmer: ColorRect
var dynamic_labels: Dictionary = {}
var font: Font = ThemeDB.fallback_font
const INK = Color("101e26")
const PANEL = Color("172932")
const EDGE = Color("365059")
const GOLD = Color("dfbd7e")
const TEXT = Color("e2e7de")
const MUTED = Color("94aaa8")

func _ready() -> void:
	root=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme=Theme.new()
	theme.default_font_size=16
	theme.set_color("font_color","Label",TEXT)
	theme.set_color("font_color","Button",TEXT)
	theme.set_color("font_hover_color","Button",Color("fff0ce"))
	theme.set_stylebox("normal","Button",box(Color("283f47"),EDGE,6))
	theme.set_stylebox("hover","Button",box(Color("3b5759"),GOLD,6))
	theme.set_stylebox("pressed","Button",box(Color("1c333b"),GOLD,6))
	root.theme=theme
	var top=panel_at(Rect2(18,16,1244,66))
	label_at(top,"EMBER VEIL",Vector2(18,8),23,GOLD)
	label_at(top,"F I R S T   L I G H T   /   P R O T O T Y P E  0 . 1",Vector2(19,39),10,MUTED)
	region_label=label_at(top,"",Vector2(346,15),16,TEXT)
	label_at(top,"A living world, at your pace",Vector2(346,38),12,MUTED)
	health_bar=progress_at(top,Rect2(725,33,180,9),Color("85b19c"))
	health_label=label_at(top,"",Vector2(725,9),13,TEXT)
	button_at(top,"World  [M]",Rect2(953,16,112,35),func(): game.map_open=not game.map_open;game.panel="";game.gather_target=-1)
	button_at(top,"Bag  [I]",Rect2(1080,16,143,35),func(): game.panel="" if game.panel=="inventory" else "inventory";game.map_open=false;game.gather_target=-1)
	var side=panel_at(Rect2(1014,99,248,493))
	label_at(side,"YOUR EXPEDITION",Vector2(17,15),13,GOLD)
	objective_label=label_at(side,"",Vector2(17,46),14,TEXT)
	line(side,Vector2(17,124),214)
	label_at(side,"SATCHEL",Vector2(17,143),12,GOLD)
	resources_label=label_at(side,"",Vector2(17,172),15,TEXT)
	line(side,Vector2(17,287),214)
	label_at(side,"SKILLS",Vector2(17,305),12,GOLD)
	skills_label=label_at(side,"",Vector2(17,332),14,TEXT)
	line(side,Vector2(17,395),214)
	label_at(side,"WHILE YOU'RE AWAY",Vector2(17,413),12,GOLD)
	workers_label=label_at(side,"",Vector2(17,440),12,MUTED)
	var bottom=panel_at(Rect2(220,646,780,56))
	button_at(bottom,"E  Interact",Rect2(10,9,125,37),func(): if not game.blocking_ui(): game.interact())
	button_at(bottom,"SPACE  Strike",Rect2(145,9,145,37),func(): if not game.blocking_ui(): game.attack())
	button_at(bottom,"SHIFT  Dodge",Rect2(300,9,145,37),func(): if not game.blocking_ui(): game.roll())
	button_at(bottom,"Q  Potion",Rect2(455,9,125,37),func(): if not game.blocking_ui(): game.use_potion())
	button_at(bottom,"H  Help",Rect2(590,9,90,37),func(): game.show_help=not game.show_help;game.gather_target=-1)
	button_at(bottom,"Save",Rect2(690,9,78,37),func(): game.save_now();game.toast("Progress saved."))
	hint_label=label_at(root,"",Vector2(260,601),16,Color("f2d89f"))
	notice_label=label_at(root,"",Vector2(28,96),14,TEXT)
	notice_label.add_theme_color_override("font_shadow_color",Color("101e26"))
	notice_label.add_theme_constant_override("shadow_offset_x",1)
	notice_label.add_theme_constant_override("shadow_offset_y",2)
	notice_label.size=Vector2(940,70)
	notice_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	gather_bar=progress_at(root,Rect2(390,628,310,6),Color("c2dca1"))
	boss_name=label_at(root,"THE CRYSTAL WEAVER",Vector2(385,145),15,Color("dec7f0"))
	boss_bar=progress_at(root,Rect2(300,175,440,9),Color("ad84cf"))
	boss_bar.max_value=340
	dimmer=ColorRect.new()
	dimmer.color=Color(0.02,0.05,0.07,0.76)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dimmer)
	modal=PanelContainer.new()
	modal.position=Vector2(325,115)
	modal.size=Vector2(630,460)
	modal.add_theme_stylebox_override("panel",box(INK,EDGE,10))
	root.add_child(modal)
	var margin=MarginContainer.new()
	for side_name in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side_name,28)
	modal.add_child(margin)
	modal_body=VBoxContainer.new()
	modal_body.add_theme_constant_override("separation",12)
	margin.add_child(modal_body)
	map_view=Control.new()
	map_view.position=Vector2(200,106)
	map_view.size=Vector2(850,520)
	map_view.draw.connect(draw_map)
	root.add_child(map_view)
	refresh()

func box(color: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=color
	style.border_color=border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left=12
	style.content_margin_right=12
	style.content_margin_top=8
	style.content_margin_bottom=8
	return style

func panel_at(rect: Rect2) -> Panel:
	var p=Panel.new()
	p.position=rect.position
	p.size=rect.size
	p.add_theme_stylebox_override("panel",box(PANEL,EDGE,8))
	root.add_child(p)
	return p

func label_at(parent: Node, text: String, pos: Vector2, size: int, color: Color) -> Label:
	var l=Label.new()
	l.text=text
	l.position=pos
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func button_at(parent: Node, text: String, rect: Rect2, action: Callable) -> Button:
	var b=Button.new()
	b.text=text
	b.position=rect.position
	b.size=rect.size
	b.add_theme_font_size_override("font_size",14)
	b.focus_mode=Control.FOCUS_NONE
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func progress_at(parent: Node, rect: Rect2, color: Color) -> ProgressBar:
	var p=ProgressBar.new()
	p.position=rect.position
	p.size=rect.size
	p.show_percentage=false
	var background=box(Color("0c1820"),Color("2d444a"),3)
	var fill=box(color,color,3)
	for style in [background,fill]:
		style.content_margin_left=0
		style.content_margin_right=0
		style.content_margin_top=0
		style.content_margin_bottom=0
	p.add_theme_stylebox_override("background",background)
	p.add_theme_stylebox_override("fill",fill)
	p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	p.size=rect.size
	return p

func line(parent: Node, pos: Vector2, width: float) -> void:
	var l=ColorRect.new()
	l.position=pos
	l.size=Vector2(width,1)
	l.color=EDGE
	parent.add_child(l)

func refresh() -> void:
	if region_label==null: return
	region_label.text=game.region()
	health_label.text="HEALTH   %d / 100" % int(game.hp)
	health_bar.value=game.hp
	var inv=game.progress.inventory
	resources_label.text="Wood         %d\nIron ore       %d\nFish / Herbs   %d / %d\nCrystal        %d" % [inv.wood,inv.ore,inv.fish,inv.herb,inv.crystal]
	objective_label.text=game.objective()
	skills_label.text="Woodcutting %d    Mining %d\nFishing %d           Combat %d" % [game.progress.level("woodcutting"),game.progress.level("mining"),game.progress.level("fishing"),game.progress.level("combat")]
	var workers=game.progress.workers
	workers_label.text="Wood: %s\nOre:    %s" % ["5 / minute" if workers.wood else "Hire at the worker board","5 / minute" if workers.ore else "Hire at the worker board"]
	notice_label.text=game.notice if game.notice_timer>0 else ""
	hint_label.text="WASD / arrows to explore  •  Gold markers show resources"
	if game.nearest>=0 and not game.blocking_ui():
		var obj=game.world.objects[game.nearest]
		hint_label.text="[E]  "+obj.title+ ("  •  gathering... E to stop" if game.gather_target==game.nearest else "")
	if game.blocking_ui(): hint_label.text=""
	gather_bar.visible=game.gather_target>=0 and not game.blocking_ui()
	if gather_bar.visible:
		gather_bar.value=100*game.gather_timer/game.gather_duration(game.world.objects[game.gather_target])
	var boss_visible=game.area=="mine" and not game.boss.is_empty() and game.boss.get("hp",0)>0 and game.player.distance_to(game.boss.pos)<420
	boss_bar.visible=boss_visible
	boss_name.visible=boss_visible
	if boss_visible: boss_bar.value=game.boss.hp
	var key="help" if game.show_help else ("pause" if game.paused else game.panel)
	if game.map_open and key=="": key="map"
	dimmer.visible=key!=""
	modal.visible=key!="" and key!="map"
	map_view.visible=key=="map"
	if key!=modal_key:
		modal_key=key
		build_modal(key)
	if key=="map": map_view.queue_redraw()
	if dynamic_labels.has("feedback"):
		dynamic_labels.feedback.text=game.notice if game.notice_timer>0 else ""
	if dynamic_labels.has("inventory"):
		var text=""
		for item in inv:
			text+="%-16s %d\n" % [game.NAMES[item],inv[item]]
		dynamic_labels.inventory.text=text
	if dynamic_labels.has("sword"):
		dynamic_labels.sword.text="Sword tier %d  •  %d damage" % [game.progress.sword_level,game.damage()]
	if dynamic_labels.has("craft_stock"):
		dynamic_labels.craft_stock.text="Wood %d   •   Ore %d   •   Fish %d   •   Herbs %d   •   Planks %d" % [inv.wood,inv.ore,inv.fish,inv.herb,inv.plank]
	if dynamic_labels.has("upgrade"):
		dynamic_labels.upgrade.text="Sword fully upgraded" if game.progress.sword_level>=3 else "Upgrade sword  ·  %d wood + %d ore" % [5*game.progress.sword_level,5*game.progress.sword_level]
		dynamic_labels.upgrade.disabled=game.progress.sword_level>=3
	for item in ["wood","ore"]:
		if dynamic_labels.has("worker_"+item):
			dynamic_labels["worker_"+item].disabled=workers[item]
			if workers[item]: dynamic_labels["worker_"+item].text="Worker active  •  1 "+item+" / 12 seconds"

func modal_label(text: String, size: int = 16, color: Color = TEXT) -> Label:
	var l=Label.new()
	l.text=text
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	modal_body.add_child(l)
	return l

func modal_button(text: String, action: Callable) -> Button:
	var b=Button.new()
	b.text=text
	b.custom_minimum_size=Vector2(0,43)
	b.focus_mode=Control.FOCUS_NONE
	b.pressed.connect(action)
	modal_body.add_child(b)
	return b

func close_modal() -> void:
	game.panel=""
	game.show_help=false
	game.paused=false
	game.map_open=false

func build_modal(key: String) -> void:
	for child in modal_body.get_children():
		modal_body.remove_child(child)
		child.queue_free()
	dynamic_labels.clear()
	modal.size=Vector2(630,0)
	match key:
		"help":
			modal_label("FIRST LIGHT",12,GOLD)
			modal_label("Welcome to Emberveil",30,TEXT)
			modal_label("A little world with two rhythms: resources keep flowing, while adventures need you.",17,MUTED)
			modal_label("WASD / arrows    Move\nE    Interact or gather repeatedly; move to stop\nSPACE / left click    Sword attack\nSHIFT    Dodge (brief invulnerability)\nQ    Drink a healing potion\nI    Inventory     M    World map     ESC    Pause",16)
			modal_label("Start here: gather 5 wood and 5 ore, upgrade your sword at the forge, then enter the northern mine. Hire workers at the board south of the village.",15,MUTED)
			modal_label("Single-player prototype • auto-save • up to 8h offline production\nCosmetic rewards are local game items; Steam is not connected.",12,GOLD)
			modal_button("Begin exploring",close_modal)
		"inventory":
			modal_label("YOUR SATCHEL",12,GOLD)
			modal_label("Inventory & equipment",27)
			dynamic_labels.inventory=modal_label("",16)
			dynamic_labels.sword=modal_label("",16,GOLD)
			if game.progress.cloak:
				modal_label("WEAVER'S MANTLE  •  Active challenge reward",16,Color("c5a5df"))
				modal_button("Toggle cosmetic cloak",func(): game.progress.equipped_cloak=not game.progress.equipped_cloak;game.save_now())
			else:
				modal_label("Weaver's Mantle: defeat the Crystal Weaver to unlock.\nThis reward cannot be produced by idle workers.",14,MUTED)
			modal_button("Back to the world",close_modal)
		"craft":
			modal_label("RIVERDORP WORKSHOP",12,GOLD)
			modal_label("Make something useful",27)
			dynamic_labels.craft_stock=modal_label("",14,MUTED)
			dynamic_labels.sword=modal_label("",16,GOLD)
			modal_button("Craft plank  ·  3 wood",func(): game.craft("plank"))
			modal_button("Brew healing potion  ·  1 fish + 2 herbs",func(): game.craft("potion"))
			dynamic_labels.upgrade=modal_button("Upgrade sword",func(): game.craft("sword"))
			modal_label("Potions restore 50 HP. Sword upgrades improve your active attacks.\nRecipes consume the listed materials.",14,MUTED)
			modal_button("Leave workshop",close_modal)
		"workers":
			modal_label("THE WORKER BOARD",12,GOLD)
			modal_label("A world that keeps working",27)
			dynamic_labels.craft_stock=modal_label("",14,MUTED)
			modal_label("Hire permanent workers to collect basic materials.\nEach gathers 1 resource every 12 seconds. Offline progress is capped at 8 hours per absence.",16,MUTED)
			dynamic_labels.worker_wood=modal_button("Hire woodcutter  ·  8 wood + 3 ore",func(): game.hire("wood"))
			dynamic_labels.worker_ore=modal_button("Hire miner  ·  3 planks + 5 ore",func(): game.hire("ore"))
			modal_label("Workers never award boss loot, cosmetics or combat XP.",14,GOLD)
			modal_button("Back to the world",close_modal)
		"pause":
			modal_label("TAKE A BREATHER",12,GOLD)
			modal_label("Adventure paused",30)
			modal_label("Combat is paused. Your hired workers continue producing materials.",16,MUTED)
			modal_button("Continue",close_modal)
			modal_button("Save progress",func(): game.save_now();game.toast("Progress saved."))
			modal_button("Controls",func(): game.paused=false;game.show_help=true)
			modal_button("Save & quit",func(): game.save_now();game.get_tree().quit())

	if key in ["craft","workers","inventory","pause"]:
		dynamic_labels.feedback=modal_label("",13,GOLD)

func draw_map() -> void:
	map_view.draw_style_box(box(INK,EDGE,8),Rect2(0,0,850,540))
	map_view.draw_string(font,Vector2(25,34),"THE WORLD OF EMBERVEIL",HORIZONTAL_ALIGNMENT_LEFT,-1,23,GOLD)
	map_view.draw_string(font,Vector2(25,60),"Explorable prototype  •  M or ESC to close  •  Gold diamond: you",HORIZONTAL_ALIGNMENT_LEFT,-1,14,MUTED)
	var origin=Vector2(30,88)
	var scale: float = 7.7
	for y in range(WorldMap.H):
		for x in range(WorldMap.W):
			var type=game.world.tile_kind(x,y)
			var c=Color("527452")
			match type:
				"water":c=Color("2c596c")
				"snow":c=Color("bfd0cc")
				"path","bridge":c=Color("b5a17c")
				"forest":c=Color("537b78")
				"sand":c=Color("bcab80")
				"wall":c=Color("253040")
				"cave":c=Color("655a76")
				"marsh":c=Color("4b6464")
			map_view.draw_rect(Rect2(origin+Vector2(x,y)*scale,Vector2(scale+0.5,scale+0.5)),c)
	for obj in game.world.objects:
		var p: Vector2 = origin+obj.pos/32*scale
		var c=GOLD if obj.kind in ["portal","forge","camp"] else Color("a6c58d")
		map_view.draw_circle(p,4 if obj.kind in ["portal","forge","camp"] else 2,c)
	var pp=origin+game.player/32*scale
	map_view.draw_colored_polygon(PackedVector2Array([pp+Vector2(0,-7),pp+Vector2(6,0),pp+Vector2(0,7),pp+Vector2(-6,0)]),Color("ffe2a1"))
	var tx=Vector2(610,108)
	map_view.draw_string(font,tx,"CURRENT LAYER",HORIZONTAL_ALIGNMENT_LEFT,-1,12,GOLD)
	map_view.draw_string(font,tx+Vector2(0,27),"Overworld" if game.area=="surface" else "Underground",HORIZONTAL_ALIGNMENT_LEFT,-1,20,TEXT)
	var lines=["Riverdorp", "Forge & worker board", "", "North: mountain mine", "East: enchanted forest", "West: fishing coast", "South: fields & marsh", "", "Use E at a mine entrance", "to change layers."] if game.area=="surface" else ["West: entrance & forge", "Center: iron & crystal", "East: Crystal Weaver", "", "Watch the pink circles.", "Step outside or dodge", "before they detonate."]
	for i in range(lines.size()):
		map_view.draw_string(font,tx+Vector2(0,65+i*24),lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,13,MUTED)
