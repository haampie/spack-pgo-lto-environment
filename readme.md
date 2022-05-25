# Spack environments with LTO and PGO

Note: currently `%clang` specific.

Proof of concept that builds a Spack environment in two stages (generate and use) to enable profile-guided optimization.

How to use this:

1. Update `spack.yaml` with your specs + clang compiler
2. Apply the provided patch to Spack's compiler wrapper
3. Run `make stage1 -j$(nproc) -Orecurse SPACK_COLOR=always`
4. [Maybe remove the `profiles/` dir to get rid of build time profile data]
5. Run your software in `store/` to generate profiles
6. Run `make stage2 -j$(nproc) -Orecurse SPACK_COLOR=always`


