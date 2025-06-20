{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.mu;

  # Used to generate command line arguments that mu can operate with.
  genCmdMaildir = path: "--maildir=" + path;

  # Sorted list of personal email addresses to register
  sortedAddresses =
    let
      # Set of email account sets where mu.enable = true.
      muAccounts = lib.filter (a: a.mu.enable) (lib.attrValues config.accounts.email.accounts);
      addrs = map (a: a.address) muAccounts;
      # Construct list of lists containing email aliases, and flatten
      aliases = map (alias: alias.address or alias) (lib.flatten (map (a: a.aliases) muAccounts));
      # Sort the list
    in
    lib.sort lib.lessThan (addrs ++ aliases);

  # Takes the list of accounts with mu.enable = true, and generates a
  # command-line flag for initializing the mu database.
  myAddresses =
    let
      # Prefix --my-address= to each account's address and all defined aliases
      addMyAddress = map (addr: "--my-address=" + addr) sortedAddresses;
    in
    lib.concatStringsSep " " addMyAddress;

in
{
  meta.maintainers = [ lib.maintainers.KarlJoad ];

  options = {
    programs.mu = {
      enable = lib.mkEnableOption "mu, a maildir indexer and searcher";

      package = lib.mkPackageOption pkgs "mu" { };

      home = lib.mkOption {
        type = lib.types.path;
        default = config.xdg.cacheHome + "/mu";
        defaultText = lib.literalExpression ''config.xdg.cacheHome + "/mu"'';
        example = "\${config.home.homeDirectory}/Maildir/.mu";
        description = ''
          Directory to store Mu's database.
        '';
      };

      # No options/config file present for mu, and program author will not be
      # adding one soon. See https://github.com/djcb/mu/issues/882 for more
      # information about this.
    };

    accounts.email.accounts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.mu.enable = lib.mkEnableOption "mu indexing";
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.sessionVariables.MUHOME = cfg.home;

    home.activation.runMuInit =
      let
        maildirOption = genCmdMaildir config.accounts.email.maildirBasePath;
        muExe = lib.getExe cfg.package;
        gawkExe = lib.getExe pkgs.gawk;
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # If the database directory exists and registered personal addresses remain the same,
        # then `mu init` should NOT be run.
        # In theory, mu is the only thing that creates that directory, and it is
        # only created during the initial index.
        MU_SORTED_ADDRS=$((${muExe} info store | ${gawkExe} '/personal-address/{print $4}' | LC_ALL=C sort | paste -sd ' ') || exit 0)
        if [[ ! -d "${cfg.home}" || ! "$MU_SORTED_ADDRS" = "${lib.concatStringsSep " " sortedAddresses}" ]]; then
          run ${muExe} init ${maildirOption} --muhome "${lib.escapeShellArg cfg.home}" ${myAddresses} $VERBOSE_ARG;
        fi
      '';
  };
}
