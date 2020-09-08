ifndef KERNEL_MK
KERNEL_MK := 1
ifndef PRAWNOS_ROOT
PRAWNOS_ROOT := $(shell git rev-parse --show-toplevel)
endif
include $(PRAWNOS_ROOT)/scripts/BuildScripts/BuildCommon.mk
include $(PRAWNOS_ROOT)/initramfs/makefile

### TARGETED VARS ###
KERNEL_PATCHED := $(PRAWNOS_KERNEL_BUILD)/.kernel_patched
KERNEL_EXTRACTED := $(PRAWNOS_KERNEL_BUILD)/.kernel_extracted

KERNEL_SHARED_RESOURCES := $(PRAWNOS_KERNEL)/resources/shared
KERNEL_RESOURCES := $(PRAWNOS_KERNEL)/resources/$(TARGET)
KERNEL_PATCHES := $(PRAWNOS_KERNEL)/patches/$(TARGET)

KERNEL_BUILD_LOG := $(PRAWNOS_BUILD_LOGS)/kernel-log-$(TARGET).txt

### UNIVERSAL VARS ###
KERNEL_TAR := $(KERNEL_SOURCES)/linux-$(KVER).tar.gz

### PHONY RULES
.PHONY: kernel
kernel: $(PRAWNOS_KERNEL_BUILT)

.PHONY: patch_kernel
patch_kernel: $(KERNEL_PATCHED)

.PHONY: extract_kernel
extract_kernel: $(KERNEL_EXTRACTED)

.PHONY: kernel_image_package
kernel_image_package: $(PRAWNOS_KERNEL_BUILT)
	$(MAKE) -C $(PRAWNOS_KERNEL_PACKAGE_IMAGE)
	$(MAKE) -C $(PRAWNOS_KERNEL_PACKAGE_IMAGE) install INSTALL_TARGET=$(PRAWNOS_BUILD)

.PHONY: kernel_config
kernel_config: $(KERNEL_PATCHED)
	mkdir -p $(PRAWNOS_BUILD_DIRS)
	$(PRAWNOS_KERNEL_SCRIPTS_MENUCONFIG) $(KERNEL_RESOURCES) $(PRAWNOS_KERNEL_BUILD) $(TARGET)

### CLEAN RULES

.PHONY: clean_kernel
clean_kernel:
	rm -rf $(PRAWNOS_KERNEL_BUILD)


.PHONY: update_kernel_sig
update_kernel_sig:
	# dummy

### REAL RULES

$(KERNEL_TAR):
	wget https://www.kernel.org/pub/linux/kernel/v5.x/linux-$(KVER).tar.gz -O $(KERNEL_TAR)

$(KERNEL_EXTRACTED): $(KERNEL_TAR)
	mkdir -p $(PRAWNOS_BUILD_DIRS)
	tar -xvzf $(KERNEL_TAR) -C $(PRAWNOS_BUILD)

$(KERNEL_PATCHED): $(KERNEL_EXTRACTED)
	@echo $(PRAWNOS_KERNEL_BUILD)
	$(PRAWNOS_KERNEL_SCRIPTS_PATCH) $(KVER) $(KERNEL_PATCHES) $(PRAWNOS_KERNEL_BUILD) $(TARGET)
	touch $(KERNEL_PATCHED)

$(PRAWNOS_KERNEL_BUILT): $(PRAWNOS_INITRAMFS_IMAGE) $(KERNEL_PATCHED)
	rm -rf $(KERNEL_BUILD_LOG)
	$(PRAWNOS_KERNEL_SCRIPTS_BUILD) $(KVER) $(KERNEL_RESOURCES) $(PRAWNOS_KERNEL_BUILD) $(PRAWNOS_INITRAMFS_IMAGE) $(TARGET) 2>&1 | tee $(KERNEL_BUILD_LOG)

endif
