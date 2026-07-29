extends AudioStreamPlayer

const MENU = preload("res://music/main menu bg.wav")
const ATMOS = preload("res://music/ambient music.wav")
const BOSS = preload("res://music/boss music.wav")	

var current_music: AudioStream

func play_music(song: AudioStream):
	if current_music == song:
		return

	current_music = song

	if playing:
		var tween = create_tween()

		tween.tween_property(self, "volume_db", -40.0, 1.0)

		await tween.finished

	stream = song
	play()

	# Start quiet and fade back in
	volume_db = -40.0

	var tween = create_tween()
	tween.tween_property(self, "volume_db", 0.0, 1.0)
