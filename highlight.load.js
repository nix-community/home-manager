/* This file is NOT part of highlight.js */
document.addEventListener('DOMContentLoaded', (event) => {
  document.querySelectorAll('pre.programlisting, pre.screen').forEach((block) => {
    hljs.highlightBlock(block);
  });
});
