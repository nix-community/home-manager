{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.firejail;

  wrappedBins = pkgs.runCommandLocal "firejail-wrapped-binaries"
    {
      # override packages added from other modules in PATH
      meta.priority = -5;
    }
    ''
      mkdir -p $out/bin
      ${concatStringsSep "\n" (mapAttrsToList (command: value:
      let
        opts = if isAttrs value
        then value
        else { executable = value; profile = null; extraArgs = []; };
        args = escapeShellArgs (
          opts.extraArgs
          ++ (optional (opts.profile != null) "--profile=${toString opts.profile}")
          );
      in
      ''
        cat <<_EOF >$out/bin/${command}
        #! ${pkgs.runtimeShell} -e
        exec ${cfg.firejailBinary} ${args} ${toString opts.executable} "\$@"
        _EOF
        chmod 0755 $out/bin/${command}
      '') cfg.wrappedBinaries)}
    '';

in
{
  options.programs.firejail = {
    firejailBinary = mkOption {
      type = types.path;
      default = "/run/wrappers/bin/firejail";
      description = mdDoc "The firejail executable with setuid installed using your package manager";
      example = "/bin/firejail";
    };

    wrappedBinaries = mkOption {
      type = types.attrsOf (types.either types.path (types.submodule {
        options = {
          executable = mkOption {
            type = types.path;
            description = mdDoc "Executable to run sandboxed";
            example = literalExpression ''"''${getBin pkgs.firefox}/bin/firefox"'';
          };
          profile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = mdDoc "Profile to use";
            example = literalExpression ''"''${pkgs.firejail}/etc/firejail/firefox.profile"'';
          };
          extraArgs = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = mdDoc "Extra arguments to pass to firejail";
            example = [ "--private=~/.firejail_home" ];
          };
        };
      }));
      default = { };
      example = literalExpression ''
        {
          firefox = {
            executable = "''${getBin pkgs.firefox}/bin/firefox";
            profile = "''${pkgs.firejail}/etc/firejail/firefox.profile";
          };
          mpv = {
            executable = "''${getBin pkgs.mpv}/bin/mpv";
            profile = "''${pkgs.firejail}/etc/firejail/mpv.profile";
          };
        }
      '';
      description = mdDoc ''
        Wrap the binaries in firejail and place them in your path.
        You still need to install firejail globally using your package manager.
        You will get file collisions if you put the actual application binary in
        the environment (such as by adding the application package to
        `home.packages`), and applications started via .desktop files are not
        wrapped if they specify the absolute path to the binary.
      '';
    };
  };

  config = mkIf (cfg.wrappedBinaries != { }) {
    home.packages = [ wrappedBins ];
  };

  meta.maintainers = with maintainers; [ vawvaw ];
}
