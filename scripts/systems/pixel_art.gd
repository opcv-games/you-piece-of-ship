extends RefCounted
## Pixel-art helpers (Olivier's sheets, see assets/art/CREDITS.md). Everything is drawn with
## nearest-neighbour filtering so pixels stay crisp. Crew sheets are recoloured per player once
## and cached: the pirate's blue clothes become the player's colour, the rest stays as drawn.

const SHEET := "res://assets/art/source/pixel/nes_pirate_sprite_sheet.png"
const EXPORT := "res://assets/art/export/pixel/"
const CELL := Vector2i(16, 24)
const PIXEL := 0.11 ## metres per pixel for the crew (24 px = 2.6 m: cartoon-big so they read from the camera)

## Animation blocks on the sheet: origin, rows (frames), frames per second.
const ANIMATIONS := {
	"walk": {"origin": Vector2i(16, 24), "frames": 4, "fps": 7.0},
	"run": {"origin": Vector2i(16, 120), "frames": 4, "fps": 10.0},
	"idle": {"origin": Vector2i(160, 120), "frames": 4, "fps": 3.0},
	"push": {"origin": Vector2i(160, 24), "frames": 4, "fps": 6.0},
	"pull": {"origin": Vector2i(160, 216), "frames": 4, "fps": 6.0},
	"hit": {"origin": Vector2i(344, 24), "frames": 1, "fps": 1.0},
	"carry": {"origin": Vector2i(344, 48), "frames": 1, "fps": 1.0},
}

## Sheet columns by screen direction (E, SE, S, SW, W, NW, N, NE), screen right = +X, down = +Z.
const COLUMN_FOR_OCTANT := [5, 4, 3, 2, 1, 0, 7, 6]

static var _crew_textures := {}
static var _textures := {}


## The crew sheet with the blue clothes recoloured (null colour = original blue).
static func crew_texture(tint: Variant) -> Texture2D:
	var key := str(tint)
	if _crew_textures.has(key):
		return _crew_textures[key]
	var image := _image(SHEET)
	if tint is Color:
		for y in image.get_height():
			for x in image.get_width():
				var c := image.get_pixel(x, y)
				if c.a > 0.5 and c.b > 0.3 and c.b > c.r + 0.15 and c.b > c.g + 0.1:
					var shade := clampf(0.35 + c.b * 0.75, 0.0, 1.15)
					image.set_pixel(x, y, Color(tint.r * shade, tint.g * shade, tint.b * shade, c.a))
	var texture := ImageTexture.create_from_image(image)
	_crew_textures[key] = texture
	return texture


## A cut texture from assets/art/export/pixel/ (deck, hull, trim, crate, plank, pin, coal, sail...).
static func texture(name: String) -> Texture2D:
	if not _textures.has(name):
		_textures[name] = ImageTexture.create_from_image(_image(EXPORT + name + ".png"))
	return _textures[name]


## An imported image as plain RGBA pixels (works in the editor and in exported builds alike).
static func _image(path: String) -> Image:
	var image := (load(path) as Texture2D).get_image()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	return image


## Sheet column for a facing direction on screen (x right, y down).
static func column_for(direction: Vector2) -> int:
	var octant := posmod(roundi(atan2(direction.y, direction.x) / (PI / 4.0)), 8)
	return COLUMN_FOR_OCTANT[octant]


static func frame_rect(animation: String, column: int, frame: int) -> Rect2:
	var a: Dictionary = ANIMATIONS[animation]
	var origin: Vector2i = a.origin
	return Rect2(origin.x + CELL.x * column, origin.y + CELL.y * (frame % int(a.frames)), CELL.x, CELL.y)


## A crisp, unshaded, camera-facing sprite standing on its feet.
static func make_sprite(tex: Texture2D, pixel_size: float, billboard := true) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = tex
	sprite.pixel_size = pixel_size
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.centered = true
	sprite.offset = Vector2(0, tex.get_height() * 0.5) # feet on the deck
	return sprite


## A tiling, pixel-crisp material for ship parts (triplanar: no UV work on simple boxes).
static func tiled_material(name: String, metres_per_tile: Vector2, tint := Color.WHITE) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture(name)
	material.albedo_color = tint
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.uv1_triplanar = true
	var across := 1.0 / metres_per_tile.x
	material.uv1_scale = Vector3(across, 1.0 / metres_per_tile.y, across)
	return material
