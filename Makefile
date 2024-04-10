NAME = Astrolabe

.SECONDARY:
SHELL = bash
MAKEFLAGS := -sr
PYTHON := python3

SOURCEDIR = sources
GLYPHSFILE = ${SOURCEDIR}/${NAME}.glyphspackage
FONTSDIR = fonts

VERSION=$(shell git describe --tags --abbrev=0)
export SOURCE_DATE_EPOCH ?= $(shell stat -c "%Y" ${GLYPHSFILE})

all: ttf
ttf: ${FONTSDIR}/${NAME}.ttf

${FONTSDIR}/${NAME}.ttf: ${GLYPHSFILE}
	echo "    MAKE    $(@F)"
	mkdir -p $(@D)
	${PYTHON} -m fontmake $< \
	                      --verbose=WARNING \
	                      --output-path=$@ \
						  --output=variable

dist:
	echo "    DIST    ${DIST}"
	cp OFL.txt AUTHORS.txt CONTRIBUTORS.txt README.md ${DIST}
	echo "    ZIP     ${DIST}.zip"
	zip -rq ${DIST}.zip ${DIST}
