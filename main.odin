package main

import "core:fmt"
import "wayland"

main :: proc() {
	wayland.connect()
	//msg := wayland.make_message(1, 1, []u8{2, 0, 0, 0})
	msg: wayland.Message
	msg_buffer: [4]u8
	wayland.set_message_object(&msg, 1)
	wayland.set_message_opcode(&msg, 1)
	msg.arguments = msg_buffer[:]
	wayland.write_uint_into_message_args(msg, 2)
	wayland.set_message_length_based_on_args_length(&msg)

	wayland.write_message(msg)	
	for answer, ok := wayland.read_message(); ok; answer, ok = wayland.read_message(){
		fmt.printf("id: %d | ", wayland.get_message_object_id(answer))
		fmt.printf("opcode: %d | ", wayland.get_message_opcode(answer))
		length := wayland.get_message_length(answer)
		fmt.printf("length: %d | ", length)
		argument_index := 0
		global_object_id: u32
		interface_name: string
		version: u32

		global_object_id, argument_index = wayland.read_uint_from_message_args(answer)
		interface_name, argument_index = wayland.read_string_from_message_args(answer, argument_index)
		version, argument_index = wayland.read_uint_from_message_args(answer, argument_index)

		fmt.printf("global object id: %d | ", global_object_id)
		fmt.printf("interface name: %s | ", interface_name);
		fmt.printf("version: %d\n", version);
	}
	
}
