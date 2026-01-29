# PB Manifest Resource Generator (PerMonitorV2)

A small PureBasic tool that generates a Windows **RT_MANIFEST** resource as:
- `Resource.rc`
- `Data_1.bin`

The manifest enables:
- **Per-Monitor DPI Aware v2 (PerMonitorV2)** with fallback to PerMonitor
- optional **Modern Theme support** (Common-Controls v6)
- optional **requestedExecutionLevel** (asInvoker / requireAdministrator)

The output is intended to be embedded into your PureBasic EXE by adding the generated
`Resource.rc` to **Compiler Options → Resources** in the PureBasic IDE.

## Why this exists

PureBasic’s built-in DPI option is limited to the IDE’s provided settings. If you need
**PerMonitorV2** via manifest, this tool generates a proper RT_MANIFEST resource that the
PureBasic IDE can compile and link into the executable as part of the normal build.

## Output

The tool writes files into a target folder (default: `resources/windows/manifest/`):
- `Resource.rc`  
  Contains `1 24 "Data_1.bin"` → Resource ID `1`, resource type `24` (RT_MANIFEST)
- `Data_1.bin`  
  The manifest XML payload (ASCII file containing UTF-8 XML header)

## Repository Layout (recommended)

´´´
├─ src/
│ └─ GenerateManifestResource.pb
├─ resources/
│ └─ windows/
│ └─ manifest/
│ ├─ Resource.rc
│ └─ Data_1.bin
├─ LICENSE
└─ README.md
´´´

> Notes:
- The generator can still run before builds to update output when settings change.

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
3. Add: `resources\windows\manifest\Resource.rc`
4. Compile your application
   
### Important: avoid duplicate manifests
If you embed your own RT_MANIFEST via `Resource.rc`, disable PureBasic’s own manifest/DPI options
that might emit another manifest resource (depending on your PB setup). Use a single manifest
source to avoid conflicts.

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
  
