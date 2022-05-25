# Spack environments with LTO and PGO

Note: currently `%clang` specific.

Proof of concept that builds a Spack environment in two stages with profile-guided optimization.

Prerequisites:

1. Update `spack.yaml` with your specs + clang compiler
2. Run `git apply spack-compiler-wrapper.patch` to patch Spack's compiler wrapper

Building stage1 and stage2:

1. Run `make stage1 -j$(nproc)`
2. `rm -rf profiles/` to start with a clean slate (optional)
3. Run your software in `store/` to generate profile data
4. Run `make stage2 -j$(nproc)`\*
5. PGO+LTO optimized binaries are now in `./store`

\* Note: you may need to specify the path to `llvm-profdata`: `make ... LLVM_PROFDATA=/path/to/bin/llvm-profdata` if not in the PATH

Run `make clean` to remove generated files, and `make distclean` to also remove installed software.

