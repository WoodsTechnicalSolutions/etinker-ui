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

FLUID_SOURCES = $(shell ls *.fl 2>/dev/null)
FLUID_OBJECTS = $(patsubst %.fl,%.o,$(FLUID_SOURCES))
FLUID_CPP = $(patsubst %.fl,%.cpp,$(FLUID_SOURCES))
FLUID_CPP += $(patsubst %.fl,%.h,$(FLUID_SOURCES))

SOURCES = $(shell ls *.cpp 2>/dev/null)
SOURCES_EXTRA = Makefile
SOURCES_EXTRA += $(shell ls *.h 2>/dev/null)
OBJECTS = $(FLUID_OBJECTS) $(patsubst %.cpp,%.o,$(SOURCES))

DEBUG = yes
CXXFLAGS = -g
CXXFLAGS += -std=c++17 -ansi -Wall -Wno-deprecated-declarations
CXXFLAGS += -D_REENTRANT
CXXFLAGS += $(shell fltk-config --use-images --use-cairo --cxxflags 2>/dev/null)
CXXFLAGS += -I.

LDFLAGS = -L/lib -L/usr/lib
ifneq ($(DEBIAN),)
LDFLAGS += \
	-L/lib/$(shell dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null) \
	-L/usr/lib/$(shell dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null)
endif

LDLIBS = -lc -lrt -lpthread -lz -lcairo
LDLIBS += $(shell fltk-config --use-images --use-cairo --ldflags 2>/dev/null)

.PHONY: all
all: $(TARGET_EXE)

.PHONY: fltk
fltk: /usr/bin/fluid

/usr/bin/fluid:
	@if ! [ -n "`which cmake 2>/dev/null`" ]; then \
		printf "***** 'cmake' IS MISSING *****\n"; \
		exit 2; \
	fi
	@if ! [ -d fltk ]; then \
		git clone https://github.com/fltk/fltk; \
	fi
	@if [ -d fltk ]; then \
		(cd fltk && \
			mkdir -p build && cd build &&\
			cmake .. \
				-DCMAKE_INSTALL_PREFIX=/usr \
				-DCMAKE_INSTALL_LIBDIR=lib/$(shell dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null) \
				-DOPTION_BUILD_TYPE=Release \
				-DOPTION_BUILD_SHARED_LIBS=on \
				-DOPTION_BUILD_EXAMPLES=0 \
				-DOPTION_BUILD_PDF_DOCUMENTATION=on \
				-DOPTION_BUILD_HTML_DOCUMENTATION=on \
				-DOPTION_OPTIM=-fPIC \
				-DOPTION_CAIRO=on \
				-DOPTION_CAIROEXT=on && \
			make && \
			make html && \
			sudo make install); \
		if ! [ -f /usr/bin/fluid ]; then \
			printf "***** FLTK BUILD FAILED *****\n"; \
			exit 2; \
		fi; \
	else \
		printf "***** FLTK GIT CLONE FAILED *****\n"; \
		exit 2; \
	fi

$(TARGET_EXE): fltk $(FLUID_CPP) $(OBJECTS) $(SOURCES_EXTRA)
	$(CXX) $(LDFLAGS) $(OBJECTS) -o $@ $(LDLIBS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -o $@ -c $<

%.cpp %.h: %.fl
	@fluid -c $<

.PHONY: clean
clean:
	$(RM) $(OBJECTS)
	$(RM) $(TARGET_EXE)

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
