package wayland

fixed :: u32
FRACTIONAL_BITS :: 8

f32ToFixed :: proc(f: f32) -> fixed {
    return fixed(f * f32(1 << FRACTIONAL_BITS))
}

fixedToF32 :: proc(f: fixed) -> f32 {
    return f32(f) / f32(1 << FRACTIONAL_BITS)
}