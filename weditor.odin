package weditor

import rl "vendor:raylib"
import "vendor:raylib/rlgl"
import doom "shared:wodin/wodin"
import nfd "shared:nativefiledialog"
import "core:fmt"
import "core:strings"
import "core:math"

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
}

state: State

scroll: rl.Vector2
lump_viewer_size: rl.Vector2
visible_lumps: int = 32
scroll_content: rl.Rectangle
scroll_max: f32
scroll_offset: f32 = 48

update_gui_sizes :: proc() {
	visible_lumps = int((rl.GetScreenHeight()-48-4) / 12)

	lump_viewer_size = {192, f32(rl.GetScreenHeight()) - 48}

	update_scroll_bar()
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
	append(&state.files, File {})

	nfd.Init()
	
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(640, 480, "WEditor")
	update_gui_sizes()
}

step :: proc() {
	if rl.IsWindowResized() {
		update_gui_sizes()
	}
}

draw :: proc() {
	rl.ClearBackground(rl.RAYWHITE)

	rl.GuiEnableTooltip()
	rl.GuiSetTooltip("Create new WAD")
	if rl.GuiButton({0, 24, 24, 24}, "#8#") do create_wad()
	rl.GuiSetTooltip("Load WAD")
	if rl.GuiButton({24, 24, 24, 24}, "#5#") do open_wad()
	rl.GuiSetTooltip("Save WAD")
	if rl.GuiButton({48, 24, 24, 24}, "#6#") do save_wad()
	rl.GuiDisableTooltip()

	rl.GuiScrollPanel({0, 48, lump_viewer_size.x, lump_viewer_size.y}, nil, scroll_content, &scroll, nil)

	scalar := clamp((scroll.y * -1) / scroll_max, 0, 1)

	offset_max := int(get_current_file().wad.header.lumps) - visible_lumps
	if offset_max < 0 do offset_max = 0

	lump_offset := int(math.lerp(f32(0), f32(offset_max), scalar))

	rlgl.PushMatrix()
	rlgl.Translatef(0, scroll_offset, 0)
	for i := 0; i < visible_lumps; i += 1 {
		if i >= len(get_current_file().wad.directory.files) do break

		rl.DrawText(strings.clone_to_cstring(get_current_file().wad.directory.files[i + lump_offset].label), 4, (i32(i) * 12) + 4, 10, rl.DARKGRAY)
	}
	rlgl.PopMatrix()
}

unload_everything :: proc() {
	for file in state.files {
		wad := file.wad
		doom.unload_wad(&wad)
	}

	rl.CloseWindow()

	nfd.Quit()

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