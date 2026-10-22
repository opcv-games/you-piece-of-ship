"""Shared helpers for the Blender build scripts (run headless:  blender -b -P tools/blender/<script>.py).
Coordinates are written in GAME space (x = bow, y = up, z = starboard) and converted to Blender
(x, -z, y), so exported .glb files land in Godot exactly where the gameplay expects them.
Materials are only named slots; Godot paints them with the toon shader (scripts/systems/toon.gd)."""
import math
import bmesh
import bpy
from mathutils import Vector

PREVIEW = {  # rough colours so the .blend looks right when opened; the game uses its own palette
    "wood_hull": (0.55, 0.32, 0.18), "wood_light": (0.85, 0.65, 0.42), "wood_dark": (0.32, 0.18, 0.1),
    "deck": (0.86, 0.7, 0.48), "paint_red": (0.86, 0.3, 0.27), "paint_teal": (0.2, 0.62, 0.66),
    "trim_cream": (0.98, 0.92, 0.78), "gold": (1.0, 0.78, 0.25), "iron": (0.25, 0.25, 0.3),
    "sail": (0.98, 0.95, 0.86), "rope": (0.78, 0.66, 0.45), "glow": (1.0, 0.85, 0.4),
    "glass": (0.2, 0.3, 0.45), "rock": (0.55, 0.55, 0.6), "rock_dark": (0.38, 0.38, 0.45),
    "moss": (0.45, 0.68, 0.38), "sand": (0.98, 0.86, 0.6), "leaf": (0.35, 0.72, 0.32),
    "whale": (0.32, 0.45, 0.72), "belly": (0.88, 0.9, 0.95), "skin": (1.0, 0.8, 0.68),
    "eye": (0.08, 0.06, 0.1), "white": (1, 1, 1), "blush": (1.0, 0.55, 0.6), "tail": (0.3, 0.75, 0.7),
    "hair": (0.95, 0.45, 0.55), "flag": (0.85, 0.25, 0.25), "coal": (0.12, 0.12, 0.14), "water": (0.4, 0.75, 0.95),
    "player": (0.9, 0.9, 0.9),
}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def g(x, y, z):
    """Game coordinates -> Blender coordinates."""
    return Vector((x, -z, y))


def material(name):
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
        rgb = PREVIEW.get(name, (0.8, 0.8, 0.8))
        mat.diffuse_color = (*rgb, 1.0)
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    return mat


def collection(name):
    col = bpy.data.collections.get(name)
    if col is None:
        col = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(col)
    return col


CURRENT = {"col": None}


def into(name):
    CURRENT["col"] = collection(name)


def link(obj):
    col = CURRENT["col"] or bpy.context.scene.collection
    for c in obj.users_collection:
        c.objects.unlink(obj)
    col.objects.link(obj)
    return obj


def finish(obj, mat_name=None, smooth=True, subdiv=0, bevel=0.0, solidify=0.0):
    if mat_name:
        obj.data.materials.clear()
        obj.data.materials.append(material(mat_name))
    if smooth:
        for poly in obj.data.polygons:
            poly.use_smooth = True
    if bevel:
        m = obj.modifiers.new("Bevel", "BEVEL")
        m.width = bevel
        m.segments = 3
        m.limit_method = "ANGLE"
    if solidify:
        m = obj.modifiers.new("Solidify", "SOLIDIFY")
        m.thickness = solidify
        m.offset = -1.0
    if subdiv:
        m = obj.modifiers.new("Subdivision", "SUBSURF")
        m.levels = subdiv
        m.render_levels = subdiv
    return obj


def _op_obj(name):
    obj = bpy.context.active_object
    obj.name = name
    obj.data.name = name
    return link(obj)


def box(name, centre, size, mat=None, bevel=0.06, rot=(0, 0, 0)):
    """size in game axes (x length, y height, z width)."""
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=g(*centre))
    obj = _op_obj(name)
    obj.scale = (size[0], size[2], size[1])
    obj.rotation_euler = (rot[0], -rot[2], rot[1])
    bpy.ops.object.transform_apply(scale=True, rotation=True, location=False)
    return finish(obj, mat, smooth=bevel > 0, bevel=bevel)


def cylinder(name, a, b, r1, r2=None, mat=None, verts=16, cap=True):
    """A (tapered) cylinder between two game-space points."""
    r2 = r1 if r2 is None else r2
    pa, pb = g(*a), g(*b)
    axis = pb - pa
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r1, radius2=r2, depth=axis.length,
                                    end_fill_type="NGON" if cap else "NOTHING", location=(pa + pb) / 2)
    obj = _op_obj(name)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(axis.normalized())
    bpy.ops.object.transform_apply(rotation=True, location=False, scale=False)
    return finish(obj, mat)


def sphere(name, centre, radius, mat=None, scale=(1, 1, 1), segments=20, rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=radius, location=g(*centre))
    obj = _op_obj(name)
    obj.scale = (scale[0], scale[2], scale[1])
    bpy.ops.object.transform_apply(scale=True, rotation=False, location=False)
    return finish(obj, mat)


def torus(name, centre, major, minor, mat=None, axis="y"):
    rot = {"y": (0, 0, 0), "x": (0, math.pi / 2, 0), "z": (math.pi / 2, 0, 0)}[axis]
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=32, minor_segments=10,
                                     location=g(*centre), rotation=rot)
    obj = _op_obj(name)
    bpy.ops.object.transform_apply(rotation=True, location=False, scale=False)
    return finish(obj, mat)


def mesh_from(name, verts, faces, mat=None, smooth=True):
    me = bpy.data.meshes.new(name)
    me.from_pydata([g(*v) for v in verts], [], faces)
    me.update()
    obj = bpy.data.objects.new(name, me)
    link(obj)
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    return finish(obj, mat, smooth=smooth)


def set_face_materials(obj, rule):
    """rule(centre_in_game_space) -> material name, per face."""
    names = []
    for poly in obj.data.polygons:
        c = poly.center
        name = rule((c.x, c.z, -c.y))
        if name not in names:
            names.append(name)
    obj.data.materials.clear()
    for name in names:
        obj.data.materials.append(material(name))
    for poly in obj.data.polygons:
        c = poly.center
        poly.material_index = names.index(rule((c.x, c.z, -c.y)))


def parent_all(root_name, objects):
    root = bpy.data.objects.new(root_name, None)
    link(root)
    for obj in objects:
        obj.parent = root
    return root


def export(col_name, path):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in collection(col_name).all_objects:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, use_selection=True, export_apply=True, export_yup=True,
                              export_format="GLB", export_materials="EXPORT", export_normals=True,
                              export_texcoords=True, export_animations=False)


def save(path):
    bpy.ops.wm.save_as_mainfile(filepath=path)
