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
	quit()


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
