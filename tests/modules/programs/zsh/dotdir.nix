case:
{
  config,
  lib,
  options,
  ...
}:
let
  home = config.home.homeDirectory;

  dotDir =
    let
      subDir = "subdir/subdir2";
    in
    if case == "absolute" then
      "${home}/${subDir}"
    else if case == "relative" then
      subDir
    else if case == "default" then
      options.programs.zsh.dotDir.default
    else
      abort "Test condition not provided.";

  absDotDir = lib.optionalString (!lib.hasPrefix home dotDir) "${home}/" + dotDir;
  relDotDir = lib.removePrefix home dotDir;
in
{
  config = {
    programs.zsh = {
      enable = true;
      inherit dotDir;
    };

    test.stubs.zsh = { };

    nmt.script = lib.concatStringsSep "\n" [
      # check dotDir entrypoint exists
      "assertFileExists home-files/${relDotDir}/.zshenv"

      # for non-default dotDir only:
      (lib.optionalString (case != "default") ''
        # check .zshenv in homeDirectory sources .zshenv in dotDir
        assertFileRegex home-files/.zshenv \
          "source [\"']\?${absDotDir}/.zshenv[\"']\?"

        # check that .zshenv in dotDir exports ZDOTDIR
        assertFileRegex home-files/${relDotDir}/.zshenv \
          "export ZDOTDIR=[\"']\?${absDotDir}[\"']\?"
      '')
    ];
  };
}
