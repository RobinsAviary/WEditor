package weditor

import doom "shared:wodin/wodin"
import "core:strings"
import "core:fmt"
import "core:c"
import tfd "shared:tinyfiledialogs"

open_wad :: proc() {
	filter_patterns := [?]cstring {"*.wad", "*.WAD"}
	path := tfd.openFileDialog("Open WAD archive...", "", len(filter_patterns), raw_data(&filter_patterns), "WAD Archives", 0)
	fmt.println(path)

	if path != "" {
		string_path := strings.clone_from_cstring(path)
		wad, ok := doom.load_wad(string_path)
			if ok {
				unload_file(state.files[0])

				state.files[0] = {
					wad = wad,
					filename = string_path,
				}
				reset_scroll_bar()
				update_title()
			} else {
				tfd.messageBox("WAD read error", "Something went wrong while trying to read the WAD", "ok", "error", 1)
			}
	}
}

save_wad :: proc() {
	filename_c := strings.clone_to_cstring(state.files[0].filename, context.temp_allocator)
	filter_patterns := [?]cstring {"*.wad", "*.WAD"}

	path := tfd.saveFileDialog("Save WAD archive...", filename_c, len(filter_patterns), raw_data(&filter_patterns), "WAD Archives")

	if path != "" {
		fmt.println(path)
	}
}

create_wad :: proc() {
	id := tfd.messageBox("Create new WAD?", "Create a new WAD? This will overwrite any existing data you have open.", "okcancel", "question", 0)

	if id == 1 {
		unload_file(state.files[0])
		state.files[0] = {filename=strings.clone("untitled.wad")}
		reset_scroll_bar()
		update_title()
	}
}