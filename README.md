[![Build](https://github.com/floooh/dcimgui/actions/workflows/build.yml/badge.svg)](https://github.com/floooh/dcimgui/actions/workflows/build.yml)

An version-tagged all-in-one [Dear ImGui](https://github.com/ocornut/imgui)
source distribution repository for C and C++ coding with:

- regular and docking versions of Dear ImGui (for C++)
- C bindings for the regular and docking version (generated with the
  new [dear_bindings](https://github.com/dearimgui/dear_bindings) approach.

The C bindings use the `ig` prefix and cimgui.h/cimgui.cpp filenames to be as
compatible as possible with the 'legacy' cimgui bindings (but please be aware
that there are still significant differences to the legacy cimgui bindings).

The CMakeLists.txt file can be used both from regular cmake projects and
from fips projects (https://floooh.github.io/fips/) and defines to
static link libraries (`imgui` and `imgui-docking`).

NOTE: do not use the `imgui` and `imgui-docking` libraries together in the
same project since this will confuse header search paths.

To use the C API:

- for the regular version: link with `imgui` and include `cimgui.h`
- for the docking version: link with `imgui-docking` and include `cimgui.h`
- NOTE: the cimgui.h header contains duplicate symbol definitions and
  must be compiled in C11 mode.

To use the C++ API:

- for regular version: link with `imgui` and include `imgui.h`
- for the docking version: link with `imgui-docking` and include `imgui.h`
