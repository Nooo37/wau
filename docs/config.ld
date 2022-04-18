project = "wau"
title = "wau - wayland on lua"
description = "Client-side libwayland bindings for lua"
format = 'markdown'

examples = {
    "examples",
    exclude = {
        "examples/protocol",
        "examples/helpers",
    }
}

topics = {
    "README.md",
    "docs"
}

kind_names = {
    topic = "Manual",
    module = "Protocols",
}

new_type("event", "Events", false, "Parameters")
new_type("enum", "Enumerations")

