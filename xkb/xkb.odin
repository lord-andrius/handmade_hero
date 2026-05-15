package xkb

import "vendor:kb_text_shape"
import "core:fmt"
import "core:strings"

Token :: enum {
    BACKSLAH_COMMENT,
    HASH_COMMENT,
    STRING_LITERAL,
    NUMERICAL_LITERAL,
    KEYSYMS,
    KEYWORD,
}

Keywords :: enum {
    ACTION,
    ALIAS,
    ALPHANUMERIC_KEYS,
    ALTERNATE_GROUP,
    ALTERNATE,
    AUGMENT,
    DEFAULT,
    FUNCTION_KEYS,
    GROUP,
    HIDDEN,
    INCLUDE,
    INDICATOR,
    INTERPRET,
    KEY,
    KEYPAD_KEYS,
    KEYS,
    LOGO,
    MOD_MAP,
    MODIFIER_KEYS,
    MODMAP,
    MODIFIER_MAP,
    OUTLINE,
    OVERLAY,
    OVERRIDE,
    PARTIAL,
    REPLACE,
    ROW,
    SECTION,
    SHAPE,
    SOLID,
    TEXT,
    TYPE,
    VIRTUAL_MODIFIERS,
    VIRTUAL,
    XKB_COMPAT_MAP,
    XKB_COMPAT,
    XKB_COMPATIBILITY_MAP,
    XKB_COMPATIBILITY,
    XKB_GEOMETRY,
    XKB_KEYCODES,
    XKB_KEYMAP,
    XKB_LAYOUT,
    XKB_SEMANTICS,
    XKB_SYMBOLS,
    XKB_TYPES
}

Keywords_Str :: [Keywords]string {
    .ACTION = "action",
    .ALIAS = "alias",
    .ALPHANUMERIC_KEYS = "alphanumeric_keys",
    .ALTERNATE_GROUP = "alternate_group",
    .ALTERNATE = "alternate",
    .AUGMENT = "augment",
    .DEFAULT = "default",
    .FUNCTION_KEYS = "function_keys",
    .GROUP = "group",
    .HIDDEN = "hidden",
    .INCLUDE = "include",
    .INDICATOR = "indicator",
    .INTERPRET = "interpret",
    .KEY = "key",
    .KEYPAD_KEYS = "keypad_keys",
    .KEYS = "keys",
    .LOGO = "logo",
    .MOD_MAP = "mod_map",
    .MODIFIER_KEYS = "modifier_keys",
    .MODMAP = "modmap",
    .MODIFIER_MAP = "modifier_map",
    .OUTLINE = "outline",
    .OVERLAY = "overlay",
    .OVERRIDE = "override",
    .PARTIAL = "partial",
    .REPLACE = "replace",
    .ROW = "row",
    .SECTION = "section",
    .SHAPE = "shape",
    .SOLID = "solid",
    .TEXT = "text",
    .TYPE = "type",
    .VIRTUAL_MODIFIERS = "virtual_modifiers",
    .VIRTUAL = "virtual",
    .XKB_COMPAT_MAP = "xkb_compat_map",
    .XKB_COMPAT = "xkb_compat",
    .XKB_COMPATIBILITY_MAP = "xkb_compatibility_map",
    .XKB_COMPATIBILITY = "xkb_compatibility",
    .XKB_GEOMETRY = "xkb_geometry",
    .XKB_KEYCODES = "xkb_keycodes",
    .XKB_KEYMAP = "xkb_keymap",
    .XKB_LAYOUT = "xkb_layout",
    .XKB_SEMANTICS = "xkb_semantics",
    .XKB_SYMBOLS = "xkb_symbols",
    .XKB_TYPES = "xkb_type"
}


Parse_Context :: struct {
    state: enum {
        ACCUMULATING,
        ACCUMULATING_UTIL_END_OF_SEQUENCE,
        DONE_ACCUMULATING,
        IGNORING_UTIL_END_OF_SEQUENCE,
        ESPECTING_SEQUENCE,
        BLOCK_DISCOVERING, // Onde vamos descobrir os limites dos blocos
        BLOCK_DISCOVERED,
    },
    // NOTA: Por favor diminuir esse acumulador depois.
    accumulated_sequence: [dynamic; 128]u8,
    expected_sequence_to_end_accumulating_or_ignoring: []u8,
    expected_sequence_to_end_accumulating_or_ignoring_buffer: [16]u8,
    where_it_stoped_lookin_into_the_file: int,
    previous_keyword: Keywords,
    block_text: []u8,
    line_number: int, // começa em zero
    done: bool,
    error: bool,
    error_message: string
}



load_keymap :: proc(xkb_map_complete: []u8) {
    ctx: Parse_Context
    for ctx.done == false {
        #partial switch ctx.state {
            case .ACCUMULATING:
                loop: for char, index in xkb_map_complete[ctx.where_it_stoped_lookin_into_the_file:] {
                    ctx.where_it_stoped_lookin_into_the_file += 1
                    if ctx.where_it_stoped_lookin_into_the_file == len(xkb_map_complete) - 1 {
                        // tudo foi bem e passamos por todo o arquivo
                        ctx.done = true
                        ctx.error = false
                        break loop
                    }
                    switch char {
                        case '/':
                            if xkb_map_complete[index + 1] == '/' { // Estamos em um comentário '//'
                                ctx.state = .DONE_ACCUMULATING
                                break loop
                            } else if xkb_map_complete[index + 1] == '*' {
                                // NOTA: Se comentários do tipo /**/ forem como espaço em branco
                                // então deveriamos fazer: ctx.state = .DONE_ACCUMULATING
                                ctx.state = .IGNORING_UTIL_END_OF_SEQUENCE
                                ctx.expected_sequence_to_end_accumulating_or_ignoring_buffer[0] = '*'
                                ctx.expected_sequence_to_end_accumulating_or_ignoring_buffer[1] = '/'
                                ctx.expected_sequence_to_end_accumulating_or_ignoring = ctx.expected_sequence_to_end_accumulating_or_ignoring_buffer[:2]
                            }
                            ctx.done = true
                            ctx.error = true
                            ctx.error_message = "'/' is invalid in this context."
                            break loop
                        case '*':
                            ctx.done = true
                            ctx.error = true
                            ctx.error_message = "'*' is invalid in this context."
                            break loop 
                        case '\n':
                            ctx.line_number += 1
                            fallthrough
                        case ' ':
                            ctx.state = .DONE_ACCUMULATING
                            ctx.where_it_stoped_lookin_into_the_file += 1
                            break loop
                        case:
                            if append(&ctx.accumulated_sequence, char) == 0 {
                                ctx.done = true
                                ctx.error = true
                                ctx.error_message = "Identificator too big"
                            }
                            
                    }
                }
            case .DONE_ACCUMULATING:
                accumulated_string := string(ctx.accumulated_sequence[:])
                switch accumulated_string {
                    // fallthroughs são temporátios
                    case Keywords_Str[.ACTION]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.ALIAS]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.ALPHANUMERIC_KEYS]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.ALTERNATE_GROUP]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.ALTERNATE]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.AUGMENT]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.DEFAULT]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.FUNCTION_KEYS]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.GROUP]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.HIDDEN]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.INCLUDE]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.INDICATOR]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.INTERPRET]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.KEY]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.KEYPAD_KEYS]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.KEYS]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.LOGO]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.MOD_MAP]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.MODIFIER_KEYS]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.MODMAP]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.MODIFIER_MAP]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.OUTLINE]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.OVERLAY]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.OVERRIDE]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.PARTIAL]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.REPLACE]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.ROW]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.SECTION]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.SHAPE]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.SOLID]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.TEXT]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.TYPE]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.VIRTUAL_MODIFIERS]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.VIRTUAL]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.XKB_COMPAT_MAP]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.XKB_COMPAT]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.XKB_COMPATIBILITY_MAP]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.XKB_COMPATIBILITY]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.XKB_GEOMETRY]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.XKB_KEYCODES]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.XKB_KEYMAP]:
                        ctx.state = .BLOCK_DISCOVERING
                        ctx.previous_keyword = .XKB_KEYMAP
                        continue
                    case Keywords_Str[.XKB_LAYOUT]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.XKB_SEMANTICS]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.XKB_SYMBOLS]: fmt.println("keyword:", accumulated_string)
                    case Keywords_Str[.XKB_TYPES]:
                        fmt.println("keyword:", accumulated_string)
                    case:
                        fmt.printfln("WARNING:'%s' Not a keyword", accumulated_string)
                }

                //viemos de um comentário
                if xkb_map_complete[ctx.where_it_stoped_lookin_into_the_file] == '/' {
                    ctx.state = .IGNORING_UTIL_END_OF_SEQUENCE
                    ctx.expected_sequence_to_end_accumulating_or_ignoring_buffer[0] = '\n'
                    ctx.expected_sequence_to_end_accumulating_or_ignoring = ctx.expected_sequence_to_end_accumulating_or_ignoring_buffer[:1]
                    continue
                }

                ctx.state = .ACCUMULATING
                clear_fixed_capacity_dynamic_array(&ctx.accumulated_sequence)
            case .IGNORING_UTIL_END_OF_SEQUENCE:
                ignore_sequence_string := string(ctx.expected_sequence_to_end_accumulating_or_ignoring)
                xkb_map_complete_string := string(xkb_map_complete[ctx.where_it_stoped_lookin_into_the_file:])
                index_ignore_sequence := strings.index(xkb_map_complete_string, ignore_sequence_string)                
                if index_ignore_sequence == -1 {
                    ctx.done = true
                    ctx.error = true
                    ctx.error_message = "ignored sequence not found in file"
                    return
                }
                ctx.where_it_stoped_lookin_into_the_file = index_ignore_sequence + len(ignore_sequence_string)
                ctx.state = .ACCUMULATING

            case .BLOCK_DISCOVERING:
                index_begin_block, index_end_block: int
                found_index_begin := false
                should_consider_closing_block := true
                found_block := false
                for char, index in xkb_map_complete[ctx.where_it_stoped_lookin_into_the_file:] {
                    if char == '{' && found_index_begin == false {
                        index_begin_block = index
                    } else if char == '{' && found_index_begin == true {
                        should_consider_closing_block = false
                    } else if char == '}' && should_consider_closing_block == false {
                        should_consider_closing_block = true
                    } else if char == '}' && should_consider_closing_block == true {
                        index_end_block = index
                        found_block = true
                        break
                    }
                }

                if !found_block {
                    ctx.done = true
                    ctx.error = true
                    ctx.error_message = "Not matching } for block."
                    continue
                }

                ctx.state = .BLOCK_DISCOVERED
                ctx.block_text = xkb_map_complete[index_begin_block:index_end_block + 1]
                ctx.where_it_stoped_lookin_into_the_file = index_end_block

            case .BLOCK_DISCOVERED:

        }
    }

    if ctx.error == true {
        fmt.println("Error: ", ctx.error_message)
    }
}
