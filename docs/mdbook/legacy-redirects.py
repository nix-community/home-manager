#!/usr/bin/env python3

import html
import json
import re
import sys
from pathlib import Path


ANCHOR = re.compile(r'<a id="([^"]+)"></a>')
SPECIAL_PAGES = {
    Path("manual.md"): "index.html",
    Path("preface.md"): "index.html",
    Path("options.md"): "options/home-manager/index.html",
    Path("nixos-options.md"): "options/nixos/index.html",
    Path("nix-darwin-options.md"): "options/nix-darwin/index.html",
}
OPTION_PREFIXES = {
    "opt-": "options/home-manager",
    "nixos-opt-": "options/nixos",
    "nix-darwin-opt-": "options/nix-darwin",
}

ROUTER = """
(function () {
  var h = location.hash || "", a = h.slice(1), t = __DEFAULT__;
  var m = __ANCHORS__, p = __PREFIXES__;
  function o(a) {
    for (var k in p) {
      if (a.indexOf(k) !== 0) continue;
      var s = a.slice(k.length).replace(/[<>]/g, "_").split("."), q = s[0];
      if ((q === "programs" || q === "services") && s.length > 1) q += "/" + s[1];
      return p[k] + "/" + q + ".html";
    }
    return null;
  }
  if (a) t = Object.prototype.hasOwnProperty.call(m, a) ? m[a] : o(a) || t;
  if (t === null) return;
  var n = t + (location.search || "") + h;
  var c = location.pathname.split("/").pop() + location.search + h;
  if (n !== c) location.replace(n);
}());
""".strip()


def page_for(source, path):
    relative = path.relative_to(source)
    return SPECIAL_PAGES.get(relative, relative.with_suffix(".html").as_posix())


def anchors_for(source, roots):
    anchors = {}
    for root in roots:
        files = [root] if root.is_file() else sorted(root.rglob("*.md"))
        for path in files:
            page = page_for(source, path)
            for anchor in ANCHOR.findall(path.read_text(encoding="utf-8")):
                anchors.setdefault(anchor, page)
    return anchors


def script(default, anchors):
    js = (
        ROUTER.replace("__DEFAULT__", json.dumps(default))
        .replace(
            "__ANCHORS__", json.dumps(anchors, sort_keys=True, separators=(",", ":"))
        )
        .replace("__PREFIXES__", json.dumps(OPTION_PREFIXES, separators=(",", ":")))
    )
    return "\n".join(
        [
            "    <script>",
            "      //<![CDATA[",
            *[f"      {line}" for line in js.splitlines()],
            "      //]]>",
            "    </script>",
        ]
    )


def write_redirect(output, name, destination, anchors=None):
    escaped = html.escape(destination, quote=True)
    (output / name).write_text(
        f"""<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
  <head>
    <meta charset="utf-8" />
{script(destination, anchors or {})}
    <meta http-equiv="refresh" content="0; url={escaped}" />
    <link rel="canonical" href="{escaped}" />
    <title>Redirecting...</title>
  </head>
  <body>
    <p>Redirecting to <a href="{escaped}">{escaped}</a>.</p>
  </body>
</html>
""",
        encoding="utf-8",
    )


def inject_root_router(output, anchors):
    index = output / "index.html"
    text = index.read_text(encoding="utf-8")
    index.write_text(text.replace("<head>", f"<head>\n{script(None, anchors)}", 1))


def main():
    source, output = map(Path, sys.argv[1:])

    manual_roots = [
        path
        for path in source.iterdir()
        if path.name != "options" and (path.is_dir() or path.suffix == ".md")
    ]
    manual_anchors = anchors_for(source, manual_roots)
    release_anchors = anchors_for(source, [source / "release-notes"])

    inject_root_router(output, manual_anchors)
    for name, destination, anchors in [
        ("index.xhtml", "index.html", manual_anchors),
        ("options.html", "options/home-manager/index.html", {}),
        ("options.xhtml", "options/home-manager/index.html", {}),
        ("nixos-options.xhtml", "options/nixos/index.html", {}),
        ("nix-darwin-options.xhtml", "options/nix-darwin/index.html", {}),
        ("release-notes.xhtml", "release-notes/release-notes.html", release_anchors),
    ]:
        write_redirect(output, name, destination, anchors)


if __name__ == "__main__":
    main()
