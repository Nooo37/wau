local ffi = require("cffi")

local M = ffi.load("wayland-cursor")

local s = [[
struct wl_cursor_theme;
struct wl_cursor_image {
	uint32_t width;		/* actual width */
	uint32_t height;	/* actual height */
	uint32_t hotspot_x;	/* hot spot x (must be inside image) */
	uint32_t hotspot_y;	/* hot spot y (must be inside image) */
	uint32_t delay;		/* animation delay to next frame (ms) */
};
struct wl_cursor {
	unsigned int image_count;
	struct wl_cursor_image **images;
	char *name;
};
struct wl_shm;
struct wl_cursor_theme *
wl_cursor_theme_load(const char *name, int size, struct wl_shm *shm);
void
wl_cursor_theme_destroy(struct wl_cursor_theme *theme);
struct wl_cursor *
wl_cursor_theme_get_cursor(struct wl_cursor_theme *theme,
			   const char *name);
struct wl_buffer *
wl_cursor_image_get_buffer(struct wl_cursor_image *image);
int
wl_cursor_frame(struct wl_cursor *cursor, uint32_t time);
int
wl_cursor_frame_and_duration(struct wl_cursor *cursor, uint32_t time,
			     uint32_t *duration);

]]

ffi.cdef(s)

return M
