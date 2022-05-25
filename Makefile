SPACK ?= spack
PROFILE_DIR ?= $(CURDIR)/profiles

# todo, make spack locate this based on %clang
LLVM_PROFDATA ?= llvm-profdata

.SUFFIXES: 

.PHONY: stage1 stage2

# Build with instrumentation
stage1: generate/env

# Use the instrumentation
stage2: use/env

spack.lock: spack.yaml
	$(SPACK) -e . concretize -f --fresh

# Make sure gnu make doesn't remove intermediate files
keep: spack.lock

# Inject the -fprofile-generate flag
generate/.install/%: export SPACK_EXTRA_CFLAGS=-fprofile-generate=$(PROFILE_DIR) -Xclang -mllvm -Xclang -vp-counters-per-site=6

# Inject the -fprofile-use flag
use/.install/%: export SPACK_EXTRA_CFLAGS=-fprofile-use=$(PROFILE_DIR)/merged.prof

# Generate Makefiles for stage1 (generate) and stage2 (use)
%.Makefile: spack.lock
	$(SPACK) -e . env depfile --make-target-prefix $* -o $@

# Merge all collected profile data
$(PROFILE_DIR)/merged.prof: generate/env
	$(LLVM_PROFDATA) merge -output=$@ $(PROFILE_DIR)/*.profraw && \
	mv store store.generate

include generate.Makefile
ifneq (,$(wildcard generate.Makefile))
include use.Makefile
endif

