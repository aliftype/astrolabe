NAME = Astrolabe

SHELL = bash
MAKEFLAGS := -sr
PYTHON := python3

SOURCEDIR = sources
GLYPHSFILE = ${SOURCEDIR}/${NAME}.glyphspackage
FONTSDIR = fonts
FONTS = ${FONTSDIR}/${NAME}.ttf

VERSION=$(shell git describe --tags --abbrev=0)
DIST = ${NAME}-${VERSION}

export SOURCE_DATE_EPOCH ?= $(shell stat -c "%Y" ${GLYPHSFILE})

.SECONDARY:
.ONESHELL:
.PHONY: all dist

all: ${FOTS}

${FONTSDIR}/${NAME}.ttf: ${GLYPHSFILE}
	$(info   BUILD  $(@F))
	mkdir -p $(@D)
	${PYTHON} -m fontmake $< \
	                      --verbose=WARNING \
	                      --output-path=$@ \
			      --output=variable

dist: all
	$(info   DIST   ${DIST}.zip)
	install -Dm644 -t ${DIST} ${FONTS}
	install -Dm644 -t ${DIST} README.txt
	#install -Dm644 -t ${DIST} README-Arabic.txt
	install -Dm644 -t ${DIST} LICENSE
	zip -rq ${DIST}.zip ${DIST}
