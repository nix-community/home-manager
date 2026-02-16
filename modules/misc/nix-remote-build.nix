{ config, lib, ... }:

let
  inherit (lib)
    concatStringsSep
    mkIf
    mkOption
    optionalString
    types
    ;

  cfg = config.nix;
in
{
  meta.maintainers = [ lib.maintainers.GaetanLepage ];

  options = {
    nix = {
      buildMachines = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              hostName = mkOption {
                type = types.str;
                example = "nixbuilder.example.org";
                description = ''
                  The hostname of the build machine.
                '';
              };
              protocol = mkOption {
                type = types.enum [
                  null
                  "ssh"
                  "ssh-ng"
                ];
                default = "ssh";
                example = "ssh-ng";
                description = ''
                  The protocol used for communicating with the build machine.
                  Use `ssh-ng` if your remote builder and your
                  local Nix version support that improved protocol.

                  Use `null` when trying to change the special localhost builder
                  without a protocol which is for example used by hydra.
                '';
              };
              systems = mkOption {
                type = types.listOf types.str;
                default = [ ];
                example = [
                  "x86_64-linux"
                  "aarch64-linux"
                ];
                description = ''
                  The system types the build machine can execute derivations on.
                '';
              };
              sshUser = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "builder";
                description = ''
                  The username to log in as on the remote host. This user must be
                  able to log in and run nix commands non-interactively. It must
                  also be privileged to build derivations, so must be included in
                  {option}`nix.settings.trusted-users`.
                '';
              };
              sshKey = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "/root/.ssh/id_buildhost_builduser";
                description = ''
                  The path to the SSH private key with which to authenticate on
                  the build machine. The private key must not have a passphrase.
                  If null, the building user (root on NixOS machines) must have an
                  appropriate ssh configuration to log in non-interactively.

                  Note that for security reasons, this path must point to a file
                  in the local filesystem, *not* to the nix store.
                '';
              };
              maxJobs = mkOption {
                type = types.int;
                default = 1;
                description = ''
                  The number of concurrent jobs the build machine supports. The
                  build machine will enforce its own limits, but this allows hydra
                  to schedule better since there is no work-stealing between build
                  machines.
                '';
              };
              speedFactor = mkOption {
                type = types.int;
                default = 1;
                description = ''
                  The relative speed of this builder. This is an arbitrary integer
                  that indicates the speed of this builder, relative to other
                  builders. Higher is faster.
                '';
              };
              mandatoryFeatures = mkOption {
                type = types.listOf types.str;
                default = [ ];
                example = [ "big-parallel" ];
                description = ''
                  A list of features mandatory for this builder. The builder will
                  be ignored for derivations that don't require all features in
                  this list. All mandatory features are automatically included in
                  {var}`supportedFeatures`.
                '';
              };
              supportedFeatures = mkOption {
                type = types.listOf types.str;
                default = [ ];
                example = [
                  "kvm"
                  "big-parallel"
                ];
                description = ''
                  A list of features supported by this builder. The builder will
                  be ignored for derivations that require features not in this
                  list.
                '';
              };
              publicHostKey = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  The (base64-encoded) public host key of this builder. The field
                  is calculated via {command}`base64 -w0 /etc/ssh/ssh_host_type_key.pub`.
                  If null, SSH will use its regular known-hosts file when connecting.
                '';
              };
            };
          }
        );
        default = [ ];
        description = ''
          This option lists the machines to be used if distributed builds are
          enabled (see {option}`nix.distributedBuilds`).
          Nix will perform derivations on those machines via SSH by copying the
          inputs to the Nix store on the remote machine, starting the build,
          then copying the output back to the local Nix store.
        '';
      };

      distributedBuilds = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to distribute builds to the machines listed in
          {option}`nix.buildMachines`.
        '';
      };
    };
  };

  # distributedBuilds does *not* inhibit $XDG_CONFIG_HOME/nix/machines generation; caller may
  # override that nix option.
  config = mkIf cfg.enable (
    let
      machineFilePath = "nix/machines";

      isNixAtLeast = lib.versionAtLeast (lib.getVersion cfg.package);
    in
    {
      # List of machines for distributed Nix builds
      xdg.configFile.${machineFilePath} = mkIf (cfg.buildMachines != [ ]) {
        text = lib.concatMapStrings (
          machine:
          (concatStringsSep " " (
            [
              "${optionalString (machine.protocol != null) "${machine.protocol}://"}${
                optionalString (machine.sshUser != null) "${machine.sshUser}@"
              }${machine.hostName}"
              (concatStringsSep "," machine.systems)
              (if machine.sshKey != null then machine.sshKey else "-")
              (toString machine.maxJobs)
              (toString machine.speedFactor)
              (
                let
                  res = (machine.supportedFeatures ++ machine.mandatoryFeatures);
                in
                if (res == [ ]) then "-" else (concatStringsSep "," res)
              )
              (
                let
                  res = machine.mandatoryFeatures;
                in
                if (res == [ ]) then "-" else (concatStringsSep "," machine.mandatoryFeatures)
              )
            ]
            ++ lib.optional (isNixAtLeast "2.4pre") (
              if machine.publicHostKey != null then machine.publicHostKey else "-"
            )
          ))
          + "\n"
        ) cfg.buildMachines;
      };

      nix.settings = mkIf cfg.distributedBuilds {
        builders = "@${config.xdg.configHome}/${machineFilePath}";
      };
    }
  );
}
