{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types;

  cfg = config.services.signaturepdf;
  extraConfigToArgs =
    extraConfig:
    lib.flatten (
      lib.mapAttrsToList (name: value: [
        "-d"
        "${name}=${value}"
      ]) extraConfig
    );
in
{
  meta.maintainers = [ lib.maintainers.DamienCassou ];

  options.services.signaturepdf = {
    enable = lib.mkEnableOption "signaturepdf; signing, organizing, editing metadatas or compressing PDFs";

    package = lib.mkPackageOption pkgs "signaturepdf" { };

    port = mkOption {
      type = types.port;
      default = 8080;
      example = 8081;
      description = "The port on which the application runs";
    };

    extraConfig = mkOption {
      default = { };
      type =
        with types;
        let
          primitive = oneOf [
            str
            int
            bool
            float
          ];
        in
        attrsOf primitive;
      example = {
        upload_max_filesize = "24M";
        post_max_size = "24M";
        max_file_uploads = "201";
      };
      description = "Additional configuration optional.";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.desktopEntries = {
      signaturepdf = {
        name = "SignaturePDF";
        exec = "${pkgs.xdg-utils}/bin/xdg-open http://localhost:${toString cfg.port}";
        terminal = false;
        icon = "${cfg.package}/share/signaturepdf/public/favicon.ico";
      };
    };

    systemd.user.services.signaturepdf = {
      Unit = {
        Description = "signaturepdf; signing, organizing, editing metadatas or compressing PDFs";
      };

      Service = {
        ExecStart = "${cfg.package}/bin/signaturepdf ${toString cfg.port} ${lib.escapeShellArgs (extraConfigToArgs cfg.extraConfig)}";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
