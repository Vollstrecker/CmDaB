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
