{
  pkgs,
  optionDocs,
  manpageUrls,
  revision,
}:

pkgs.runCommand "home-manager-mdbook-options"
  {
    nativeBuildInputs = [
      pkgs.buildPackages.nixos-render-docs
      pkgs.buildPackages.python3
    ];
    optionDocsJson = builtins.toJSON optionDocs;
    passAsFile = [ "optionDocsJson" ];
  }
  ''
    python3 ${./render-options.py} \
      "$optionDocsJsonPath" \
      ${manpageUrls} \
      ${revision} \
      "$out"
  ''
