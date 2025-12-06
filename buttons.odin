package weditor

import nfd "shared:nativefiledialog"
import doom "shared:wodin/wodin"
import "core:strings"
import sdl "vendor:sdl2"
import "core:fmt"
import "core:c"

open_wad :: proc() {
	path: cstring
	filters := [?]nfd.Filter_Item {{"WAD", "wad,WAD"}}
	args := nfd.Open_Dialog_Args {
		filter_list = raw_data(filters[:]),
		filter_count = len(filters)
	}

	result := nfd.OpenDialogU8_With(&path, &args)
	switch result {
		case .Okay:
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
				sdl.ShowSimpleMessageBox({.ERROR}, "WAD read error", "Something went wrong while trying to read the WAD", nil)
			}
			nfd.FreePathU8(path)
		case .Error:
			error_message := fmt.aprint("An error occured while trying to open the WAD:", nfd.GetError())
			error_message_c := strings.clone_to_cstring(error_message)
			
			sdl.ShowSimpleMessageBox({.ERROR}, "Error opening WAD", error_message_c, nil)
			delete(error_message_c)
			delete(error_message)
		case .Cancel:
			// pass
	}
}

save_wad :: proc() {
	path: cstring
	filters := [?]nfd.Filter_Item {{"WAD", "wad,WAD"}}
	name := path_to_filename(state.files[0].filename, context.temp_allocator)
	directory := path_to_directory(state.files[0].filename, context.temp_allocator)
	directory_c := strings.clone_to_cstring(directory, context.temp_allocator)
	fmt.println(directory)
	name_c := strings.clone_to_cstring(name, context.temp_allocator)
	fmt.println(state.files[0].filename)
	args := nfd.Save_Dialog_Args {
		filter_list = raw_data(filters[:]),
		filter_count = len(filters),
		default_name = name_c,
		default_path = directory_c
	}
	
	result := nfd.SaveDialogU8_With(&path, &args)
	switch result {
		case .Okay:
			fmt.println(path)
			nfd.FreePathU8(path)
		case .Error:
			error_message := fmt.aprint("An error occured while trying to save the WAD:", nfd.GetError())
			error_message_c := strings.clone_to_cstring(error_message)
			
			sdl.ShowSimpleMessageBox({.ERROR}, "Error saving WAD", error_message_c, nil)
			delete(error_message_c)
			delete(error_message)
		case .Cancel:
			// pass
	}
}

create_wad :: proc() {
	button_data := [?]sdl.MessageBoxButtonData {
		{
			{.RETURNKEY_DEFAULT},
			0,
			"Ok",
		},
		{
			{.ESCAPEKEY_DEFAULT},
			1,
			"Cancel",
		}
	}

	data := sdl.MessageBoxData {
		flags = {.INFORMATION, .BUTTONS_LEFT_TO_RIGHT},
		title = "Create new WAD?",
		message = "Create a new WAD? This will overwrite any existing data you have open.",
		numbuttons = 2,
		buttons = raw_data(&button_data)
	}

	id: c.int

	sdl.ShowMessageBox(&data, &id)

	if id == 0 {
		unload_file(state.files[0])
		state.files[0] = {filename=strings.clone("untitled.wad")}
		reset_scroll_bar()
		update_title()
	}
}