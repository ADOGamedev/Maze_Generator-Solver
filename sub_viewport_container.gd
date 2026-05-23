extends SubViewportContainer

func _input(event: InputEvent) -> void:
    $SubViewport/main/Camera2D.input(event)