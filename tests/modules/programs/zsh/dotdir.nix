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
    else if case == "shell-variable" then
      "\${XDG_CONFIG_HOME:-\$HOME/.config}/zsh"
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

    test.asserts.warnings.expected = lib.optionals (case == "relative") [
      ''
        Using relative paths in programs.zsh.dotDir is deprecated and will be removed in a future release.
        Current dotDir: subdir/subdir2
        Consider using absolute paths or home-manager config options instead.
        You can replace relative paths or environment variables with options like:
        - config.home.homeDirectory (user's home directory)
        - config.xdg.configHome (XDG config directory)
        - config.xdg.dataHome (XDG data directory)
        - config.xdg.cacheHome (XDG cache directory)
      ''
    ];

    test.asserts.assertions.expected = lib.optionals (case == "shell-variable") [
      ''
        programs.zsh.dotDir cannot contain shell variables as it is used for file creation at build time.
        Current dotDir: ''${XDG_CONFIG_HOME:-''$HOME/.config}/zsh
        Consider using an absolute path or home-manager config options instead.
        You can replace shell variables with options like:
        - config.home.homeDirectory (user's home directory)
        - config.xdg.configHome (XDG config directory)
        - config.xdg.dataHome (XDG data directory)
        - config.xdg.cacheHome (XDG cache directory)
      ''
    ];

    nmt.script =
      if case == "shell-variable" then
        ''
          # Shell variable case should fail assertion, no files to check
          echo "Shell variable case should trigger assertion failure"
        ''
      else
        lib.concatStringsSep "\n" [
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
