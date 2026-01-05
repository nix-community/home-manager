case:
{
  config,
  lib,
  options,
  ...
}:
let
  home = config.home.homeDirectory;
  subDir = "subdir/subdir2";

  dotDirCases = {
    absolute = "${home}/${subDir}";
    relative = subDir;
    inherit (options.programs.zsh.dotDir) default;
    shell-variable = "\${XDG_CONFIG_HOME:-$HOME/.config}/zsh";

    # Path normalization cases
    abs-no-slash = "${home}/subdir";
    abs-slash = "${home}/subdir/";
    rel-no-slash = "subdir";
    rel-slash = "subdir/";
    root-no-slash = "${home}";
    root-slash = "${home}/";
    abs-space = "${home}/subdir with space";
  };

  dotDir = dotDirCases.${case} or (abort "Unknown case: ${case}");

  # Normalize absolute path to match module behavior (no trailing slash)
  absDotDir =
    let
      fullPath = if lib.hasPrefix "/" dotDir then dotDir else "${home}/${dotDir}";
    in
    lib.removeSuffix "/" fullPath;

  # Calculate relative path for file location assertions
  relDotDir =
    let
      # Use the normalized absDotDir to determine relative location
      rawRel = lib.removePrefix home absDotDir;
    in
    if lib.hasPrefix "/" rawRel then lib.removePrefix "/" rawRel else rawRel;

  isRelative = lib.elem case [
    "relative"
    "rel-no-slash"
    "rel-slash"
  ];
in
{
  config = {
    programs.zsh = {
      enable = true;
      inherit dotDir;
    };

    test = {
      stubs.zsh = { };

      asserts = {
        assertions.expected = lib.optionals (case == "shell-variable") [
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

        warnings.expected = lib.optionals isRelative [
          ''
            Using relative paths in programs.zsh.dotDir is deprecated and will be removed in a future release.
            Current dotDir: ${dotDir}
            Consider using absolute paths or home-manager config options instead.
            You can replace relative paths or environment variables with options like:
            - config.home.homeDirectory (user's home directory)
            - config.xdg.configHome (XDG config directory)
            - config.xdg.dataHome (XDG data directory)
            - config.xdg.cacheHome (XDG cache directory)
          ''
        ];
      };
    };

    nmt.script =
      if case == "shell-variable" then
        ''
          # Shell variable case should fail assertion, no files to check
          echo "Shell variable case should trigger assertion failure"
        ''
      else
        lib.concatStringsSep "\n" [
          # check dotDir entrypoint exists
          "assertFileExists 'home-files/${if relDotDir == "" then "" else "${relDotDir}/"}.zshenv'"

          # for non-default dotDir only:
          (lib.optionalString (absDotDir != home) ''
            # check .zshenv in homeDirectory sources .zshenv in dotDir
            assertFileRegex home-files/.zshenv "source ${lib.escapeShellArg "${absDotDir}/.zshenv"}"

            # check that .zshenv in dotDir exports ZDOTDIR
            assertFileRegex 'home-files/${relDotDir}/.zshenv' "export ZDOTDIR=\"${absDotDir}\""
          '')
        ];
  };
}
