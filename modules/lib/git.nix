{ lib }:

{
  diffPagerConfig = pagerCommand: {
    pager = lib.genAttrs [
      "diff"
      "log"
      "show"
    ] (_: pagerCommand);
  };
}
