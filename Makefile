NAME = Astrolabe

SHELL = bash
MAKEFLAGS := -sr
PYTHON := python3

SOURCEDIR = sources
FONTSDIR = fonts
TESTSDIR = tests

TTF = ${FONTSDIR}/${NAME}.ttf
JSON = ${TESTSDIR}/shaping.json
HTML = ${TESTSDIR}/shaping.html ${TESTSDIR}/qa.html

VERSION=$(shell git describe --tags --abbrev=0)
DIST = ${NAME}-${VERSION}

GLYPHSFILE = ${SOURCEDIR}/${NAME}.glyphspackage

export SOURCE_DATE_EPOCH ?= $(shell stat -c "%Y" ${GLYPHSFILE})

.SECONDARY:
.ONESHELL:
.PHONY: all dist test ${HTML}

all: ${TTF}
test: ${HTML}
expectation: ${JSON}

${FONTSDIR}/${NAME}.ttf: ${GLYPHSFILE}
	$(info   BUILD  $(@F))
	mkdir -p $(@D)
	${PYTHON} -m fontmake $< \
	                      --verbose=WARNING \
	                      --output-path=$@ \
			      --output=variable

${TESTSDIR}/%.json: ${TESTSDIR}/%.toml ${TTF}
	$(info   GEN    $(@F))
	${PYTHON} -m fontbakery.update_shaping_tests $< $@ ${TTF}

${TESTSDIR}/shaping.html: ${TTF} ${TESTSDIR}/fontbakery.yml
	$(info   SHAPE  $(<F))
	${PYTHON} -m fontbakery check-shaping \
	                        --config=${TESTSDIR}/fontbakery.yml \
				$< \
				--html=$@ \
				-e WARN \
				-l PASS \
				-q

${TESTSDIR}/qa.html: ${TTF} ${TESTSDIR}/fontbakery.yml
	$(info   QA     $(<F))
	${PYTHON} -m fontbakery check-universal \
	                        --config=${TESTSDIR}/fontbakery.yml \
				$< \
				--html=$@ \
				-e WARN \
				-q

dist: all
	$(info   DIST   ${DIST}.zip)
	install -Dm644 -t ${DIST} ${FONTS}
	install -Dm644 -t ${DIST} README.txt
	#install -Dm644 -t ${DIST} README-Arabic.txt
	install -Dm644 -t ${DIST} LICENSE
	zip -rq ${DIST}.zip ${DIST}
