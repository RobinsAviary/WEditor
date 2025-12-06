package weditor

import rl "vendor:raylib"
import "vendor:raylib/rlgl"
import doom "shared:wodin/wodin"
import "core:fmt"
import "core:strings"
import "core:math"
import "core:c"
import "core:path/filepath"

PROGRAM_NAME :: "WEditor"

get_current_file :: proc() -> (file: ^File) {
	return &state.files[state.current_file]
}

State :: struct {
	files: [dynamic]File,
	current_file: int,
}

File :: struct {
	wad: doom.Wad,
	filename: string,
	unsaved_changes: bool,
}

state: State

scroll: rl.Vector2
lump_viewer_size: rl.Vector2
visible_lumps: int = 32
scroll_content: rl.Rectangle
scroll_max: f32
scroll_offset: f32 = 48

update_gui_sizes :: proc() {
	visible_lumps = ((int(rl.GetScreenHeight())-48-4) / 12)

	lump_viewer_size = {192, f32(rl.GetScreenHeight()) - 48}

	update_scroll_bar()
}

path_to_filename :: proc(path: string, allocator := context.allocator) -> (filename: string) {
	slashpath, _ := filepath.to_slash(path, allocator)
	last_slash := strings.last_index(slashpath, "/")
	if last_slash != -1 {
		filename = slashpath[last_slash + 1:]
	} else {
		filename = path
	}

	return
}

path_to_directory :: proc(path: string, allocator := context.allocator, loc := #caller_location) -> (directory: string) {
	slashpath, slash_allocated := filepath.to_slash(path, allocator)
	last_slash := strings.last_index(slashpath, "/")
	if last_slash != -1 {
		directoryslash: string = slashpath[:last_slash]
		directoryregular, _ := filepath.from_slash(directoryslash, allocator)
		directory = directoryregular
	}
	if slash_allocated do delete(slashpath, allocator, loc)

	return
}

update_title :: proc() {
	file := get_current_file()

	filename := path_to_filename(file.filename, context.temp_allocator)

	title := fmt.aprint(PROGRAM_NAME, "-", filename, allocator = context.temp_allocator)
	title_c := strings.clone_to_cstring(title, allocator = context.temp_allocator)

	rl.SetWindowTitle(title_c)
}

update_scroll_bar :: proc() {
	scroll_content = {0, 0, lump_viewer_size.x-14, 8 + (f32(len(get_current_file().wad.directory.files)) * 12)}
	scroll_max = scroll_content.height - lump_viewer_size.y + 1
}

reset_scroll_bar :: proc() {
	scroll = {}
	update_scroll_bar()
}

init :: proc() {
	append(&state.files, File {filename=strings.clone("untitled.wad")})
	
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(640, 480, PROGRAM_NAME)

	rl.GuiLoadStyle("dark.rgs")

	update_gui_sizes()
	update_title()
}

step :: proc() {
	if rl.IsWindowResized() {
		update_gui_sizes()
	}
}

draw :: proc() {
	rl.ClearBackground(rl.GetColor(u32(rl.GuiGetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.BACKGROUND_COLOR)))))

	rl.GuiScrollPanel({0, 48, lump_viewer_size.x, lump_viewer_size.y}, nil, scroll_content, &scroll, nil)

	rl.GuiEnableTooltip()
	rl.GuiSetTooltip("Create new WAD")
	if rl.GuiButton({0, 24, 24, 24}, "#8#") {
		create_wad()
		
	}
	rl.GuiSetTooltip("Load WAD")
	if rl.GuiButton({24, 24, 24, 24}, "#5#") do open_wad()
	rl.GuiSetTooltip("Save WAD")
	if rl.GuiButton({48, 24, 24, 24}, "#6#") do save_wad()
	rl.GuiDisableTooltip()
	viewer_buttons_offset := rl.Vector2 {lump_viewer_size.x, scroll_offset}
	rl.GuiButton({viewer_buttons_offset.x, viewer_buttons_offset.y, 24, 24}, "#8#")
	rl.GuiButton({viewer_buttons_offset.x, viewer_buttons_offset.y + 24, 24, 24}, "#9#")
	rl.GuiButton({viewer_buttons_offset.x, viewer_buttons_offset.y + 48, 24, 24}, "#117#")
	rl.GuiButton({viewer_buttons_offset.x, viewer_buttons_offset.y + (24 * 3), 24, 24}, "#116#")

	scalar := clamp((scroll.y * -1) / scroll_max, 0, 1)

	offset_max := int(get_current_file().wad.header.lumps) - visible_lumps
	if offset_max < 0 do offset_max = 0

	lump_offset := int(math.lerp(f32(0), f32(offset_max), scalar))

	rlgl.PushMatrix()
	rlgl.Translatef(0, scroll_offset, 0)
	rl.BeginScissorMode(0 + 1, 48 + 1, c.int(lump_viewer_size.x) - 14, c.int(lump_viewer_size.y - 2))
	for i := 0; i < visible_lumps; i += 1 {
		if i >= len(get_current_file().wad.directory.files) do break

		rl.DrawText(strings.clone_to_cstring(get_current_file().wad.directory.files[i + lump_offset].label), 4, (i32(i) * 12) + 4, 10, rl.GetColor(u32(rl.GuiGetStyle(.LABEL, i32(rl.GuiControlProperty.TEXT_COLOR_NORMAL)))))
	}
	rl.EndScissorMode()
	rlgl.PopMatrix()
}

unload_file :: proc(file: File) {
	delete(file.filename)
	wad := file.wad
	doom.unload_wad(&wad)
}

unload_everything :: proc() {
	for file in state.files {
		unload_file(file)
	}

	rl.CloseWindow()

	delete(state.files)
}

main :: proc() {
	init()

	for !rl.WindowShouldClose() {
		step()

		rl.BeginDrawing()

		draw()
		
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}

	unload_everything()
}