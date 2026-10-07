class_name ProgressData
extends RefCounted

const SAVE_PATH = "user://progress_v1.json"
const SAVE_VERSION = 1
const OFFLINE_CAP = 8 * 3600
const WORK_INTERVAL = 12.0
var inventory: Dictionary = {"wood": 0, "ore": 0, "fish": 0, "herb": 0, "crystal": 0, "plank": 0, "potion": 2}
var xp: Dictionary = {"woodcutting": 0, "mining": 0, "fishing": 0, "combat": 0}
var workers: Dictionary = {"wood": false, "ore": false}
var work_remainder: float = 0.0
var sword_level: int = 1
var boss_kills: int = 0
var cloak: bool = false
var equipped_cloak: bool = false
var total_gathered: int = 0
var area: String = "surface"
var player_position: Vector2 = Vector2(1024, 864)
var last_save: int = 0
var status_message: String = ""

func level(skill: String) -> int:
	return 1 + int(sqrt(float(xp.get(skill, 0)) / 20.0))

func add(item: String, count: int = 1) -> void:
	inventory[item] = int(inventory.get(item, 0)) + count

func afford(cost: Dictionary) -> bool:
	for item in cost:
		if int(inventory.get(item, 0)) < int(cost[item]):
			return false
	return true

func spend(cost: Dictionary) -> bool:
	if not afford(cost):
		return false
	for item in cost:
		inventory[item] -= cost[item]
	return true

func simulate_workers(seconds: float) -> Dictionary:
	var earned: Dictionary = {}
	if not workers.wood and not workers.ore:
		work_remainder = 0.0
		return earned
	work_remainder += maxf(0.0, seconds)
	var ticks: int = int(work_remainder / WORK_INTERVAL)
	work_remainder = fmod(work_remainder, WORK_INTERVAL)
	if ticks < 1:
		return earned
	for item in workers:
		if workers[item]:
			add(item, ticks)
			earned[item] = ticks
	return earned

func save_game() -> bool:
	var payload = {
		"version": SAVE_VERSION, "inventory": inventory, "xp": xp,
		"workers": workers, "work_remainder": work_remainder,
		"sword_level": sword_level, "boss_kills": boss_kills,
		"cloak": cloak, "equipped_cloak": equipped_cloak,
		"total_gathered": total_gathered, "area": area,
		"position": [player_position.x, player_position.y],
		"saved_at": int(Time.get_unix_time_from_system())
	}
	var file = FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		status_message = "Save failed: cannot write file."
		return false
	file.store_string(JSON.stringify(payload))
	file.flush()
	file.close()
	var absolute = ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(absolute, absolute + ".bak")
	var result = DirAccess.rename_absolute(absolute + ".tmp", absolute)
	if result != OK:
		status_message = "Save failed. Previous save preserved."
		return false
	last_save = payload.saved_at
	return true

func read_save(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var parser = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	var value = parser.data
	if not value is Dictionary or int(value.get("version", 0)) != SAVE_VERSION:
		return null
	for key in ["inventory", "xp", "workers"]:
		if not value.get(key) is Dictionary:
			return null
	if not value.get("position") is Array or value.position.size() != 2:
		return null
	return value

func load_game() -> Dictionary:
	var data = read_save(SAVE_PATH)
	if data == null:
		data = read_save(SAVE_PATH + ".bak")
		if data != null:
			status_message = "Recovered backup save."
	if data == null:
		return {}
	for item in inventory:
		inventory[item] = clampi(int(data.inventory.get(item, inventory[item])), 0, 100000000)
	for skill in xp:
		xp[skill] = clampi(int(data.xp.get(skill, 0)), 0, 100000000)
	for item in workers:
		workers[item] = bool(data.workers.get(item, false))
	work_remainder = clampf(float(data.get("work_remainder", 0)), 0, WORK_INTERVAL - 0.001)
	sword_level = clampi(int(data.get("sword_level", 1)), 1, 3)
	boss_kills = maxi(0, int(data.get("boss_kills", 0)))
	cloak = bool(data.get("cloak", false))
	equipped_cloak = cloak and bool(data.get("equipped_cloak", false))
	total_gathered = maxi(0, int(data.get("total_gathered", 0)))
	area = "mine" if data.get("area") == "mine" else "surface"
	player_position = Vector2(float(data.position[0]), float(data.position[1]))
	last_save = int(data.get("saved_at", Time.get_unix_time_from_system()))
	var seconds = clampf(Time.get_unix_time_from_system() - last_save, 0, OFFLINE_CAP)
	return simulate_workers(seconds)
