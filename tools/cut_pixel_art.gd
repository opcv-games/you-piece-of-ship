extends SceneTree
## Cuts the game's pixel-art textures out of Olivier's source sheets (assets/art/source/pixel/).
## Run from the project folder:  godot --headless -s tools/cut_pixel_art.gd
## Outputs go to assets/art/export/pixel/. Coordinates were read off the sheets on a pixel grid.

const TILES := "res://assets/art/source/pixel/pirate_ship_tile_set.png"
const OUT := "res://assets/art/export/pixel/"

## name -> [x, y, w, h, rotate_quarter_turns]
const CROPS := {
	"deck": [208, 480, 64, 64, 1], # red deck planks, turned to run along the ship; tiles seamlessly
	"hull": [56, 96, 32, 8, 0], # dark brown hull planks
	"trim": [40, 104, 64, 8, 0], # orange rail trim
	"crate": [208, 280, 16, 16, 0],
	"sack": [224, 280, 16, 16, 0],
	"coal": [288, 304, 16, 16, 0],
	"cannon": [256, 296, 16, 24, 0],
	"table": [352, 296, 48, 32, 0],
	"plank": [416, 232, 8, 32, 1], # an oar-like plank, carried sideways
	"pin": [304, 280, 8, 40, 1], # the iron pin, carried sideways
	"sail": [776, 0, 96, 366, 0],
}


func _initialize() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(TILES))
	sheet.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for name in CROPS:
		var c: Array = CROPS[name]
		var part := sheet.get_region(Rect2i(c[0], c[1], c[2], c[3]))
		_clear_white(part)
		for i in c[4]:
			part.rotate_90(CLOCKWISE)
		if name == "sail":
			_canvas(part)
		part.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
		print("cut ", name, " ", part.get_size())
	_make_shovel(sheet)
	_make_menu_background()
	quit()


## The right part of Olivier's menu mockup (the painted deck, without the mockup's own buttons,
## tagline and badge) becomes the menu background.
func _make_menu_background() -> void:
	var mock := Image.load_from_file(ProjectSettings.globalize_path("res://assets/art/source/ui/main_menu_mockup.png"))
	var part := mock.get_region(Rect2i(540, 0, 860, 941))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/art/export/ui/"))
	part.save_png(ProjectSettings.globalize_path("res://assets/art/export/ui/menu_background.png"))
	print("cut menu_background")


## No shovel on the sheets: draw one (wooden handle, iron blade) and heap the coal lumps on it.
func _make_shovel(sheet: Image) -> void:
	var image := Image.create(28, 14, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var wood := Color(0.55, 0.33, 0.15)
	var dark := Color(0.08, 0.06, 0.05)
	for x in range(1, 16):
		var y := 3 + int(x * 0.3)
		image.set_pixel(x, y, wood)
		image.set_pixel(x, y + 1, wood.darkened(0.3))
	for x in range(15, 27):
		for y in range(5, 13):
			image.set_pixel(x, y, Color(0.45, 0.47, 0.5) if y > 9 else dark)
	var lumps := sheet.get_region(Rect2i(288, 304, 16, 16))
	_clear_white(lumps)
	lumps.resize(11, 8, Image.INTERPOLATE_NEAREST)
	image.blend_rect(lumps, Rect2i(0, 0, 11, 8), Vector2i(15, 2))
	image.save_png(ProjectSettings.globalize_path(OUT + "shovel_coal.png"))
	print("drew shovel_coal")


## The sheets use white (and sky blue) as background: make those transparent.
func _clear_white(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.r > 0.95 and c.g > 0.95 and c.b > 0.95:
				image.set_pixel(x, y, Color(0, 0, 0, 0))


## The sheet's sail is a black silhouette; on a blue sea that reads as a shadow. Paint it canvas
## (the grey rigging lines stay).
func _canvas(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a > 0.5 and c.r < 0.15 and c.g < 0.15 and c.b < 0.15:
				image.set_pixel(x, y, Color(0.93, 0.88, 0.76))
