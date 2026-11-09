extends Node
## Процедурные звуки: синтезируются при запуске, никаких внешних файлов.

const RATE := 22050
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _last := {}
var volume := 0.8:
	set(v):
		volume = clampf(v, 0.0, 1.0)
		AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 16:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_streams["click"] = _tone([[900, 0.03]], 0.25, "square")
	_streams["hover"] = _tone([[1400, 0.015]], 0.08, "sine")
	_streams["coin"] = _tone([[1318, 0.06], [1976, 0.16]], 0.35, "sine")
	_streams["build"] = _tone([[523, 0.07], [659, 0.07], [784, 0.07], [1046, 0.18]], 0.35, "square")
	_streams["levelup"] = _tone([[523, 0.1], [659, 0.1], [784, 0.1], [1046, 0.1], [784, 0.08], [1046, 0.35]], 0.4, "saw")
	_streams["sabotage"] = _sweep(600, 120, 0.45, 0.4, true)
	_streams["hit"] = _sweep(300, 60, 0.5, 0.5, true)
	_streams["caught"] = _tone([[220, 0.18], [0, 0.05], [220, 0.18], [0, 0.05], [165, 0.4]], 0.45, "square")
	_streams["alarm"] = _siren()
	_streams["error"] = _tone([[180, 0.12]], 0.3, "square")
	_streams["good"] = _tone([[784, 0.08], [1046, 0.16]], 0.3, "sine")
	_streams["firework"] = _sweep(200, 1200, 0.25, 0.25, true)
	_streams["boom"] = _noise_burst(0.6, 0.5)
	_streams["win"] = _tone([[523, 0.15], [523, 0.08], [784, 0.15], [1046, 0.5]], 0.4, "saw")
	_streams["lose"] = _tone([[392, 0.25], [370, 0.25], [349, 0.25], [330, 0.7]], 0.4, "saw")
	_streams["chat"] = _tone([[1046, 0.04], [1318, 0.06]], 0.2, "sine")
	_streams["horn"] = _tone([[415, 0.18], [0, 0.06], [415, 0.4]], 0.3, "square")


	for i in 2:
		var m := AudioStreamPlayer.new()
		add_child(m)
		_music.append(m)
	for i in 2:
		var a := AudioStreamPlayer.new()
		a.volume_db = -80.0
		add_child(a)
		_amb.append(a)


const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
var _files := {}
var _music: Array[AudioStreamPlayer] = []
var _music_on := 0
var _music_name := ""
var _amb: Array[AudioStreamPlayer] = []
var _amb_names := ["", ""]


## Звук из assets/audio/sfx (name.wav и варианты name_1.wav, name_2.wav…) — из Jackpot Hotel.
func file_stream(name: String) -> AudioStream:
	if not _files.has(name):
		var list := []
		for p in [SFX_DIR + name + ".wav"]:
			if ResourceLoader.exists(p):
				list.append(load(p))
		var i := 1
		while ResourceLoader.exists(SFX_DIR + "%s_%d.wav" % [name, i]):
			list.append(load(SFX_DIR + "%s_%d.wav" % [name, i]))
			i += 1
		_files[name] = list
	var arr: Array = _files[name]
	return null if arr.is_empty() else arr[randi() % arr.size()]


func _stream(name: String) -> AudioStream:
	if _streams.has(name):
		return _streams[name]
	return file_stream(name)


func play(name: String, vol_db := 0.0, pitch := 1.0) -> void:
	var st := _stream(name)
	if st == null:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(name, -1000)) < 60:
		return
	_last[name] = now
	for p in _players:
		if not p.playing:
			p.stream = st
			p.volume_db = vol_db
			p.pitch_scale = pitch
			p.play()
			return


func play_3d(name: String, pos: Vector3, vol_db := 0.0, pitch := 1.0, max_dist := 30.0) -> void:
	var st := _stream(name)
	if st == null or Game.world == null or not is_instance_valid(Game.world):
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = st
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.max_distance = max_dist
	p.unit_size = 6.0
	Game.world.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()


## Музыка с плавной сменой. Пустое имя — тишина.
func music(name: String, vol_db := -12.0, fade := 1.5) -> void:
	if name == _music_name:
		return
	_music_name = name
	var old := _music[_music_on]
	_music_on = 1 - _music_on
	var nw := _music[_music_on]
	var tw := create_tween().set_parallel(true)
	tw.tween_property(old, "volume_db", -60.0, fade)
	tw.chain().tween_callback(old.stop)
	var path := MUSIC_DIR + name + ".ogg"
	if name == "" or not ResourceLoader.exists(path):
		return
	var st: AudioStream = load(path)
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = true
	nw.stream = st
	nw.volume_db = -60.0
	nw.play()
	create_tween().tween_property(nw, "volume_db", vol_db, fade)


## Фоновые петли: слот 0 — улица, слот 1 — зал казино. Громкость меняется плавно каждый кадр.
func ambient(slot: int, name: String, vol_db: float) -> void:
	var p := _amb[slot]
	if _amb_names[slot] != name:
		_amb_names[slot] = name
		var st := file_stream(name) if name != "" else null
		if st is AudioStreamWAV:
			st = (st as AudioStreamWAV).duplicate()
			st.loop_mode = AudioStreamWAV.LOOP_FORWARD
			st.loop_end = int(st.get_length() * st.mix_rate)
		p.stream = st
		if st:
			p.play()
		else:
			p.stop()
	p.volume_db = lerpf(p.volume_db, vol_db, 0.08)


func _wav(data: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w


func _osc(kind: String, ph: float) -> float:
	match kind:
		"square":
			return 1.0 if fmod(ph, 1.0) < 0.5 else -1.0
		"saw":
			return fmod(ph, 1.0) * 2.0 - 1.0
	return sin(ph * TAU)


func _tone(notes: Array, amp: float, kind: String) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	for n in notes:
		var f: float = n[0]
		var count := int(RATE * float(n[1]))
		var ph := 0.0
		for i in count:
			var env := minf(1.0, i / 200.0) * minf(1.0, (count - i) / 400.0)
			out.append(0.0 if f <= 0.0 else _osc(kind, ph) * amp * env * (0.6 if kind != "sine" else 1.0))
			ph += f / RATE
	return _wav(out)


func _sweep(f0: float, f1: float, dur: float, amp: float, noisy: bool) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	var count := int(RATE * dur)
	var ph := 0.0
	for i in count:
		var k := float(i) / count
		var f := lerpf(f0, f1, k)
		var v := sin(ph * TAU) * 0.7 + (randf_range(-1, 1) * 0.3 if noisy else 0.0)
		out.append(v * amp * (1.0 - k) * minf(1.0, i / 150.0))
		ph += f / RATE
	return _wav(out)


func _siren() -> AudioStreamWAV:
	var out := PackedFloat32Array()
	var count := int(RATE * 1.2)
	var ph := 0.0
	for i in count:
		var k := float(i) / RATE
		var f := 700.0 + 250.0 * sin(k * TAU * 2.5)
		out.append(_osc("square", ph) * 0.18 * minf(1.0, (count - i) / 2000.0))
		ph += f / RATE
	return _wav(out)


func _noise_burst(dur: float, amp: float) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	var count := int(RATE * dur)
	var lp := 0.0
	for i in count:
		var k := float(i) / count
		lp = lerpf(lp, randf_range(-1, 1), 0.15)
		out.append(lp * amp * 2.0 * pow(1.0 - k, 2.0))
	return _wav(out)
