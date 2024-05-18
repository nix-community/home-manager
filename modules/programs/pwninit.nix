{ pkgs, lib, config, ... }:
let
  inherit (lib) mkEnableOption mkPackageOption mkOption mkIf types;
  cfg = config.programs.pwninit;
in {
  meta.maintainers = [ lib.hm.maintainer.soratenshi ];

  options = {
    programs.pwninit = {
      enable = mkEnableOption
        "A tool for automating starting binary exploit challenges";
      package = mkPackageOption pkgs "pwninit" { };

      template = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The pwninit template.";
        example = ''
          #!/usr/bin/env python3
          from pwn import *
          import warnings

          warnings.filterwarnings(action='ignore', category=BytesWarning)

          {bindings}

          context.binary = {bin_name}

          IP, PORT = "address", 12345

          gdbscript = '''
          tbreak main
          continue
          '''

          def start():
              if args.GDB:
                  return gdb.debug([elf.path], gdbscript)
              elif args.REMOTE:
                  return remote(IP, PORT)
              else:
                  return elf.process()

          p = start()

          # ----- Exploit ----- #

          p.interactive()
        '';
      };

      templateAlias = mkOption {
        type = types.bool;
        default = false;
        description =
          "Creates an alias for 'pwninit --template-path {template}' as 'pwninit'.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    assertions = mkIf cfg.templateAlias [{
      assertion = cfg.template != null;
      message =
        "The 'programs.pwninit.template' option must be set when 'programs.pwninit.templateAlias' is true.";
    }];

    home.shellAliases = mkIf (cfg.templateAlias && cfg.template != null) {
      pwninit = "${cfg.package}/bin/pwninit --template-path ${
          (pkgs.writeText "template.py" cfg.template)
        }";
    };
  };
}
