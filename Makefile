# Base name of distribution and release files
NAME	=	samples

# Version is read from first paragraph of REAMDE file
#~ VERSION		?=	$(shell grep '^FABUI [0-9]\+\.[0-9]\+' README.md README.md | head -n1 | cut -d' ' -f2)
VERSION		?=	$(shell date +%Y%m%d)

# Priority for colibri bundle
PRIORITY	?= 080

# FABUI license
LICENSE		?= CC0

# Buncle compression method
# Available:
# - xz		Best compression with slowest access time
# - gzip	Bit better access time then xz but worse compressiong rate
# - lzo		Best access time with worst compression rate (>50% worse then xz)
BUNDLE_COMP		?= xz

# OS flavour identifier
OS_FLAVOUR	?= colibri

# FAB-UI system paths
LIB_PATH		?= /var/lib/fabui/
SHARED_PATH		?= /usr/share/fabui/
METADATA_PATH	?= /var/lib/colibri/bundle/$(NAME)
WWW_PATH		?= /var/www/
MOUNT_BASE_PATH	?= /mnt/
FABUI_PATH		?= $(SHARED_PATH)
TASKS_PATH		?= $(WWW_PATH)tasks/
RECOVERY_PATH	?= $(FABUI_PATH)recovery/
UPLOAD_PATH		?= $(WWW_PATH)upload/
FABUI_TEMP_PATH	?= $(WWW_PATH)temp/
PYTHON_PATH		?= $(FABUI_PATH)ext/py/
BASH_PATH		?= $(FABUI_PATH)ext/bash/
TEMP_PATH		?= /tmp/
RUN_PATH		?= /run/$(NAME)/
BIGTEMP_PATH	?= $(MOUNT_BASE_PATH)bigtmp/
USERDATA_PATH	?= $(MOUNT_BASE_PATH)userdata/
DB_PATH			?= $(LIB_PATH)/
USB_MEDIA_PATH	?= /run/media/

# FAB-UI parameters
SERIAL_PORT 	?= /dev/ttyAMA0


########################## Input Files #################################
# File paths of local files taht will be installed to the configured
# paths according to their type


# <files>/* is to avoid making <files>/<files> path
#PYTHON_FILES	= 	fabui/ext/py*
# <files>/* is to avoid making <files>/<files> path
#SCRIPT_FILES	=	fabui/ext/bash/*

# Files that will end up in WWW_PATH
WWW_FILES		= 
					
# Files that will end up in FABUI_PATH
FABUI_FILES		=	

# <files>/* is to avoid making <files>/<files> path
RECOVERY_FILES	=	samples

CONFIG_FILES	=

# Files that will end up in SHARED_PATH
STATIC_FILES	=	

# Files that will end up in LIB_PATH
DYNAMIC_FILES	=	

# List of files that should go through the generator script
GENERATED_FILES = 

########################################################################

# Build/Install paths
DESTDIR 		?= .
TEMP_DIR 		= ./temp
BDATA_DIR 		= $(TEMP_DIR)/bdata
BDATA_STAMP		= $(TEMP_DIR)/.bdata_stamp

ifneq ($(VERSION),)
CUSTOM_BUNDLE	= $(DESTDIR)/$(PRIORITY)-$(NAME)-v$(VERSION).cb
else
CUSTOM_BUNDLE	= $(DESTDIR)/$(PRIORITY)-$(NAME)-devel.cb
endif

OS_FILES_DIR	= ./os

# This is not a mistake. OS_STAMP is general dependency used bundle rule
OS_STAMP		= $(TEMP_DIR)/.os_$(OS_FLAVOUR)_stamp
# OS_COLIBRI_STAMP is specific stamp used in case OS_FLAVOUR is colibri
OS_COLIBRI_STAMP= $(TEMP_DIR)/.os_colibri_stamp

OS_COMMON_STAMP	= $(TEMP_DIR)/.os_common_stamp

# Tools
INSTALL			?= install
FAKEROOT 		?= fakeroot
FAKEROOT_ENV 	= $(FAKEROOT) -s $(TEMP_DIR)/.fakeroot_env -i $(TEMP_DIR)/.fakeroot_env -- 
MKSQUASHFS		?= mksquashfs
########################### Makefile rules #############################

all: $(CUSTOM_BUNDLE)

clean:
	rm -rf $(TEMP_DIR)
	rm -rf $(CONFIG_FILES)
	rm -rf $(DB_FILES)
	
distclean: clean
	rm -rf *.cb
	rm -rf *.cb.md5sum
	rm -f $(GENERATED_FILES)
	

check-tools:
	@echo "Looking for fakeroot"
	@which fakeroot &> /dev/null
	@echo "OK"
	@echo "Looking for mksquashfs"
	@which mksquashfs  &> /dev/null
	@echo "OK"

bundle: $(CUSTOM_BUNDLE)

# Collects rules of all *.in files and uses the generator on them.
% : %.in
	./generate_config.sh $^ $@ \
		WWW_PATH=$(WWW_PATH) \
		FABUI_PATH=$(FABUI_PATH) \
		PYTHON_PATH=$(PYTHON_PATH) \
		BASH_PATH=$(BASH_PATH) \
		TASKS_PATH=$(TASKS_PATH) \
		RECOVERY_PATH=$(RECOVERY_PATH) \
		TEMP_PATH=$(TEMP_PATH) \
		FABUI_TEMP_PATH=$(FABUI_TEMP_PATH) \
		UPLOAD_PATH=$(UPLOAD_PATH) \
		LIB_PATH=$(LIB_PATH) \
		SHARED_PATH=$(SHARED_PATH) \
		BIGTEMP_PATH=$(BIGTEMP_PATH) \
		USERDATA_PATH=$(USERDATA_PATH) \
		USB_MEDIA_PATH=$(USB_MEDIA_PATH) \
		SERIAL_PORT=$(SERIAL_PORT)

$(TEMP_DIR):
	mkdir -p $@
	
$(BDATA_DIR):
	mkdir -p $@

$(BDATA_STAMP): $(TEMP_DIR) $(BDATA_DIR) $(DB_FILES) $(GENERATED_FILES)
# 	Copy www files
ifneq ($(WWW_FILES),)
	$(FAKEROOT_ENV) mkdir -p $(BDATA_DIR)$(WWW_PATH)
	$(FAKEROOT_ENV) cp -R $(WWW_FILES) 		$(BDATA_DIR)$(WWW_PATH)
endif
# 	Copy fabui files
ifneq ($(FABUI_FILES),)
	$(FAKEROOT_ENV) mkdir -p $(BDATA_DIR)$(FABUI_PATH)
	$(FAKEROOT_ENV) cp -R $(FABUI_FILES) 		$(BDATA_DIR)$(FABUI_PATH)
endif
# 	Copy recovery files
ifneq ($(RECOVERY_FILES),)
	$(FAKEROOT_ENV) mkdir -p $(BDATA_DIR)$(RECOVERY_PATH)
	$(FAKEROOT_ENV) cp -R $(RECOVERY_FILES) 	$(BDATA_DIR)$(RECOVERY_PATH)
endif
#	Install static files
ifneq ($(STATIC_FILES),)
	$(FAKEROOT_ENV)mkdir -p $(BDATA_DIR)$(SHARED_PATH)
	$(FAKEROOT_ENV) cp -a $(STATIC_FILES) $(BDATA_DIR)$(SHARED_PATH)
endif
#	Install dynamic files
ifneq ($(DYNAMIC_FILES),)
#	Create runtime data directory
	$(FAKEROOT_ENV) $(INSTALL) -d -o 33 -g 33 -m 0755 $(BDATA_DIR)$(LIB_PATH)
	$(FAKEROOT_ENV) cp -a $(DYNAMIC_FILES) $(BDATA_DIR)$(LIB_PATH)
endif
#	Create sym-links

#	The autoinstall flag file is created at compile time

#	Public runtime directories

########################################################################
# 	Fix permissions
ifneq ($(WWW_FILES),)
	$(FAKEROOT_ENV) chown -R 33:33 $(BDATA_DIR)$(WWW_PATH)
endif
ifneq ($(DYNAMIC_FILES),)
	$(FAKEROOT_ENV) chown -R 33:33 $(BDATA_DIR)$(LIB_PATH)
endif
########################################################################
#	Add metadata
	$(FAKEROOT_ENV) mkdir -p $(BDATA_DIR)$(METADATA_PATH)
#	metadata/info
	$(FAKEROOT_ENV) echo "name: $(NAME)" >> $(BDATA_DIR)$(METADATA_PATH)/info
	$(FAKEROOT_ENV) echo "version: $(VERSION)" >> $(BDATA_DIR)$(METADATA_PATH)/info
	$(FAKEROOT_ENV) echo "build-date: $(shell date +%Y-%m-%d)" >> $(BDATA_DIR)$(METADATA_PATH)/info
#	metadata/packages
	$(FAKEROOT_ENV) echo "$(NAME): $(VERSION)" >> $(BDATA_DIR)$(METADATA_PATH)/packages
#	metadata/licenses
	$(FAKEROOT_ENV) echo "$(NAME): $(LICENSE)" >> $(BDATA_DIR)$(METADATA_PATH)/licenses
#	license files
	$(FAKEROOT_ENV) mkdir -p $(BDATA_DIR)/usr/share/licenses/$(NAME)
	$(FAKEROOT_ENV) cp LICENSE $(BDATA_DIR)/usr/share/licenses/$(NAME)
# 	Create a stamp file
	touch $@

$(OS_COLIBRI_STAMP):
#	OS specific files
# 	Create a stamp file
	touch $@
	
$(OS_COMMON_STAMP):
#	OS common files
# 	Create a stamp file
	touch $@
		
$(CUSTOM_BUNDLE): $(BDATA_STAMP) $(OS_COMMON_STAMP) $(OS_STAMP)
	$(FAKEROOT_ENV) $(MKSQUASHFS) $(BDATA_DIR) $@ -noappend -comp $(BUNDLE_COMP) -b 512K -no-xattrs
	md5sum $@ > $@.md5sum
