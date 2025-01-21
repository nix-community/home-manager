{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.mu;

  # Used to generate command line arguments that mu can operate with.
  genCmdMaildir = path: "--maildir=" + path;

  # Sorted list of personal email addresses to register
  sortedAddresses = let
    # Set of email account sets where mu.enable = true.
    muAccounts =
      filter (a: a.mu.enable) (attrValues config.accounts.email.accounts);
    addrs = map (a: a.address) muAccounts;
    # Construct list of lists containing email aliases, and flatten
    aliases = flatten (map (a: a.aliases) muAccounts);
    # Sort the list
  in sort lessThan (addrs ++ aliases);

  # Takes the list of accounts with mu.enable = true, and generates a
  # command-line flag for initializing the mu database.
  myAddresses = let
    # Prefix --my-address= to each account's address and all defined aliases
    addMyAddress = map (addr: "--my-address=" + addr) sortedAddresses;
  in concatStringsSep " " addMyAddress;

in {
  meta.maintainers = [ maintainers.KarlJoad ];

  options = {
    programs.mu = {
      enable = mkEnableOption "mu, a maildir indexer and searcher";

      package = mkPackageOption pkgs "mu" { };

      home = mkOption {
        type = types.path;
        default = config.xdg.cacheHome + "/mu";
        defaultText = literalExpression ''config.xdg.cacheHome + "/mu"'';
        example = "\${config.home.homeDirectory}/Maildir/.mu";
        description = ''
          Directory to store Mu's database.
        '';
      };

      # No options/config file present for mu, and program author will not be
      # adding one soon. See https://github.com/djcb/mu/issues/882 for more
      # information about this.
    };

    accounts.email.accounts = mkOption {
      type = with types;
        attrsOf
        (submodule { options.mu.enable = mkEnableOption "mu indexing"; });
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.sessionVariables.MUHOME = cfg.home;

    home.activation.runMuInit = let
      maildirOption = genCmdMaildir config.accounts.email.maildirBasePath;
      muExe = getExe cfg.package;
      gawkExe = getExe pkgs.gawk;
    in hm.dag.entryAfter [ "writeBoundary" ] ''
      # If the database directory exists and registered personal addresses remain the same,
      # then `mu init` should NOT be run.
      # In theory, mu is the only thing that creates that directory, and it is
      # only created during the initial index.
      MU_SORTED_ADDRS=$((${muExe} info store | ${gawkExe} '/personal-address/{print $4}' | LC_ALL=C sort | paste -sd ' ') || exit 0)
      if [[ ! -d "${cfg.home}" || ! "$MU_SORTED_ADDRS" = "${
        concatStringsSep " " sortedAddresses
      }" ]]; then
        run ${muExe} init ${maildirOption} --muhome "${
          escapeShellArg cfg.home
        }" ${myAddresses} $VERBOSE_ARG;
      fi
    '';
  };
}
