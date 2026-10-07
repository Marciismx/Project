extends SceneTree
const WorldScript=preload("res://scripts/world.gd")

func _initialize() -> void:
	call_deferred("check_routes")

func check_routes() -> void:
	var world=WorldScript.new()
	root.add_child(world)
	for area in ["surface","mine"]:
		world.build(area)
		var spawn=Vector2i(32,27) if area=="surface" else Vector2i(9,33)
		var visited: Dictionary={spawn:true}
		var queue: Array[Vector2i]=[spawn]
		var index=0
		while index<queue.size():
			var p=queue[index]
			index+=1
			for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var n=p+d
				if not visited.has(n) and world.can_stand(Vector2(n)*32+Vector2(16,16)):
					visited[n]=true
					queue.append(n)
		for obj in world.objects:
			if obj.kind in ["house","dock"]: continue
			var reachable=false
			for cell in visited:
				if (Vector2(cell)*32+Vector2(16,16)).distance_to(obj.pos)<67:
					reachable=true
					break
			assert(reachable,"Unreachable: "+area+" / "+obj.title+" @ "+str(obj.pos))
		if area=="mine":
			assert(visited.has(Vector2i(56,20)),"Boss arena disconnected")
		print("ROUTES PASSED: ",area," / ",visited.size()," connected tiles / all interactions reachable")
	world.queue_free()
	quit()
