extends RefCounted
## The voyage's weather: pastel sky and sunlight, fog (with the telescope), and storms with rain
## and lightning. Owned by voyage.gd.

var voyage: Node3D


func _init(owner_voyage: Node3D) -> void:
	voyage = owner_voyage


func apply_fog(on: bool) -> void:
	var telescope: Node3D = voyage.get_node("Ship/Telescope")
	telescope.enabled = on
	telescope.visible = on
	var environment: Environment = voyage.get_node("WorldEnvironment").environment
	environment.fog_enabled = on
	if on:
		# Light enough that the deck (about 30 m from the camera) stays readable; the sea beyond fades.
		environment.fog_light_color = Color(0.72, 0.75, 0.78)
		environment.fog_density = 0.016
		environment.background_color = Color(0.72, 0.75, 0.78)
	else:
		environment.background_color = Color(0.62, 0.8, 0.93)


## A soft pastel sky, warm sunlight, a little glow on bright things (lanterns, glints).
func setup_sky() -> void:
	var environment: Environment = voyage.get_node("WorldEnvironment").environment
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.36, 0.62, 0.92)
	sky_material.sky_horizon_color = Color(0.8, 0.9, 0.98)
	sky_material.ground_horizon_color = Color(0.7, 0.86, 0.95)
	sky_material.ground_bottom_color = Color(0.2, 0.45, 0.7)
	sky_material.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.sky = sky
	if not voyage.contract.fog:
		environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.82, 0.86, 1.0)
	environment.ambient_light_energy = 0.75
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_white = 6.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.5
	environment.glow_bloom = 0.05
	environment.glow_hdr_threshold = 1.1
	var sun := voyage.get_node("Sun") as DirectionalLight3D
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 1.25
	sun.shadow_blur = 2.0
	if voyage.contract.storm:
		_setup_storm(sky_material, environment, sun)


## A storm: bruised purple sky, dim light, rough sea, rain around the camera, lightning now and then.
func _setup_storm(sky_material: ProceduralSkyMaterial, environment: Environment, sun: DirectionalLight3D) -> void:
	sky_material.sky_top_color = Color(0.22, 0.2, 0.32)
	sky_material.sky_horizon_color = Color(0.45, 0.45, 0.55)
	sky_material.ground_horizon_color = Color(0.4, 0.42, 0.5)
	environment.ambient_light_color = Color(0.6, 0.62, 0.78)
	environment.ambient_light_energy = 0.6
	sun.light_energy = 0.55
	sun.light_color = Color(0.8, 0.82, 0.95)
	var water: Node3D = voyage._water
	if water.has_method("set_storm"):
		water.set_storm(true)
	var rain := CPUParticles3D.new()
	rain.name = "Rain"
	rain.amount = 1400
	rain.lifetime = 0.9
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(30, 1, 22)
	var streak := QuadMesh.new()
	streak.size = Vector2(0.07, 1.4)
	var wet := StandardMaterial3D.new()
	wet.albedo_color = Color(0.85, 0.9, 1.0, 0.7)
	wet.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wet.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wet.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	streak.material = wet
	rain.mesh = streak
	rain.direction = Vector3(0.25, -1, 0)
	rain.spread = 4.0
	rain.gravity = Vector3(0, -30, 0)
	rain.initial_velocity_min = 18.0
	rain.initial_velocity_max = 24.0
	rain.position = Vector3(0, 16, 0)
	voyage._ship.add_child(rain)
	var lightning := Timer.new()
	lightning.name = "Lightning"
	lightning.wait_time = 9.0
	lightning.autostart = true
	lightning.timeout.connect(voyage._lightning)
	voyage.add_child(lightning)


func lightning() -> void:
	var environment: Environment = voyage.get_node("WorldEnvironment").environment
	var flash := voyage.create_tween()
	flash.tween_property(environment, "ambient_light_energy", 2.6, 0.05)
	flash.tween_property(environment, "ambient_light_energy", 0.6, 0.12)
	flash.tween_property(environment, "ambient_light_energy", 2.0, 0.05)
	flash.tween_property(environment, "ambient_light_energy", 0.6, 0.4)
	(voyage.get_node("Lightning") as Timer).wait_time = randf_range(7.0, 15.0)
