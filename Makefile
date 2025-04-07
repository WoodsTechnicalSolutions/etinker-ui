# Makefile for etinker-ui

BUILD_OS := $(shell uname -o)

DEBIAN := $(shell dpkg-architecture 2>/dev/null)

ifeq ($(DEBIAN),)
# Generic Linux host system
HOST_ARCH := $(shell uname -m 2>/dev/null)
else
# Debian/Ubuntu host system
HOST_ARCH := $(shell dpkg-architecture -qDEB_HOST_GNU_CPU 2>/dev/null)
endif

CXX = g++

TARGET_EXE = etinker-ui

FLTK_VERSION := 1.4.2

FLUID_SOURCES = $(shell ls *.fl 2>/dev/null)
FLUID_OBJECTS = $(patsubst %.fl,%.o,$(FLUID_SOURCES))
FLUID_CPP = $(patsubst %.fl,%.cpp,$(FLUID_SOURCES))
FLUID_CPP += $(patsubst %.fl,%.h,$(FLUID_SOURCES))

SOURCES = $(shell ls *.cpp 2>/dev/null)
SOURCES_EXTRA = Makefile
SOURCES_EXTRA += $(FLUID_SOURCES)
SOURCES_EXTRA += $(shell ls *.h 2>/dev/null)
OBJECTS = $(patsubst %.cpp,%.o,$(SOURCES))

DEBUG = yes
CXXFLAGS = -g
CXXFLAGS += -D_REENTRANT
CXXFLAGS += $(shell fltk-config --use-images --use-cairo --cxxflags 2>/dev/null)
CXXFLAGS += -I.

LDFLAGS = -L/lib -L/usr/lib
ifneq ($(DEBIAN),)
LDFLAGS += \
	-L/lib/$(shell dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null) \
	-L/usr/lib/$(shell dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null)
endif

LDLIBS = -lc -lrt -lpthread -lz
LDLIBS += $(shell fltk-config --use-images --use-cairo --ldflags 2>/dev/null)

.PHONY: all
all: $(TARGET_EXE)

$(TARGET_EXE): $(FLUID_CPP) $(OBJECTS) $(SOURCES_EXTRA)
	$(CXX) $(LDFLAGS) $(OBJECTS) -o $@ $(LDLIBS)

%.o: %.cpp | /usr/bin/fluid
	$(CXX) $(CXXFLAGS) -o $@ -c $<

%.cpp %.h: %.fl | /usr/bin/fluid
	@fluid -c $<

.PHONY: fluid
fluid: /usr/bin/fluid
	@fluid $(TARGET_EXE).fl

/usr/bin/fluid: fltk-git-check
	@if ! [ -n "`which cmake 2>/dev/null`" ]; then \
		printf "***** 'cmake' IS MISSING *****\n"; \
		exit 2; \
	fi
	@if ! [ -f /usr/bin/fluid ]; then \
		(cd fltk && \
			mkdir -p build && cd build &&\
			cmake .. \
				-DCMAKE_INSTALL_PREFIX=/usr \
				-DCMAKE_INSTALL_LIBDIR=lib/$(shell dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null) \
				-DCMAKE_BUILD_TYPE=Release \
				-DFLTK_BUILD_SHARED_LIBS=on \
				-DFLTK_GRAPHICS_CAIRO=on -DFLTK_OPTION_CAIRO_EXT=on -DFLTK_OPTION_CAIRO_WINDOW=on -DFLTK_USE_PANGO=on \
				-DFLTK_BUILD_HTML_DOCS=on -DFLTK_BUILD_FLUID_DOCS=on -DFLTK_BUILD_PDF_DOCS=on \
				-DFLTK_OPTION_OPTIM=-fPIC && \
			make && \
			make docs && \
			sudo make install && \
			if ! [ -f /usr/bin/fluid ]; then \
				printf "***** FLTK BUILD FAILED *****\n"; \
				exit 2; \
			fi); \
	fi

fltk-%:
	@if [ -d fltk/build ] && [ -f fltk/build/Makefile ]; then \
		if [ "install" = "`echo $(*F)|grep -o install`" ]; then \
			(cd fltk/build && sudo make $(*F)); \
		else \
			(cd fltk/build && make $(*F)); \
		fi; \
	fi

fltk-git-%:
	@if ! [ -d fltk ]; then \
		git clone https://github.com/fltk/fltk; \
		if ! [ -d fltk ]; then \
			printf "***** FLTK GIT CLONE FAILED *****\n"; \
			exit 2; \
		fi; \
		(cd fltk && git checkout release-$(FLTK_VERSION)); \
	else \
		if ! [ "check" = "$(*F)" ]; then \
			(cd fltk && git $(*F)); \
		fi; \
	fi
		
.PHONY: clean
clean:
	$(RM) $(OBJECTS)
	$(RM) $(TARGET_EXE)

.PHONY: distclean
distclean: clean
	$(RM) -r fltk/build

.PHONY: env
env:
	@printf "========================================================================\n"
	@printf "TARGET_EXE    : $(TARGET_EXE)\n"
	@printf "BUILD_OS      : $(BUILD_OS)\n"
	@printf "HOST_ARCH     : $(HOST_ARCH)\n"
	@printf "CXX           : $(CXX)\n"
	@printf "CXXFLAGS      : $(CXXFLAGS)\n"
	@printf "LDLIBS        : $(LDLIBS)\n"
	@printf "LDFLAGS       : $(LDFLAGS)\n"
	@printf "SOURCES       : $(SOURCES)\n"
	@printf "SOURCES_EXTRA : $(SOURCES_EXTRA)\n"
	@printf "OBJECTS       : $(OBJECTS)\n"
	@printf "FLUID_SOURCES : $(FLUID_SOURCES)\n"
	@printf "FLUID_OBJECTS : $(FLUID_OBJECTS)\n"
	@printf "FLUID_CPP     : $(FLUID_CPP)\n"
	@printf "========================================================================\n"
	@printf "PATH          : $(PATH)\n"
	@printf "========================================================================\n"
