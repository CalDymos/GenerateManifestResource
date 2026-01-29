# PB Manifest Resource Generator (PerMonitorV2)

A small PureBasic tool that generates a Windows **RT_MANIFEST** resource as:

- `resource.rc`
- `manifest.bin`

The manifest enables:

- **Per-Monitor DPI Aware v2 (PerMonitorV2)** with fallback to PerMonitor
- optional **Modern Theme support** (Common-Controls v6)
- optional **requestedExecutionLevel** (asInvoker / requireAdministrator)

The output is intended to be embedded into your PureBasic EXE by adding the generated
`resource.rc` to **Compiler Options → Resources** in the PureBasic IDE.

## Why this exists

PureBasic’s built-in DPI option is limited to the IDE’s provided settings. If you need
**PerMonitorV2** via manifest, this tool generates a proper RT_MANIFEST resource that the
PureBasic IDE can compile and link into the executable as part of the normal build.

## Output

The tool writes files into a target folder (default: `resources/windows/manifest/`):

- `resource.rc`  
  Contains `1 24 "manifest.bin"` → Resource ID `1`, resource type `24` (RT_MANIFEST)
- `manifest.bin`  
  The manifest XML payload (ASCII file containing UTF-8 XML header)

> Notes:
> The generator can still run before builds to update output when settings change.

## Requirements

- Windows
- PureBasic IDE (for easiest automation)
- PureBasic compiler (ships with the IDE)

## Usage

### PureBasic IDE

You can run the generator automatically before building your EXE:

1. Compile the generator once to an EXE (example output):
   `tools\GenerateManifestResource.exe` (location is up to you)

2. In the PureBasic IDE:
   - **Tools → Configure Tools…**
   - Add a new tool:
     - **Command-line:** path to `GenerateManifestResource.exe`
     - **Arguments:** leave empty (default output directory) or pass a custom folder
     - **Trigger:** **Before create Executable**
     - Enable **Wait until tool quits**

Now every build will regenerate the manifest resource before the final executable is created.

### Embed into your application

In your application project:

1. Open **Compiler Options**
2. Go to **Resources**
3. Add: `resources\windows\manifest\resource.rc`
4. Compile your application
  
### Important: avoid duplicate manifests

When embedding a custom RT_MANIFEST via `resource.rc` (type 24, id 1), PureBasic must **not** add its own manifest.
Otherwise the linker fails with a duplicate MANIFEST resource error.

Disable in **Compiler Options**:

- ✅ Enable XP skin support  (must be OFF)
- ✅ Enable DPI Aware Executable (must be OFF)

the generated manifest `manifest.bin` already contains:

- Common-Controls v6 (modern theme support)
- PerMonitorV2 DPI awareness (+ fallback)

> Note:  
> As fallback `GenerateManifestResource` includes a sanitizer step that automatically updates the .pbp project file before build:  
>
> - sets xpskin="0"  
> - sets dpiaware="0"  
> A .bak backup of the original .pbp is created before writing changes.  

## Configuration

Edit constants near the top of `GenerateManifestResource.pb`:

- `#ENABLE_MODERN_THEME_SUPPORT`
- `#ENABLE_PER_MONITOR_V2`
- `#REQUEST_EXECUTION_LEVEL$` (`"asInvoker"`, `"requireAdministrator"`, or empty to omit)
- `#OUT_REL_DIR$` (repo-relative output directory)

### DPI configuration emitted (PerMonitorV2)

The generated manifest includes:

- `<dpiAwareness>PerMonitorV2, PerMonitor</dpiAwareness>`
- `<dpiAware>true/pm</dpiAware>` as fallback for older systems
  