{ lib }:

{
  bashOwnedNames,
  genericNames,
  hasProfileExtra,
  sessionVariablesPackage,
}:

let
  statefulBashVersions = "4.[2-9]* | [5-9].* | [1-9][0-9].*";
  genericNamesString = lib.escapeShellArgs genericNames;
  knownGenericManifest = lib.concatMapStrings (name: " ${name}") genericNames;
  bashOwnedManifest = lib.concatMapStrings (name: " ${name}") bashOwnedNames;
  needsManifest = bashOwnedNames != [ ] || hasProfileExtra;
  addBashOwnedNames = lib.concatMapStringsSep "\n" (name: ''
    case " $__HM_BASH_SESSION_VARS_MANIFEST " in
      *" ${name} "*) ;;
      *) __HM_BASH_SESSION_VARS_MANIFEST+=" ${name}" ;;
    esac
  '') bashOwnedNames;
  prepareManifest = ''
    if [[ -z ''${__HM_BASH_SESSION_VARS_MANIFEST+x} || -z ''${__HM_BASH_SESSION_VARS_KNOWN+x} ]]; then
      __HM_BASH_SESSION_VARS_PREVIOUS_KNOWN=""
    else
      __HM_BASH_SESSION_VARS_PREVIOUS_KNOWN="$__HM_BASH_SESSION_VARS_KNOWN"
    fi
    if [[ -z ''${__HM_BASH_SESSION_VARS_MANIFEST+x} ]]; then
      __HM_BASH_SESSION_VARS_MANIFEST=""
    fi
    for __hm_bash_session_var in ${genericNamesString}; do
      case " $__HM_BASH_SESSION_VARS_PREVIOUS_KNOWN " in
        *" $__hm_bash_session_var "*) ;;
        *)
          if declare -p "$__hm_bash_session_var" &>/dev/null; then
            case " $__HM_BASH_SESSION_VARS_MANIFEST " in
              *" $__hm_bash_session_var "*) ;;
              *) __HM_BASH_SESSION_VARS_MANIFEST+=" $__hm_bash_session_var" ;;
            esac
          fi
          ;;
      esac
    done
    ${addBashOwnedNames}
    __HM_BASH_SESSION_VARS_KNOWN=${lib.escapeShellArg knownGenericManifest}
    export __HM_BASH_SESSION_VARS_MANIFEST __HM_BASH_SESSION_VARS_KNOWN
    unset __HM_BASH_SESSION_VARS_PREVIOUS_KNOWN __hm_bash_session_var
  '';
in
{
  beforeProfileExtra = lib.optionalString hasProfileExtra ''
    case "''${BASH_VERSION-}" in
      ${statefulBashVersions})
        unset __HM_BASH_SESSION_VARS_STATE
        declare -Ag __HM_BASH_SESSION_VARS_STATE
        for __hm_bash_session_var in ${genericNamesString}; do
          if [[ -v $__hm_bash_session_var ]]; then
            __HM_BASH_SESSION_VARS_STATE["set:$__hm_bash_session_var"]=1
            __HM_BASH_SESSION_VARS_STATE["value:$__hm_bash_session_var"]="''${!__hm_bash_session_var}"
          fi
        done
        ;;
    esac
  '';

  afterProfileExtra = lib.optionalString needsManifest ''
    if [ -n "''${BASH_VERSION-}" ]; then
      __HM_BASH_SESSION_VARS_MANIFEST=${lib.escapeShellArg bashOwnedManifest}
      ${lib.optionalString hasProfileExtra ''
        case "$BASH_VERSION" in
          ${statefulBashVersions})
            for __hm_bash_session_var in ${genericNamesString}; do
              if [[ -v $__hm_bash_session_var ]]; then
                if [[ ! ''${__HM_BASH_SESSION_VARS_STATE["set:$__hm_bash_session_var"]+x} || "''${!__hm_bash_session_var}" != "''${__HM_BASH_SESSION_VARS_STATE["value:$__hm_bash_session_var"]}" ]]; then
                  case " $__HM_BASH_SESSION_VARS_MANIFEST " in
                    *" $__hm_bash_session_var "*) ;;
                    *) __HM_BASH_SESSION_VARS_MANIFEST+=" $__hm_bash_session_var" ;;
                  esac
                fi
              elif [[ ''${__HM_BASH_SESSION_VARS_STATE["set:$__hm_bash_session_var"]+x} ]]; then
                __HM_BASH_SESSION_VARS_MANIFEST+=" $__hm_bash_session_var"
              fi
            done
            unset __HM_BASH_SESSION_VARS_STATE __hm_bash_session_var
            ;;
        esac
      ''}
      __HM_BASH_SESSION_VARS_KNOWN=${lib.escapeShellArg knownGenericManifest}
      export __HM_BASH_SESSION_VARS_MANIFEST __HM_BASH_SESSION_VARS_KNOWN
    fi
  '';

  refresh =
    if !needsManifest then
      ''. "${sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"''
    else if hasProfileExtra then
      ''
        case "''${BASH_VERSION-}" in
          ${statefulBashVersions})
            ${prepareManifest}
            __HM_SESS_VARS_SKIP="$__HM_BASH_SESSION_VARS_MANIFEST"
            . "${sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"
            unset __HM_SESS_VARS_SKIP
            ;;
        esac
      ''
    else
      ''
        ${prepareManifest}
        __HM_SESS_VARS_SKIP="$__HM_BASH_SESSION_VARS_MANIFEST"
        . "${sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"
        unset __HM_SESS_VARS_SKIP
      '';
}
