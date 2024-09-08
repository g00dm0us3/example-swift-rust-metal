use std::{cmp::min, ops::RangeInclusive};

use vecmath::Vector2;

use crate::UniffiCustomTypeConverter;

fn to_range(value: f32, old_range: RangeInclusive<f32>, new_range: RangeInclusive<f32>) -> f32{
    let old_min = *old_range.start();
    let old_max = *old_range.end();

    let new_min = *new_range.start();
    let new_max = *new_range.end();

    let value = value.clamp(old_min, old_max);
    let old_range_len = old_max - old_min;
    let new_range_len = new_max - new_min;

    ((value - old_min)*new_range_len/old_range_len + new_min).clamp(new_min, new_max)
}

// assuming triangle at [0, 1] x [0, 1]
pub(crate) fn point_to_linear_index(
    point: &Vector2<f32>,
    width: u16,
    height: u16
) -> usize {
    let x = to_range(point[0], 0.0..=1.0, 0.0..=(width  - 1) as f32).floor() as u32;
    let y = to_range(point[1], 0.0..=1.0, 0.0..=(height - 1) as f32).floor() as u32;

    let width = width as u32;
    let height = height as u32;

    min(width * height - 1, y * width + x) as usize
}

pub(crate) struct Handle(pub u64);

impl UniffiCustomTypeConverter for Handle {
    // The `Builtin` type will be used to marshall values across the FFI
    type Builtin = u64;

    // Convert Builtin to our custom type
    fn into_custom(val: Self::Builtin) -> uniffi::Result<Self> {
        Ok(Handle(val))
    }

    // Convert our custom type to Builtin
    fn from_custom(obj: Self) -> Self::Builtin {
        obj.0
    }
}

#[cfg(test)]
mod tests {
    use super::{to_range, point_to_linear_index};

    #[test]
    fn test_converts_to_new_range() {
        let old_range = 0.0..=1.0;
        let new_range = 2.0..=10.0;

        let value10 = 0.1;
        let value50 = 0.5;
        let value80 = 0.8;

        let converted10 = to_range(value10, old_range.clone(), new_range.clone());
        let converted50 = to_range(value50, old_range.clone(), new_range.clone());
        let converted80 = to_range(value80, old_range.clone(), new_range.clone());

        assert_eq!(converted10, 2.8);
        assert_eq!(converted50, 6.0);
        assert_eq!(converted80, 8.4);
    }

    #[test]
    fn test_out_of_bounds_when_convertingto_new_range() {
        let old_range = 0.0..=1.0;
        let new_range = 2.0..=10.0;

        let value_sup = 1.1;
        let value_inf = -0.1;

        let converted_sup = to_range(value_sup, old_range.clone(), new_range.clone());
        let converted_inf = to_range(value_inf, old_range.clone(), new_range.clone());

        assert_eq!(converted_sup, 10.0);
        assert_eq!(converted_inf, 2.0);
    }

    #[test]
    fn test_converts_point_to_lin_index() {
        let point = [0.5, 0.5];

        let width = 100;
        let height = 200;

        let index = point_to_linear_index(&point, width, height);

        assert_eq!(index, 9949);
    }

    #[test]
    fn test_out_of_bounds_when_point_to_lin_index() {
        let point = [1.1, -1.0];

        let width = 100;
        let height = 200;

        let index = point_to_linear_index(&point, width, height);

        assert_eq!(index, 99);
    }
}