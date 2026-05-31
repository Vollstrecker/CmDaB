# CmDaB
CmDaB is a lightweight helper for resolving dependencies at CMake configure
time using find_package.

It removes the need to manually integrate FetchContent while preserving the
native CMake workflow and semantics.

## Overview
CmDaB augments CMake’s dependency resolution process:

- find_package remains the only API surface
- system packages are preferred when available
- missing packages are fetched and built automatically
- no runtime logic – everything happens during configure
- CmDaB does not attempt to abstract or normalize upstream libraries beyond
basic target normalization.

## Design

CmDaB extends the standard `find_package()` workflow by transparently resolving
dependencies from the system or building them from source when necessary.

Unlike traditional package managers, CmDaB does not introduce a separate
dependency graph or workflow. Dependencies become part of the normal CMake
target graph.

This has a key consequence:

- Dependencies and project code can be built in parallel
- No "build dependencies first" phase is required
- Incremental builds naturally include dependencies

Example:

```cmake
find_package(Foo)
```

With CmDaB, this will:

1. Use a system installation if available (and wanted)
2. Otherwise build the package from source using FetchContent

No changes to the caller are required.

## Comparison
| Tool    | Integration Model        | Workflow Required | Build Model                | Parallelization | Uses System Libraries | Builds from Source | Transparent Fallback | External Build Tools |
|---------|--------------------------|-------------------|----------------------------|-----------------|-----------------------|--------------------|----------------------|----------------------|
| CmDaB   | `find_package` extension | no                | integrated build graph     | high            | yes                   | yes                | yes                  | minimal              |
| CMake   | explicit `find_package`  | no                | project only               | limited         | yes                   | no                 | no                   | minimal              |
| Meson   | built-in dependency API  | yes               | integrated build graph     | high            | yes                   | yes (fallback)     | no (explicit)        | sometimes            |
| vcpkg   | toolchain-based          | yes               | dependencies first         | limited         | optional              | yes                | n/a                  | often                |
| Conan   | external manager         | yes               | dependencies first         | limited         | optional              | yes                | n/a                  | often                |

### Key Difference
Many package managers introduce additional build-time dependencies
for building libraries (e.g. Python, Perl, custom scripts).

CmDaB operates purely within the CMake ecosystem:

- Dependencies are expected to be CMake-based
- Build requirements become part of the same CMake build graph
- No separate build toolchain is required

This avoids the need to install additional tools just to build
dependencies.

CmDaB integrates dependency resolution directly into the existing
CMake `find_package()` workflow.

Unlike Meson, which requires explicit fallback definitions, CmDaB
applies this behavior transparently without any changes to the caller.

Unlike traditional package managers (vcpkg, Conan), dependencies are
not built in a separate phase, but are part of the normal CMake build
graph. This allows full parallelization

## Usage
CmDaB can be integrated in two ways:

### 1. Copy into your source tree
Copy CmDaB.cmake into your project, for example:

```cmake
include(cmake/CmDaB.cmake)
```

### 2. Add as a subdirectory
Alternatively, include the repository directly:

```cmake
add_subdirectory(externals/CmDaB)
include(externals/CmDaB/CmDaB.cmake)
```

After inclusion, dependencies are used normally:

```cmake
find_package(GTest COMPONENTS gmock)
find_package(ZLIB)
```

## Initialization
CmDaB only affects find_package calls that occur after it is included.

Calls made before including CmDaB are not modified and use default CMake
behavior.

## How it works
CmDaB loads package definitions from its packages/ directory

Each package is declared via:

```cmake
CmDaB_Declare(...)
```

For each package, CmDaB generates:

- a Config.cmake wrapper
- a Find\<Package\>.cmake wrapper

These are added to the CMake search paths:

- CMAKE_PREFIX_PATH
- CMAKE_MODULE_PATH

When find_package is called:
- CmDaB’s wrapper intercepts the call
- Resolution proceeds via CmDaB_Resolve

## Resolution Strategy
Resolution follows a strict order:

1. Try system / toolchain packages (find_package)
2. Validate required targets
3. If insufficient, download and build via FetchContent
4. Normalize targets via declared aliases
5. System packages may provide more targets than requested, but must provide at
least the required ones.

## Package Definitions
Packages are declared in individual .cmake files:

```cmake
CmDaB_declare(GTest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG main

  OPTIONS
    INSTALL_GTEST OFF

  TEST_OPTIONS
    gtest_build_tests
    gmock_build_tests

  ALIASES
    GTest::gtest      gtest
    GTest::gmock      gmock
)
```

## Custom Packages / Overrides
Additional package definitions can be provided via:

```cmake
set(CmDaB_PACKAGE_DIR "<path>")
```

- packages in this directory are processed before built-in ones
- the first definition wins
- allows clean overrides of existing packages

## Global Options
#### CmDaB_Always_Download
- bypasses system packages
- always uses FetchContent

#### CmDaB_Build_Tests
- controls all TEST_OPTIONS defaults.Applies only if options are not explicitly
set

#### CmDaB_PACKAGE_DIR
- Path to an additional directory containing local packages or overrides

## Package-specific Handlers
Packages can define custom resolution logic:

```cmake
function(GTest_Handle_Find)
  ...
endfunction()
```

Use this for:
- component-aware builds
- special build flags
- non-standard upstream behavior

## Design Principles
CmDaB intentionally keeps a narrow scope:
- no abstraction of dependency semantics
- no attempt to fix all upstream inconsistencies
- no version or feature management layer

It provides:
- deterministic dependency availability
- consistent integration with find_package
- minimal developer overhead

## Limitations
- Only targets actually provided by upstream are exposed
- Static/shared variants cannot be synthesized
- Some packages require custom handlers

## License
See the LICENSE file for details.

## Future Direction
CmDaB can optionally cache built dependencies locally.

After an initial build from source, dependencies can be reused in subsequent builds,
combining the benefits of source-based builds with binary reuse.

This enables:

- Reproducible builds without a central registry
- Fast rebuilds after initial setup
- No additional package manager workflow
