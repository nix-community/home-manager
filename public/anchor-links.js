// Add permalink anchors to section headings.
document.addEventListener("DOMContentLoaded", function () {
  var NS = "http://www.w3.org/1999/xhtml";
  var headings = document.querySelectorAll("h1, h2, h3, h4");

  for (var i = 0; i < headings.length; i++) {
    var h = headings[i];

    // Skip headings inside note/warning boxes (those h3s are icon containers).
    if (h.closest("div.note") || h.closest("div.warning")) {
      continue;
    }

    // The id may live on the heading itself or on a child <a id="...">.
    var id = h.id;
    if (!id) {
      var child = h.querySelector("a[id]");
      if (child) {
        id = child.id;
      }
    }
    if (!id) {
      continue;
    }

    var a = document.createElementNS(NS, "a");
    a.setAttribute("class", "anchor-link");
    a.setAttribute("href", "#" + id);
    a.setAttribute("aria-label", "Permalink");
    a.textContent = "\u00B6";
    h.appendChild(a);
  }
});
