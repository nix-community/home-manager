{
  lib,
  config,
  pkgs,
  ...
}:
let
  mkVesktopLikeModule = import ./mkVesktopLikeModule.nix;
  cfg = config.programs.vesktop;
  fileDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/vesktop"
    else
      "${config.xdg.configHome}/vesktop";
  settingsFiles = [
    {
      name = "settings.json";
      inherit (cfg) settings;
      mutable = cfg.mutableSettings;
    }
    {
      name = "settings/settings.json";
      settings = cfg.vencord.settings;
      mutable = cfg.vencord.mutableSettings;
    }
  ];
  immutableConfigCleanup = lib.concatMapStrings (
    {
      name,
      settings,
      mutable,
    }:
    lib.optionalString (!mutable && settings != { }) (
      lib.hm.generators.mkImpureConfigCleanup {
        file = config.home.file."${fileDir}/${name}";
      }
    )
  ) settingsFiles;
  jsonFormat = pkgs.formats.json { };
  mutableSettingsOption = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Merge declarative settings into a writable JSON file during activation,
      preserving settings changed in the application. Declarative values take
      precedence; arrays are replaced rather than merged. Removing a
      declarative setting does not remove it from the file. Formatting is
      not preserved. Close Vesktop before activating to avoid concurrent writes.

      When disabled, files byte-identical to the generated configuration are
      replaced with managed symlinks. Other files use normal collision handling.
    '';
  };
in
{
  imports = [
    (mkVesktopLikeModule {
      moduleName = "vesktop";
      cordModuleName = "vencord";
      settingsLink = "https://github.com/Vencord/Vesktop/blob/main/src/shared/settings.d.ts";
      cordSettingsLink = "https://github.com/Vendicated/Vencord/blob/main/src/api/Settings.ts";
      installPackage = false;
      maintainers = with lib.maintainers; [
        Flameopathic
        LilleAila
      ];
    })
  ];

  options.programs.vesktop = {
    mutableSettings = mutableSettingsOption;
    vencord.mutableSettings = mutableSettingsOption;
    vencord.useSystem = lib.mkEnableOption "Vencord package from Nixpkgs";
  };

  config = lib.mkIf cfg.enable {
    home = {
      file = lib.mkMerge (
        map (
          {
            name,
            settings,
            mutable,
          }:
          lib.mkIf (mutable && settings != { }) {
            "${fileDir}/${name}".enable = false;
          }
        ) settingsFiles
      );

      activation = {
        vesktopSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] (
          lib.concatMapStrings (
            {
              name,
              settings,
              mutable,
            }:
            lib.optionalString (mutable && settings != { }) (
              lib.hm.generators.mkImpureConfigMerger {
                inherit pkgs;
                format = "json";
                empty = "{}";
                jqOperation = "$dynamic * $static";
                path =
                  let
                    target = config.home.file."${fileDir}/${name}".target;
                  in
                  if lib.hasPrefix "/" target then target else "${config.home.homeDirectory}/${target}";
                staticSettings = jsonFormat.generate "vesktop-${baseNameOf name}" settings;
                mode = "600";
              }
            )
          ) settingsFiles
        );

        vesktopImmutableSettings = lib.mkIf (immutableConfigCleanup != "") (
          lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] immutableConfigCleanup
        );
      };

      packages = lib.mkIf (cfg.package != null) [
        (cfg.package.override { withSystemVencord = cfg.vencord.useSystem; })
      ];
    };

  };
}
