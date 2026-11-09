#!/usr/bin/env python3

"""
Make the chart of the Adriatic for the sailing: the coastlines of the land and
the islands, from Natural Earth (public domain), in kilometres.

We download the 1:10m land and minor islands of Natural Earth (pinned by their
SHA-256), keep the polygons around the Adriatic and the north of the Ionian
Sea, clip them to that box, project them to kilometres (an equirectangular
projection around the middle of the Adriatic, which is accurate enough for a
sea this small), simplify them, and write data/world/adriatic_map.json.

The game places the ports with the same projection (the constants are in the
file), so the ports always lie on the coast of the chart.
"""

import hashlib
import json
import math
import pathlib
import sys
import urllib.request
from typing import List, Sequence, Tuple

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
CACHE_DIR = REPO_ROOT / ".cache" / "maps"
TARGET = REPO_ROOT / "data" / "world" / "adriatic_map.json"

NATURAL_EARTH = "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/"

SOURCES = {
    "ne_10m_land.geojson": "1ac90796408bc6ad6911d69448485d3c4dbf2190370080368a09976e1c9f7416",
    "ne_10m_minor_islands.geojson": "8c933ca7a4760256bdc46408355706e39764b0fa01c160c28888b90b4faec29f",
}

#: The box of the chart: (west, south, east, north) in degrees.
BOX = (12.0, 38.6, 21.2, 46.0)

#: The projection: kilometres east and south of (LON0, LAT0).
LON0 = 16.0
LAT0 = 43.0
KM_PER_DEGREE_LAT = 111.2
KM_PER_DEGREE_LON = KM_PER_DEGREE_LAT * math.cos(math.radians(LAT0))

#: Simplify the coastlines to this tolerance, in kilometres.
TOLERANCE_KM = 0.12

#: Drop the islands smaller than this, in square kilometres.
MIN_AREA_KM2 = 0.03

Point = Tuple[float, float]


def download(name: str, sha256: str) -> pathlib.Path:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    target = CACHE_DIR / name
    if not target.exists():
        url = NATURAL_EARTH + name
        print(f"Downloading {url}")
        with urllib.request.urlopen(url, timeout=300) as response:
            target.write_bytes(response.read())
    digest = hashlib.sha256(target.read_bytes()).hexdigest()
    if digest != sha256:
        target.unlink()
        raise RuntimeError(f"The SHA-256 of {name} is {digest}, but we expected {sha256}")
    return target


def rings(geometry: dict) -> List[List[Point]]:
    """The outer rings of the polygons of a GeoJSON geometry."""
    if geometry["type"] == "Polygon":
        return [[tuple(p) for p in geometry["coordinates"][0]]]
    if geometry["type"] == "MultiPolygon":
        return [[tuple(p) for p in polygon[0]] for polygon in geometry["coordinates"]]
    return []


def clip(ring: Sequence[Point], box: Tuple[float, float, float, float]) -> List[Point]:
    """Clip a ring to the box (Sutherland-Hodgman)."""
    west, south, east, north = box

    def clip_edge(points, inside, intersect):
        result: List[Point] = []
        if not points:
            return result
        previous = points[-1]
        for current in points:
            if inside(current):
                if not inside(previous):
                    result.append(intersect(previous, current))
                result.append(current)
            elif inside(previous):
                result.append(intersect(previous, current))
            previous = current
        return result

    def at_x(x):
        return lambda a, b: (x, a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0]))

    def at_y(y):
        return lambda a, b: (a[0] + (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1]), y)

    points = list(ring)
    points = clip_edge(points, lambda p: p[0] >= west, at_x(west))
    points = clip_edge(points, lambda p: p[0] <= east, at_x(east))
    points = clip_edge(points, lambda p: p[1] >= south, at_y(south))
    points = clip_edge(points, lambda p: p[1] <= north, at_y(north))
    return points


def project(point: Point) -> Point:
    lon, lat = point
    return ((lon - LON0) * KM_PER_DEGREE_LON, -(lat - LAT0) * KM_PER_DEGREE_LAT)


def simplify(points: List[Point], tolerance: float) -> List[Point]:
    """Simplify a polyline (Ramer-Douglas-Peucker, iterative)."""
    if len(points) < 3:
        return points
    keep = [False] * len(points)
    keep[0] = keep[-1] = True
    stack = [(0, len(points) - 1)]
    while stack:
        first, last = stack.pop()
        ax, ay = points[first]
        bx, by = points[last]
        dx, dy = bx - ax, by - ay
        length = math.hypot(dx, dy)
        farthest, index = 0.0, -1
        for i in range(first + 1, last):
            px, py = points[i]
            if length == 0.0:
                distance = math.hypot(px - ax, py - ay)
            else:
                distance = abs(dy * px - dx * py + bx * ay - by * ax) / length
            if distance > farthest:
                farthest, index = distance, i
        if farthest > tolerance and index >= 0:
            keep[index] = True
            stack.append((first, index))
            stack.append((index, last))
    return [p for p, k in zip(points, keep) if k]


def area(points: Sequence[Point]) -> float:
    total = 0.0
    for (x1, y1), (x2, y2) in zip(points, list(points[1:]) + [points[0]]):
        total += x1 * y2 - x2 * y1
    return abs(total) / 2.0


def main() -> int:
    polygons: List[List[Point]] = []
    for name, sha256 in SOURCES.items():
        data = json.loads(download(name, sha256).read_text(encoding="utf-8"))
        for feature in data["features"]:
            for ring in rings(feature["geometry"]):
                xs = [p[0] for p in ring]
                ys = [p[1] for p in ring]
                if max(xs) < BOX[0] or min(xs) > BOX[2] or max(ys) < BOX[1] or min(ys) > BOX[3]:
                    continue
                clipped = clip(ring, BOX)
                if len(clipped) < 3:
                    continue
                projected = [project(p) for p in clipped]
                if projected[0] != projected[-1]:
                    projected.append(projected[0])
                simple = simplify(projected, TOLERANCE_KM)[:-1]
                if len(simple) < 3 or area(simple) < MIN_AREA_KM2:
                    continue
                polygons.append(simple)

    polygons.sort(key=area, reverse=True)
    west, south = project((BOX[0], BOX[1]))
    east, north = project((BOX[2], BOX[3]))
    chart = {
        "source": "Natural Earth 1:10m land and minor islands, v5.1.2 (public domain)",
        "projection": {
            "lon0": LON0,
            "lat0": LAT0,
            "km_per_degree_lon": KM_PER_DEGREE_LON,
            "km_per_degree_lat": KM_PER_DEGREE_LAT,
            "note": "x = (lon - lon0) * km_per_degree_lon, y = -(lat - lat0) * km_per_degree_lat",
        },
        "bounds_km": [
            round(west, 2),
            round(north, 2),
            round(east - west, 2),
            round(south - north, 2),
        ],
        "polygons": [[[round(x, 3), round(y, 3)] for x, y in polygon] for polygon in polygons],
    }
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text(json.dumps(chart, separators=(",", ":")) + "\n", encoding="utf-8")
    points = sum(len(p) for p in polygons)
    size = TARGET.stat().st_size / 1024
    print(
        f"Wrote {TARGET.relative_to(REPO_ROOT)}: {len(polygons)} polygons, {points} points, {size:.0f} KiB"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
