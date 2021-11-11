{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.terraform;

in {
  meta.maintainers = [ maintainers.bryanhonof ];

  options.programs.terraform = {

    enable = mkEnableOption ''
      Terraform is an open-source infrastructure as code software tool that
      provides a consistent CLI workflow to manage hundreds of cloud services.
      Terraform codifies cloud APIs into declarative configuration files.

      https://www.terraform.io/
    '';

    package = mkOption {
      type = types.package;
      default = pkgs.terraform;
      defaultText = "pkgs.terraform";
      description = "The Terraform package to use";
    };

    installCompletion = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Wether or not to install the autocomplete functionality. Normally this
        is done by running `terraform -install-autocomplete`.
      '';
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.bashrcExtra = ''
      complete -C ${cfg.package}/bin/terraform terraform
    '';
  };
}
