export SPACK ?= spack
PROFILE_DIR ?= $(CURDIR)/profiles
PROFILE_MERGED := $(PROFILE_DIR)/merged.prof
LLVM_PROFDATA ?= llvm-profdata

.SUFFIXES: 

.PHONY: all clean distclean

all: stage1

spack.lock: spack.yaml
	$(SPACK) -e . concretize -f --fresh
	
%.mk: spack.lock
	$(SPACK) -e . env depfile --make-target-prefix $*.deps -o $@

# Build with profile-generate
stage1: export SPACK_EXTRA_CC_FLAGS=-fprofile-generate=$(PROFILE_DIR) -Xclang -mllvm -Xclang -vp-counters-per-site=6 -ffunction-sections
stage1: export SPACK_EXTRA_CCLD_FLAGS=-fuse-ld=lld -flto=thin -Wl,-O3
stage1: stage1.mk
	$(MAKE) -f $< && touch $@

# Build with profile-use
stage2: export SPACK_EXTRA_CC_FLAGS=-fprofile-use=$(PROFILE_MERGED) -ffunction-sections -gz
stage2: export SPACK_EXTRA_CCLD_FLAGS=-fuse-ld=lld -flto=thin -Wl,-O3,--compress-debug-sections=zlib,--icf=safe
stage2: stage2.mk $(PROFILE_MERGED) store.stage1
	$(MAKE) -f $< && touch $@

# Backup the instrumented build
store.stage1: stage1
	mv store store.stage1

# Merge all collected profile data
$(PROFILE_MERGED): stage1
	$(LLVM_PROFDATA) merge -output=$@ $(PROFILE_DIR)/*.profraw

# Make sure make doesn't consider spack.lock intermediate
.pleasekeep: spack.lock

clean:
	rm -rf $(wildcard *.deps) $(wildcard *.mk) .spack-env spack.lock stage1 stage2

distclean: clean
	rm -rf store store.stage1 profiles

