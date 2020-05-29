{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.powerline-go;

  moduleNames = [
    "aws"
    "cwd"
    "docker"
    "docker-context"
    "dotenv"
    "duration"
    "exit"
    "git"
    "gitlite"
    "hg"
    "host"
    "jobs"
    "kube"
    "load"
    "newline"
    "nix-shell"
    "node"
    "perlbrew"
    "perms"
    "plenv"
    "root"
    "shell-var"
    "shenv"
    "ssh"
    "svn"
    "termtitle"
    "terraform-workspace"
    "time"
    "user"
    "venv"
    "vgo"
  ];

  optionSpecs = [
    {
      name = "alternateSshIcon";
      description = "Show the older, original icon for SSH connections";
      type = types.bool;
    }
    {
      name = "colorizeHostname";
      description =
        "Colorize the hostname based on a hash of itself, or use the PLGO_HOSTNAMEFG and/or PLGO_HOSTNAMEBG env vars.";
      type = types.bool;
    }
    {
      name = "condensed";
      description = "Remove spacing between segments";
      type = types.bool;
    }
    {
      name = "cwdMaxDepth";
      description = "Maximum number of directories to show in path (default 5)";
      type = types.int;
    }
    {
      name = "cwdMaxDirSize";
      description =
        "Maximum number of letters displayed for each directory in the path (default -1)";
      type = types.int;
    }
    {
      name = "cwdMode";
      description = ''How to display the current directory (default "fancy")'';
      type = types.enum [ "fancy" "plain" "dironly" ];
    }
    {
      name = "eastAsianWidth";
      description = "Use East Asian Ambiguous Widths";
      type = types.bool;
    }
    {
      name = "gitAssumeUnchangedSize";
      description =
        "Disable checking for changed/edited files in git repositories where the index is larger than this size (in KB), improves performance (default 2048)";
      type = types.int;
    }
    {
      name = "hostnameOnlyIfSsh";
      description = "Show hostname only for SSH connections";
      type = types.bool;
    }
    {
      name = "ignoreRepos";
      description =
        "A list of git repos to ignore. Repos are identified by their root directory.";
      example = [ "/home/me/work/projects/foo" ];
      type = types.listOf types.str;
    }
    {
      name = "maxWidth";
      description =
        "Maximum width of the shell that the prompt may use, in percent. Setting this to 0 disables the shrinking subsystem.";
      type = types.int;
    }
    {
      name = "mode";
      description = ''
        The characters used to make separators between segments. (default "patched")'';
      type = types.enum [ "patched" "compatible" "flat" ];
    }
    {
      name = "modules";
      description = ''
        The list of modules to load (default "venv,user,host,ssh,cwd,perms,git,hg,jobs,exit,root")'';
      type = types.listOf (types.enum moduleNames);
    }
    {
      name = "newline";
      description = "Show the prompt on a new line";
      type = types.bool;
    }
    {
      name = "numericExitCodes";
      description = "Shows numeric exit codes for errors.";
      type = types.bool;
    }
    {
      name = "pathAliases";
      description =
        "One or more aliases from a path to a short name. An alias maps a path like foo/bar/baz to a short name like FBB. Use '~' for your home dir. You may need to escape this character to avoid shell substitution.";
      example = {
        "$GOPATH/src/github.com" = "@GOPATH-GH";
        "~/work/projects/foo" = "@FOO";
        "~/work/projects/bar" = "@BAR";
      };
      type = types.attrs;
    }
    {
      name = "priority";
      description = ''
        Segments sorted by priority, if not enough space exists, the least priorized segments are removed first. (default "root,cwd,user,host,ssh,perms,git-branch,git-status,hg,jobs,exit,cwd-path")'';
      type = types.listOf (types.enum moduleNames);
    }
    {
      name = "shellVar";
      description = "A shell variable to add to the segments.";
      type = types.str;
    }
    {
      name = "shortenEksNames";
      description = "Shortens names for EKS Kube clusters.";
      type = types.bool;
    }
    {
      name = "shortenGkeNames";
      description = "Shortens names for GKE Kube clusters.";
      type = types.bool;
    }
    {
      name = "staticPromptIndicator";
      description =
        "Always show the prompt indicator with the default color, never with the error color";
      type = types.bool;
    }
    {
      name = "theme";
      description =
        ''Set this to the theme you want to use (default "default")'';
      type = types.enum [ "default" "low-contrast" ];
    }
    {
      name = "truncateSegmentWidth";
      description =
        "Minimum width of a segment, segments longer than this will be shortened if space is limited. Setting this to 0 disables it. (default 16)";
      type = types.int;
    }
  ];

  # Replace a camel case string to dash-separated words. E.g.,
  # converts "someBoolProperty" to "some-bool-property".
  dashify = replaceStrings upperChars (map (l: "-${l}") lowerChars);

  optionSpecIsBool = optionSpec: optionSpec.type == types.bool;

  defaultValue = optionSpec:
    if optionSpecIsBool optionSpec then false else null;

  # Convert an option spec to a Nix option:
  optionSpecToOption = optionSpec: {
    "${optionSpec.name}" = mkOption {
      default = defaultValue optionSpec;
      description = optionSpec.description;
      type = if optionSpecIsBool optionSpec then
        optionSpec.type
      else
        types.nullOr optionSpec.type;
      example = if optionSpec ? example then optionSpec.example else null;
    };
  };

  # Convert all option specs to a set of Nix options:
  nixOptions = builtins.foldl'
    (options: optionSpec: options // (optionSpecToOption optionSpec)) { }
    optionSpecs;

  # Convert an option value to a string to be passed as argument to
  # powerline-go:
  valueToString = value:
    if builtins.isList value then
      builtins.concatStringsSep "," (builtins.map valueToString value)
    else if builtins.isAttrs value then
      valueToString
      (mapAttrsToList (key: val: "${valueToString key}=${valueToString val}")
        value)
    else
      builtins.toString value;

  optionSpecToCommandLineArgument = optionSpec:
    let
      name = optionSpec.name;
      value = valueToString cfg.${name};
      isNotBool = !optionSpecIsBool optionSpec;
    in "-${dashify name}" + optionalString isNotBool (" " + value);

  # Append command line argument for optionSpec at the end of result
  # if the option has a non-default value:
  appendOption = result: optionSpec:
    let
      name = optionSpec.name;
      value = cfg.${name};
      hasDefaultValue = value == defaultValue optionSpec;
    in if !hasDefaultValue then
      result + (optionalString (result != "") " ") + optionSpecToCommandLineArgument optionSpec
    else
      result;

  commandLineArguments = (builtins.foldl' appendOption "" optionSpecs);

in {
  options = {
    programs.powerline-go = nixOptions // {
      enable = mkEnableOption "Powerline-go";

      extraUpdatePS1 = mkOption {
        default = "";
        description =
          "Shell code to add at the end of the _update_ps1() function";
        example = ''
          PS1=$PS1"NixOS> ";
        '';
        type = types.str;
      };
    };
  };

  config = mkIf (cfg.enable && config.programs.bash.enable) {
    programs.bash.initExtra = ''
      function _update_ps1() {
        PS1="$(${pkgs.powerline-go}/bin/powerline-go -error $? ${commandLineArguments})"
        ${cfg.extraUpdatePS1}
      }

      if [ "$TERM" != "linux" ]; then
        PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
      fi
    '';
  };
}
