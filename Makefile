# Copyright (c) 2020-2024 Khaled Hosny
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

NAME = AlifAstrolabe

SHELL = bash
MAKEFLAGS := -srj
PYTHON := venv/bin/python3

SOURCEDIR = sources
SCRIPTDIR = scripts
FONTDIR = fonts
TESTDIR = tests

FONT = ${FONTDIR}/${NAME}.ttf
JSON = ${TESTDIR}/shaping.json
HTML = ${TESTDIR}/shaping.html
SVG = FontSample.svg

GLYPHSFILE = ${SOURCEDIR}/${NAME}.glyphspackage

define SAMPLE
صف خلق خود كمثل الشمس إذ بزغت
يحظى الضجيع بها نجلاء معطار
endef

export SOURCE_DATE_EPOCH ?= $(shell stat -c "%Y" ${GLYPHSFILE})

TAG=$(shell git describe --tags --abbrev=0)
VERSION=$(TAG:v%=%)
DIST = ${NAME}-${VERSION}


.SECONDARY:
.ONESHELL:
.PHONY: all dist ttf test doc

all: ttf doc
ttf: ${FONT}
test: ${HTML}
expectation: ${JSON}
doc: ${SVG}

${FONT}: ${GLYPHSFILE}
	$(info   BUILD  $(@F))
	${PYTHON} -m fontmake $< --output-path=$@ -o variable --verbose=WARNING

${TESTDIR}/%.json: ${TESTDIR}/%.toml ${FONT}
	$(info   GEN    $(@F))
	${PYTHON} ${SCRIPTDIR}/update-shaping-tests.py $< $@ ${FONT}

${TESTDIR}/shaping.html: ${FONT} ${TESTDIR}/shaping-config.yml
	$(info   SHAPE  $(<F))
	${PYTHON} ${SCRIPTDIR}/check-shaping.py $< ${TESTDIR}/shaping-config.yml $@

${SVG}: ${FONT}
	$(info   SVG    $(@F))
	${PYTHON} ${SCRIPTDIR}/make-sample.py -t "${SAMPLE}" -o $@ $<

dist: all
	$(info   DIST   ${DIST}.zip)
	install -Dm644 -t ${DIST} ${FONT}
	install -Dm644 -t ${DIST} README.md
	install -Dm644 -t ${DIST} LICENSE
	zip -rq ${DIST}.zip ${DIST}

clean:
	rm -rf ${FONT} ${SVG} ${DIST} ${DIST}.zip
