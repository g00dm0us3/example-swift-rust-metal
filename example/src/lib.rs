uniffi::include_scaffolding!("lib");

mod lsfr64;
mod util;

use std::cmp::max;
use std::sync::RwLock;

use crate::lsfr64::{random_seed_, LSFR64};
use crate::util::{point_to_linear_index, Handle};

use vecmath::{row_mat2x3_transform_pos2, Matrix2x3, Vector2};

struct DrawerState {
    iterations_per_step: u32,
    iteration_limit: u32,
    width: u16,
    height: u16,
    iteration_count: u32,
    linear_transforms: [Matrix2x3<f32>; 3],
    curr_point: Vector2<f32>,
    lsfr: LSFR64,
    curr_max_count: u32,
}

impl DrawerState {
    fn new(iterations_per_step: u32, iteration_limit: u32) -> Self {
        let sierpinsky_transforms = [
            [[0.5, 0.0, 0.0], [0.0, 0.5, 0.0]],
            [[0.5, 0.0, 0.5], [0.0, 0.5, 0.0]],
            [[0.5, 0.0, 0.0], [0.0, 0.5, 0.5]],
        ];

        Self {
            iterations_per_step,
            iteration_limit,
            width: 0,
            height: 0,
            iteration_count: 0,
            linear_transforms: sierpinsky_transforms,
            curr_point: [0.0, 0.0],
            lsfr: LSFR64::new(random_seed_()),
            curr_max_count: 0,
        }
    }
}

struct SierpinskyTriangleDrawer {
    state: RwLock<DrawerState>,
}

impl SierpinskyTriangleDrawer {
    fn new(iterations_per_step: u32, iteration_limit: u32) -> Self {
        Self {
            state: RwLock::new(DrawerState::new(iterations_per_step, iteration_limit)),
        }
    }

    fn set_number_of_iterations(&self, iteration_limit: u32) {
        self.state.write().unwrap().iteration_limit = iteration_limit
    }

    fn set_width(&self, width: u16) {
        self.state.write().unwrap().width = width
    }

    fn set_height(&self, height: u16) {
        self.state.write().unwrap().height = height
    }

    fn is_done(&self) -> bool {
        let state = self.state.read().unwrap();
        state.iteration_count >= state.iteration_limit
    }

    fn update_drawing(&self, drawing_data: Handle) -> u32 {
        let mut state = self.state.write().unwrap();

        let mut curr_number_of_iterations = state.iteration_count;
        let mut curr_point = state.curr_point;
        let mut max_count = state.curr_max_count;

        let data_pointer = drawing_data.0 as *mut u32;
        let iterations_per_step = state.iterations_per_step;
        let max_iterations = state.iteration_limit;
        let transforms = state.linear_transforms;

        let width = state.width;
        let height = state.height;

        let mut iter_ran = 0;

        if curr_number_of_iterations < 20 {
            for _ in 0..20 {
                let transform_index = state.lsfr.gen(0..=2) as usize;
                curr_point = row_mat2x3_transform_pos2(transforms[transform_index], curr_point);
            }

            curr_number_of_iterations += 20;
            iter_ran += 20;
        }

        while curr_number_of_iterations < max_iterations && iter_ran < iterations_per_step {
            let transform_index = state.lsfr.gen(0..=2) as usize;
            curr_point = row_mat2x3_transform_pos2(transforms[transform_index], curr_point);

            let index = point_to_linear_index(&curr_point, width, height);

            unsafe {
                let advanced = data_pointer.add(index);
                let curr_value = *(advanced);

                let new_value = curr_value.wrapping_add(1);
                advanced.write(new_value);

                max_count = max(new_value, max_count);
            }

            curr_number_of_iterations += 1;
            iter_ran += 1;
        }

        state.iteration_count = curr_number_of_iterations;
        state.curr_point = curr_point;
        state.curr_max_count = max_count;

        return max_count;
    }
}

#[cfg(test)]
mod tests {
    use std::alloc::{alloc, dealloc, Layout};
    use crate::Handle;

    use super::SierpinskyTriangleDrawer;

    #[test]
    fn test_creates_expected_state() {
        let triangle_drawer = SierpinskyTriangleDrawer::new(10, 100);

        triangle_drawer.set_height(200);
        triangle_drawer.set_width(300);

        let state = triangle_drawer.state.read().unwrap();

        assert_eq!(state.curr_point, [0.0, 0.0]);
        assert_eq!(state.height, 200);
        assert_eq!(state.width, 300);
        assert_eq!(state.iterations_per_step, 10);
        assert_eq!(state.iteration_limit, 100);
        assert_eq!(state.curr_max_count, 0);
        assert_eq!(state.iteration_count, 0);
    }

    #[test]
    fn test_runs_chaos_game() {
        let triangle_drawer = SierpinskyTriangleDrawer::new(500, 256 * 512 * 2);

        triangle_drawer.set_height(512);
        triangle_drawer.set_width(256);

        let layout = Layout::new::<[u32; 512 * 256]>();

        let handle: u64;

        unsafe  {
            handle = alloc(layout) as u64;
        }

        while !triangle_drawer.is_done() {
            triangle_drawer.update_drawing(Handle(handle));
        }

        let mut non_zero = 0;

        for idx in 0..(256 * 512) {
            unsafe {
                let val = *((handle as *mut u32).add(idx));

                non_zero += (val > 0) as u16;
            }
        }

        let area = non_zero as f32 / (512.0 * 256.0);

        assert!(area < 0.15);

        unsafe {
            dealloc(handle as *mut u8, layout);
        }
    }
}