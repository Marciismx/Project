extends SceneTree
const ProgressScript = preload("res://scripts/progress.gd")

func _initialize() -> void:
	# Use a separate user-data directory when running this test.
	var p=ProgressScript.new()
	assert(p.simulate_workers(500).is_empty())
	assert(not p.spend({"wood":1}))
	p.workers.wood=true
	assert(p.simulate_workers(11).is_empty())
	assert(p.simulate_workers(1).wood==1)
	p.simulate_workers(-100)
	assert(p.inventory.wood==1)
	p.inventory.wood=42
	p.player_position=Vector2(120,240)
	p.area="mine"
	p.cloak=true
	p.equipped_cloak=true
	p.work_remainder=5
	assert(p.save_game())
	var q=ProgressScript.new()
	q.load_game()
	assert(q.inventory.wood==42)
	assert(q.player_position==Vector2(120,240))
	assert(q.area=="mine" and q.cloak and q.equipped_cloak)
	assert(q.save_game())
	# A corrupt primary must recover the previous atomic backup.
	var file=FileAccess.open(ProgressScript.SAVE_PATH,FileAccess.WRITE)
	file.store_string("invalid-json")
	file.close()
	var r=ProgressScript.new()
	r.load_game()
	assert(r.inventory.wood==42)
	assert(r.status_message=="Recovered backup save.")
	# Simulate a long absence using a real saved timestamp: cap at eight hours.
	assert(r.save_game())
	var payload=JSON.parse_string(FileAccess.get_file_as_string(ProgressScript.SAVE_PATH))
	payload.saved_at=int(Time.get_unix_time_from_system())-86400
	payload.work_remainder=0
	file=FileAccess.open(ProgressScript.SAVE_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify(payload));file.close()
	var offline=ProgressScript.new()
	var earned=offline.load_game()
	assert(earned.wood==2400,"Offline cap must be exactly eight hours")
	assert(offline.boss_kills==0 and offline.xp.combat==0)
	# Future timestamps must never remove items or award progress.
	payload.saved_at=int(Time.get_unix_time_from_system())+86400
	file=FileAccess.open(ProgressScript.SAVE_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify(payload));file.close()
	var future=ProgressScript.new()
	assert(future.load_game().is_empty())
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ProgressScript.SAVE_PATH+suffix))
	print("PROGRESS TESTS PASSED: costs, remainder, roundtrip, backup, offline cap, future clock, active reward isolation")
	quit()
