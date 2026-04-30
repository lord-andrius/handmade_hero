package wayland

import "base:runtime"
import "core:sys/linux"

Wl_Keyboard_Requests :: enum (u32) {
	release,
}

Wl_Keyboard_Events :: enum (u32) {
	keymap,
	enter,
	leave,
	key,
	modifiers,
	repeat_info,
}

Wl_Keyboard_Keymap_Event_Callback :: proc(
	user_data: rawptr,
	wl_keyboard: u32,
	format: Keymap_Format,
	fd: linux.Fd,
	size: u32,
)

Wl_Keyboard_Enter_Event_Callback :: proc(
	user_data: rawptr,
	wl_keyboard: u32,
	serial: u32,
	surface: u32,
	keys: []u32,
)

Wl_Keyboard_Leave_Event_Callback :: proc(
	user_data: rawptr,
	wl_keyboard: u32,
	serial: u32,
	surface: u32,
)

Wl_Keyboard_Key_Event_Callback :: proc(
	user_data: rawptr,
	wl_keyboard: u32,
	serial: u32,
	time: u32,
	key: u32,
	state: Key_State,
)

Wl_Keyboard_Modifiers_Event_callback :: proc(
	user_data: rawptr,
	wl_keyboard: u32,
	serial: u32,
	mods_depressed: u32,
	mods_latched: u32,
	mods_locked: u32,
	group: u32,
)

Wl_Keyboard_Repeat_Info_Event_Callback :: proc(
	user_data: rawptr,
	wl_keyboard: u32,
	rate: i32,
	delay: i32,
)

Wl_Keyboard_Events_Callbacks :: map[u32]struct {
	callbacks: [Wl_Keyboard_Events]rawptr,
	user_data: [Wl_Keyboard_Events]rawptr,
}

wl_keyboard_events_callbacks: Wl_Keyboard_Events_Callbacks = nil

Keymap_Format :: enum (u32) {
	no_keymap,
	xkb_v1,
}

Key_State :: enum (u32) {
	released,
	pressed,
	repeated,
}

wl_keyboard_release :: proc(wl_keyboard: u32) -> bool {
	delete_id(wl_keyboard)
	delete_key(&wl_keyboard_events_callbacks, wl_keyboard)
	msg: Message
	set_message_object(&msg, wl_keyboard)
	set_message_opcode(&msg, u16(Wl_Keyboard_Requests.release))
	set_message_length_based_on_args_length(&msg)
	_, ok := write_message(msg)
	return ok
}

wl_keyboard_set_keymap_callback :: proc(
	wl_keyboard: u32,
	user_data: rawptr,
	callback: Wl_Keyboard_Keymap_Event_Callback,
) {
	if wl_keyboard_events_callbacks == nil {
		wl_keyboard_events_callbacks = make(type_of(wl_keyboard_events_callbacks))
	}

	if c, ok := &wl_keyboard_events_callbacks[wl_keyboard]; ok {
		c.callbacks[.keymap] = rawptr(callback)
		c.user_data[.keymap] = user_data
	} else {
		wl_keyboard_events_callbacks[wl_keyboard] = {
			callbacks = #partial{.keymap = rawptr(callback)},
			user_data = #partial{.keymap = user_data},
		}
	}
}

wl_keyboard_set_enter_callback :: proc(
	wl_keyboard: u32,
	user_data: rawptr,
	callback: Wl_Keyboard_Enter_Event_Callback,
) {
	if wl_keyboard_events_callbacks == nil {
		wl_keyboard_events_callbacks = make(type_of(wl_keyboard_events_callbacks))
	}

	if c, ok := &wl_keyboard_events_callbacks[wl_keyboard]; ok {
		c.callbacks[.enter] = rawptr(callback)
		c.user_data[.enter] = user_data
	} else {
		wl_keyboard_events_callbacks[wl_keyboard] = {
			callbacks = #partial{.enter = rawptr(callback)},
			user_data = #partial{.enter = user_data},
		}
	}
}

wl_keyboard_set_leave_callback :: proc(
	wl_keyboard: u32,
	user_data: rawptr,
	callback: Wl_Keyboard_Leave_Event_Callback,
) {
	if wl_keyboard_events_callbacks == nil {
		wl_keyboard_events_callbacks = make(type_of(wl_keyboard_events_callbacks))
	}

	if c, ok := &wl_keyboard_events_callbacks[wl_keyboard]; ok {
		c.callbacks[.leave] = rawptr(callback)
		c.user_data[.leave] = user_data
	} else {
		wl_keyboard_events_callbacks[wl_keyboard] = {
			callbacks = #partial{.leave = rawptr(callback)},
			user_data = #partial{.leave = user_data},
		}
	}
}

wl_keyboard_set_key_callback :: proc(
	wl_keyboard: u32,
	user_data: rawptr,
	callback: Wl_Keyboard_Key_Event_Callback,
) {
	if wl_keyboard_events_callbacks == nil {
		wl_keyboard_events_callbacks = make(type_of(wl_keyboard_events_callbacks))
	}

	if c, ok := &wl_keyboard_events_callbacks[wl_keyboard]; ok {
		c.callbacks[.key] = rawptr(callback)
		c.user_data[.key] = user_data
	} else {
		wl_keyboard_events_callbacks[wl_keyboard] = {
			callbacks = #partial{.key = rawptr(callback)},
			user_data = #partial{.key = user_data},
		}
	}
}

wl_keyboard_set_modifiers_callback :: proc(
	wl_keyboard: u32,
	user_data: rawptr,
	callback: Wl_Keyboard_Modifiers_Event_callback,
) {
	if wl_keyboard_events_callbacks == nil {
		wl_keyboard_events_callbacks = make(type_of(wl_keyboard_events_callbacks))
	}

	if c, ok := &wl_keyboard_events_callbacks[wl_keyboard]; ok {
		c.callbacks[.modifiers] = rawptr(callback)
		c.user_data[.modifiers] = user_data
	} else {
		wl_keyboard_events_callbacks[wl_keyboard] = {
			callbacks = #partial{.modifiers = rawptr(callback)},
			user_data = #partial{.modifiers = user_data},
		}
	}
}

wl_keyboard_set_repeat_info_callback :: proc(
	wl_keyboard: u32,
	user_data: rawptr,
	callback: Wl_Keyboard_Repeat_Info_Event_Callback,
) {
	if wl_keyboard_events_callbacks == nil {
		wl_keyboard_events_callbacks = make(type_of(wl_keyboard_events_callbacks))
	}

	if c, ok := &wl_keyboard_events_callbacks[wl_keyboard]; ok {
		c.callbacks[.repeat_info] = rawptr(callback)
		c.user_data[.repeat_info] = user_data
	} else {
		wl_keyboard_events_callbacks[wl_keyboard] = {
			callbacks = #partial{.repeat_info = rawptr(callback)},
			user_data = #partial{.repeat_info = user_data},
		}
	}
}

wl_keyboard_dispatch :: proc(msg: Message) {
	wl_keyboard := get_message_object_id(msg)
	event := Wl_Keyboard_Events(get_message_opcode(msg))
	callback, ok := wl_keyboard_events_callbacks[wl_keyboard]
	if !ok {
		return
	}
	switch event {
		case . keymap:
			// nota fd está no control
			if callback.callbacks[.keymap] == nil do return
			args_index := 0
			format: u32
			fd: i32
			size: u32
			format, args_index = read_uint_from_message_args(msg)
			//fd, args_index = read_int_from_message_args(msg, args_index)
			size, args_index = read_uint_from_message_args(msg,  args_index)
			Wl_Keyboard_Keymap_Event_Callback(callback.callbacks[.keymap])(
				callback.user_data[.keymap],
				wl_keyboard,
				Keymap_Format(format),
				linux.Fd(fd),
				size
			)
		case .enter:
			if callback.callbacks[.enter] == nil do return
			args_index := 0
			serial: u32
			surface: u32
			keys: []u8
			serial, args_index = read_uint_from_message_args(msg, args_index)
			surface, args_index = read_uint_from_message_args(msg, args_index)
			keys, args_index = read_array_from_message_args(msg, args_index)
			Wl_Keyboard_Enter_Event_Callback(callback.callbacks[.enter])(
				callback.callbacks[.enter],
				wl_keyboard,
				serial,
				surface,
				transmute([]u32)runtime.Raw_Slice {
					data = &keys[0],
					len = len(keys) / size_of(u32),	
				},
			)

		case .leave:
			if callback.callbacks[.leave] == nil do return
			args_index := 0
			serial: u32
			surface: u32
			serial, args_index = read_uint_from_message_args(msg, args_index)
			surface, args_index = read_uint_from_message_args(msg, args_index)
			Wl_Keyboard_Leave_Event_Callback(callback.callbacks[.leave])(
				callback.user_data[.leave],
				wl_keyboard,
				serial,
				surface
			)
		case .key:
			if callback.callbacks[.key] == nil do return
			args_index := 0
			serial: u32
			time: u32
			key: u32
			state: u32
			serial, args_index = read_uint_from_message_args(msg, args_index)
			time, args_index = read_uint_from_message_args(msg, args_index)
			key, args_index = read_uint_from_message_args(msg, args_index)
			state, args_index = read_uint_from_message_args(msg, args_index)
			Wl_Keyboard_Key_Event_Callback(callback.callbacks[.key])(
				callback.user_data[.key],
				wl_keyboard,
				serial,
				time,
				key,
				Key_State(state)
			)
		case .modifiers:
			if callback.callbacks[.modifiers] == nil do return
			args_index := 0
			serial: u32
			mods_depressed: u32
			mods_latched: u32
			mods_locked: u32
			group: u32
			serial, args_index = read_uint_from_message_args(msg, args_index)
			mods_depressed, args_index = read_uint_from_message_args(msg, args_index)
			mods_latched, args_index = read_uint_from_message_args(msg, args_index)
			mods_locked, args_index = read_uint_from_message_args(msg, args_index)
			group, args_index = read_uint_from_message_args(msg, args_index)
			Wl_Keyboard_Modifiers_Event_callback(callback.callbacks[.modifiers])(
				callback.user_data[.modifiers],
				wl_keyboard,
				serial,
				mods_depressed,
				mods_latched,
				mods_locked,
				group,
			)
		case .repeat_info:
			if callback.callbacks[.repeat_info] == nil do return
			args_index := 0
			rate: i32
			delay: i32
			rate, args_index = read_int_from_message_args(msg, args_index)
			delay, args_index = read_int_from_message_args(msg, args_index)
			Wl_Keyboard_Repeat_Info_Event_Callback(callback.callbacks[.repeat_info])(
				callback.user_data[.repeat_info],
				wl_keyboard,
				rate,
				delay
			)
	}
}
