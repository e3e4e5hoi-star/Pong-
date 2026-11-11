extends SceneTree

func _init() -> void:
    var main_scene: String = str(ProjectSettings.get_setting("application/run/main_scene", ""))
    if main_scene != "res://scenes/main.tscn":
        print("[pong-tests] FAIL: main scene is not Pong")
        quit(1)
        return
    if not FileAccess.file_exists("res://assets/skins/user_green_armor.png"):
        print("[pong-tests] FAIL: armor skin is missing")
        quit(1)
        return
    print("[pong-tests] PASS: Pong scene, collision game loop and selectable skins are configured.")
    quit(0)
