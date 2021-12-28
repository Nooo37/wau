local ffi = require("cffi")

local wc = ffi.load("wayland-client")

local d1=
[[
typedef int32_t wl_fixed_t;

struct wl_interface {
	/** Interface name */
	const char *name;
	/** Interface version */
	int version;
	/** Number of methods (requests) */
	int method_count;
	/** Method (request) signatures */
	const struct wl_message *methods;
	/** Number of events */
	int event_count;
	/** Event signatures */
	const struct wl_message *events;
};

struct wl_message {
	/** Message name */
	const char *name;
	/** Message signature */
	const char *signature;
	/** Object argument interfaces */
	const struct wl_interface **types;
};

union wl_argument {
	int32_t i;           /**< `int`    */
	uint32_t u;          /**< `uint`   */
	wl_fixed_t f;        /**< `fixed`  */
	const char *s;       /**< `string` */
	struct wl_object *o; /**< `object` */
	uint32_t n;          /**< `new_id` */
	struct wl_array *a;  /**< `array`  */
	int32_t h;           /**< `fd`     */
};

typedef int (*wl_dispatcher_func_t)(const void *, void *, uint32_t,
				    const struct wl_message *,
				    union wl_argument *);
]]
..
[[

struct wl_proxy;

struct wl_display;

struct wl_event_queue;

void
wl_event_queue_destroy(struct wl_event_queue *queue);

void
wl_proxy_marshal(struct wl_proxy *p, uint32_t opcode, ...);

void
wl_proxy_marshal_array(struct wl_proxy *p, uint32_t opcode,
		       union wl_argument *args);

struct wl_proxy *
wl_proxy_create(struct wl_proxy *factory,
		const struct wl_interface *interface);

void *
wl_proxy_create_wrapper(void *proxy);

void
wl_proxy_wrapper_destroy(void *proxy_wrapper);

struct wl_proxy *
wl_proxy_marshal_constructor(struct wl_proxy *proxy,
			     uint32_t opcode,
			     const struct wl_interface *interface,
			     ...);

struct wl_proxy *
wl_proxy_marshal_constructor_versioned(struct wl_proxy *proxy,
				       uint32_t opcode,
				       const struct wl_interface *interface,
				       uint32_t version,
				       ...);

struct wl_proxy *
wl_proxy_marshal_array_constructor(struct wl_proxy *proxy,
				   uint32_t opcode, union wl_argument *args,
				   const struct wl_interface *interface);

struct wl_proxy *
wl_proxy_marshal_array_constructor_versioned(struct wl_proxy *proxy,
					     uint32_t opcode,
					     union wl_argument *args,
					     const struct wl_interface *interface,
					     uint32_t version);

void
wl_proxy_destroy(struct wl_proxy *proxy);

int
wl_proxy_add_listener(struct wl_proxy *proxy,
		      void (**implementation)(void), void *data);

const void *
wl_proxy_get_listener(struct wl_proxy *proxy);

int
wl_proxy_add_dispatcher(struct wl_proxy *proxy,
			wl_dispatcher_func_t dispatcher_func,
			const void * dispatcher_data, void *data);

void
wl_proxy_set_user_data(struct wl_proxy *proxy, void *user_data);

void *
wl_proxy_get_user_data(struct wl_proxy *proxy);

uint32_t
wl_proxy_get_version(struct wl_proxy *proxy);

uint32_t
wl_proxy_get_id(struct wl_proxy *proxy);

void
wl_proxy_set_tag(struct wl_proxy *proxy,
		 const char * const *tag);

const char * const *
wl_proxy_get_tag(struct wl_proxy *proxy);

const char *
wl_proxy_get_class(struct wl_proxy *proxy);

void
wl_proxy_set_queue(struct wl_proxy *proxy, struct wl_event_queue *queue);

struct wl_display *
wl_display_connect(const char *name);

struct wl_display *
wl_display_connect_to_fd(int fd);

void
wl_display_disconnect(struct wl_display *display);

int
wl_display_get_fd(struct wl_display *display);

int
wl_display_dispatch(struct wl_display *display);

int
wl_display_dispatch_queue(struct wl_display *display,
			  struct wl_event_queue *queue);

int
wl_display_dispatch_queue_pending(struct wl_display *display,
				  struct wl_event_queue *queue);

int
wl_display_dispatch_pending(struct wl_display *display);

int
wl_display_get_error(struct wl_display *display);

uint32_t
wl_display_get_protocol_error(struct wl_display *display,
			      const struct wl_interface **interface,
			      uint32_t *id);

int
wl_display_flush(struct wl_display *display);

int
wl_display_roundtrip_queue(struct wl_display *display,
			   struct wl_event_queue *queue);

int
wl_display_roundtrip(struct wl_display *display);

struct wl_event_queue *
wl_display_create_queue(struct wl_display *display);

int
wl_display_prepare_read_queue(struct wl_display *display,
			      struct wl_event_queue *queue);

int
wl_display_prepare_read(struct wl_display *display);

void
wl_display_cancel_read(struct wl_display *display);

int
wl_display_read_events(struct wl_display *display);
]]

ffi.cdef(d1)

return wc

--void
--wl_log_set_handler_client(wl_log_func_t handler);

