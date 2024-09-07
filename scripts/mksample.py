import argparse

from blackrenderer.font import BlackRendererFont
from blackrenderer.backends.svg import SVGSurface
from blackrenderer.render import buildGlyphLine, calcGlyphLineBounds
from fontTools.misc.arrayTools import insetRect, offsetRect, unionRect

import uharfbuzz as hb


def parseFeatures(text):
    if not text:
        return {}
    features = {}
    for feature in text.split(","):
        value = 1
        start = 0
        end = -1
        if feature[0] == "-":
            value = 0
        if feature[0] in ("+", "-"):
            feature = feature[1:]
        tag = feature
        if "[" in feature:
            tag, extra = feature.split("[")
            if "=" in extra:
                extra, value = extra.split("=")
            if extra[-1] == "]":
                extra = extra[:-1]
                start = end = extra
                if ":" in extra:
                    start, end = extra.split(":")
        features[tag] = [[int(value), int(start), int(end)]]
    return features


def makeLine(buf, font, y):
    line = buildGlyphLine(buf.glyph_infos, buf.glyph_positions, font.glyphNames)

    xMin, yMin, xMax, yMax = calcGlyphLineBounds(line, font)
    rect = offsetRect((xMin, yMin, xMax, yMax), 0, y)

    height = -yMin + yMax

    return line, rect, height


def draw(
    surface: SVGSurface,
    path: str,
    text: str,
    features: str,
    foreground: None | tuple[int, int, int, int],
    background: None | tuple[int, int, int, int],
):
    margin = 100
    bounds = None
    lines = []
    y = margin
    font = BlackRendererFont(path)
    locations = [None]
    if "fvar" in font.ttFont:
        locations = sorted(
            [i.coordinates for i in font.ttFont["fvar"].instances],
            key=lambda x: x.get("wght"),
        )
    for location in reversed(locations):
        font = BlackRendererFont(path)
        if location is not None:
            font.setLocation(location)

        for textLine in reversed(text.split("\n")):
            buf = hb.Buffer()
            buf.add_str(textLine)
            buf.guess_segment_properties()
            hb.shape(font.hbFont, buf, features)

            line, rect, height = makeLine(buf, font, y)
            lines.append((font, line, rect, y))

            if bounds is None:
                bounds = rect
            bounds = unionRect(bounds, rect)
            y += height + margin

    bounds = insetRect(bounds, -margin, -margin)
    with surface.canvas(bounds) as canvas:
        if background:
            canvas.drawRectSolid(surface._viewBox, background)
        for font, line, rect, y in lines:
            with canvas.savedState():
                # Center align the line.
                x = (bounds[2] - rect[2]) / 2 - margin
                canvas.translate(x, y)
                for glyph in line:
                    with canvas.savedState():
                        canvas.translate(glyph.xOffset, glyph.yOffset)
                        if foreground:
                            font.drawGlyph(glyph.name, canvas, textColor=foreground)
                        else:
                            font.drawGlyph(glyph.name, canvas)
                    canvas.translate(glyph.xAdvance, glyph.yAdvance)


def parseColor(color):
    if len(color) == 8:
        return tuple(int(color[i : i + 2], 16) / 255 for i in (2, 4, 6))
    assert len(color) == 6, color
    return tuple(int(color[i : i + 2], 16) / 255 for i in (0, 2, 4)) + (1,)


def main(argv=None):
    parser = argparse.ArgumentParser(description="Create SVG sample.")
    parser.add_argument("font", help="input font")
    parser.add_argument("-t", "--text", help="input text", required=True)
    parser.add_argument("-f", "--features", help="input features")
    parser.add_argument("-o", "--output", help="output SVG", required=True)
    parser.add_argument("--foreground", help="foreground color", type=parseColor)
    parser.add_argument("--background", help="background color", type=parseColor)

    args = parser.parse_args(argv)

    surface = SVGSurface()
    features = parseFeatures(args.features)
    draw(
        surface,
        args.font,
        args.text,
        features,
        args.foreground,
        args.background,
    )
    surface.saveImage(args.output)


if __name__ == "__main__":
    import sys

    sys.exit(main())
