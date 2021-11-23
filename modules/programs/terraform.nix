{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.terraform;

in {
  meta.maintainers = [ hm.maintainers.bryanhonof ];

  options.programs.terraform = {

    enable = mkEnableOption ''
      <link xlink:href="https://www.terraform.io">Terraform</link>, an open-source infrastructure as code software tool that
      provides a consistent CLI workflow to manage hundreds of cloud services.
      </para>
      Terraform codifies cloud APIs into declarative configuration files.
    '';

    package = mkOption {
      type = types.package;
      default = pkgs.terraform;
      defaultText = "pkgs.terraform";
      description = "The Terraform package to use";
    };

    providers = mkOption {
      type = hm.types.selectorFunction;
      default = providers: [ ];
      defaultText = literalExpression "providers: [ ]";
      example = literalExpression ''
        providers: [ providers.consul providers.dyn ];
      '';
      description = ''
        A list of Terraform providers.
        </para>
        <para>
        A list of available providers can be obtained with either of the following commands:
        <orderedlist numeration="arabic">
          <listitem>
            <para><command>nix-env -f '&lt;nixpkgs&gt;' -qaP -A terraform-providers</command></para>
          </listitem>
          <listitem>
            <para><command>nix search 'nixpkgs#terraform-providers'</command></para>
          </listitem>
        </orderedlist>
      '';
    };

    enableBashIntegration = mkEnableOption "Bash integration" // {
      default = true;
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ (cfg.package.withPlugins (_: cfg.providers)) ];

    programs.bash.initExtra = mkIf cfg.installCompletion ''
      complete -C ${cfg.package}/bin/terraform terraform
    '';
  };
}
