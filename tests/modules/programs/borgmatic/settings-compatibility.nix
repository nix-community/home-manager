{
  config,
  lib,
  realPkgs,
  ...
}:
let
  base = {
    source_directories = [ "/source" ];
    repositories = [ { path = "/repo"; } ];
    checks = [ ];
  };
  cases = {
    basic = {
      repoDefinitions = 2;
      backup = {
        location.repositories = [
          "/repo"
          {
            path = "/labeled";
            label = "remote";
          }
        ];
        storage.encryptionPasscommand = "pass borg";
        retention = {
          keepWithin = "2d";
          keepSecondly = 2;
          keepMinutely = 3;
          keepHourly = 4;
          keepDaily = 5;
          keepWeekly = 6;
          keepMonthly = 7;
          keepYearly = 8;
        };
      };
      expected = {
        repositories = [
          { path = "/repo"; }
          {
            path = "/labeled";
            label = "remote";
          }
          { path = "/repo"; }
        ];
        encryption_passcommand = "pass borg";
        keep_within = "2d";
        keep_secondly = 2;
        keep_minutely = 3;
        keep_hourly = 4;
        keep_daily = 5;
        keep_weekly = 6;
        keep_monthly = 7;
        keep_yearly = 8;
      };
      warnings = [
        {
          from = "retention.keepYearly";
          to = "settings.keep_yearly";
        }
        {
          from = "retention.keepMonthly";
          to = "settings.keep_monthly";
        }
        {
          from = "retention.keepWeekly";
          to = "settings.keep_weekly";
        }
        {
          from = "retention.keepDaily";
          to = "settings.keep_daily";
        }
        {
          from = "retention.keepHourly";
          to = "settings.keep_hourly";
        }
        {
          from = "retention.keepMinutely";
          to = "settings.keep_minutely";
        }
        {
          from = "retention.keepSecondly";
          to = "settings.keep_secondly";
        }
        {
          from = "retention.keepWithin";
          to = "settings.keep_within";
        }
        {
          from = "storage.encryptionPasscommand";
          to = "settings.encryption_passcommand";
        }
      ];
    };
    derivation =
      let
        script = realPkgs.writeShellScript "borgmatic-ssh" ''exec ssh "$@"'';
      in
      {
        backup.storage.extraConfig.ssh_command = script;
        expected.ssh_command = toString script;
        warnings = [ { from = "storage.extraConfig"; } ];
      };
    checks = {
      checkDefinitions = 2;
      backup.consistency.checks = [
        {
          name = "repository";
          frequency = "always";
        }
        { name = "data"; }
      ];
      expected.checks = [
        {
          name = "repository";
          frequency = "always";
        }
        { name = "data"; }
      ];
    };
    sections = {
      backup = {
        location.extraConfig.one_file_system = true;
        storage.extraConfig.checkpoint_interval = 200;
        retention.extraConfig.prefix = "hostname";
        consistency.extraConfig.archive_name_format = "archive";
        output.extraConfig.color = false;
        hooks.extraConfig.before_actions = [ "echo start" ];
      };
      expected = {
        one_file_system = true;
        checkpoint_interval = 200;
        prefix = "hostname";
        archive_name_format = "archive";
        color = false;
        before_actions = [ "echo start" ];
      };
      warnings = map (section: { from = "${section}.extraConfig"; }) [
        "hooks"
        "output"
        "consistency"
        "retention"
        "storage"
        "location"
      ];
    };
    overlayTyped = {
      backup = {
        retention.keepDaily = lib.mkForce 30;
        location.extraConfig.keep_daily = lib.mkDefault 2;
      };
      expected.keep_daily = 2;
      warnings = [
        { from = "location.extraConfig"; }
        {
          from = "retention.keepDaily";
          to = "settings.keep_daily";
        }
      ];
    };
    nativePriority = {
      backup = {
        retention.keepDaily = 30;
        settings.keep_daily = 7;
      };
      expected.keep_daily = 7;
      warnings = [
        {
          from = "retention.keepDaily";
          to = "settings.keep_daily";
        }
      ];
    };
    overlayCollision = {
      backup = {
        settings.exclude_patterns = [ "- /native" ];
        location.extraConfig.exclude_patterns = [ "- /legacy" ];
      };
      expected.exclude_patterns = [
        "- /native"
        "- /legacy"
      ];
      warnings = [ { from = "location.extraConfig"; } ];
    };
    legacyOrder = {
      checkDefinitions = 3;
      backup.consistency.checks = lib.mkMerge [
        (lib.mkAfter [
          {
            name = "data";
            frequency = "always";
          }
        ])
        (lib.mkBefore [ { name = "repository"; } ])
      ];
      expected.checks = [
        { name = "repository"; }
        {
          name = "data";
          frequency = "always";
        }
      ];
    };
  };
  expected = case: base // case.expected;
  warningEntries =
    case:
    let
      entries = lib.partition (entry: lib.hasSuffix ".extraConfig" entry.from) (case.warnings or [ ]);
    in
    entries.right
    ++ [
      {
        from = "consistency.checks";
        to = "settings.checks";
        changed = true;
        definitions = case.checkDefinitions or 1;
      }
      {
        from = "location.repositories";
        to = "settings.repositories";
        changed = true;
        definitions = case.repoDefinitions or 1;
      }
    ]
    ++ entries.wrong
    ++ [
      {
        from = "location.sourceDirectories";
        to = "settings.source_directories";
      }
    ];
in
{
  programs.borgmatic = {
    enable = true;
    package = null;
    backups = lib.mapAttrs (
      _: case:
      lib.mkMerge [
        {
          location = {
            sourceDirectories = [ "/source" ];
            repositories = [ "/repo" ];
          };
          consistency.checks = [ ];
        }
        case.backup
      ]
    ) cases;
  };

  test.asserts.warnings.expected = lib.concatLists (
    lib.mapAttrsToList (
      name: case:
      (import ./warnings.nix { inherit lib; }) {
        file = ./settings-compatibility.nix;
        backup = name;
        entries = warningEntries case;
      }
    ) cases
  );

  assertions = lib.mapAttrsToList (name: case: {
    assertion =
      builtins.toJSON config.programs.borgmatic.backups.${name}.settings
      == builtins.toJSON (expected case);
    message = "Unexpected canonical settings for borgmatic ${name}";
  }) cases;

  nmt.script = lib.concatStrings (
    lib.mapAttrsToList (name: case: ''
      file=$TESTED/home-files/.config/borgmatic.d/${name}.yaml
      assertFileExists "$file"
      ${realPkgs.jq}/bin/jq --exit-status \
        --argjson expected ${lib.escapeShellArg (builtins.toJSON (expected case))} \
        '. == $expected' "$file"
    '') cases
  );
}
