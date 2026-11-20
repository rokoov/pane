# dmgbuild settings for Pane's disk image; build.sh passes the app, the background and the volume icon with -D
import os

application = defines["app"]
name = os.path.basename(application)

format = "UDZO"
files = [application]
symlinks = {"Applications": "/Applications"}
icon = defines["icon"]
background = defines["background"]

# Points from the window's top left; the background draws its arrow between the two icons
window_rect = ((200, 140), (640, 400))
icon_locations = {name: (160, 175), "Applications": (480, 175)}
icon_size = 128
text_size = 13

default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
show_icon_preview = False
include_icon_view_settings = True
include_list_view_settings = False
