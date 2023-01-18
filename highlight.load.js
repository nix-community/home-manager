/* This file is NOT part of highlight.js */

class PreserveCallouts {

  constructor(options) {
    self.callouts = [];
    /* Using OBJECT REPLACEMENT CHARACTER as a marker of where the callout
       should be inserted. We hope that this won't cause conflicts. */
    self.marker = '\u{FFFC}';
  }

  'before:highlightElement'({el, language}) {
    const re = /<a id="[^"]+"><\/a><span><img src="images\/callouts\/\d+.svg" alt="\d+" border="0"><\/span>/g;
    const array = [...el.innerHTML.matchAll(re)];
    if (array.length > 0) {
      self.callouts = array;
      el.innerHTML = el.innerHTML.replaceAll(re, self.marker);
    }
  }

  'after:highlightElement'({ el, result, text }) {
    if (self.callouts.length > 0) {
      el.innerHTML = el.innerHTML.replaceAll(
        self.marker, (str) => self.callouts.shift());
    }
  }
}

document.addEventListener('DOMContentLoaded', (event) => {
  hljs.addPlugin(new PreserveCallouts());

  document.querySelectorAll('pre.programlisting, pre.screen').forEach((el) => {
    hljs.highlightElement(el);
  });
});
