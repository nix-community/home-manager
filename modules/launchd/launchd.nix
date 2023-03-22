# launchd option type from nix-darwin
#
# Original Source:
# https://github.com/LnL7/nix-darwin/blob/a34dea2/modules/launchd/launchd.nix

# Copyright 2017 Daiderd Jordan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

{ config, lib, ... }:

with lib;

{
  freeformType = with types; attrsOf anything; # added by Home Manager

  options = {
    Label = mkOption {
      type = types.str;
      description = "This required key uniquely identifies the job to launchd.";
    };

    Disabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        This optional key is used as a hint to <literal>launchctl(1)</literal> that it should not submit this job to launchd when
        loading a job or jobs. The value of this key does NOT reflect the current state of the job on the running
        system. If you wish to know whether a job is loaded in launchd, reading this key from a configuration
        file yourself is not a sufficient test. You should query launchd for the presence of the job using
        the <literal>launchctl(1)</literal> list subcommand or use the ServiceManagement framework's
        <literal>SMJobCopyDictionary()</literal> method.

        Note that as of Mac OS X v10.6, this key's value in a configuration file conveys a default value, which
        is changed with the [-w] option of the <literal>launchctl(1)</literal> load and unload subcommands. These subcommands no
        longer modify the configuration file, so the value displayed in the configuration file is not necessarily
        the value that <literal>launchctl(1)</literal> will apply. See <literal>launchctl(1)</literal> for more information.

        Please also be mindful that you should only use this key if the provided on-demand and KeepAlive criteria
        are insufficient to describe the conditions under which your job needs to run. The cost to have a
        job loaded in launchd is negligible, so there is no harm in loading a job which only runs once or very
        rarely.
      '';
    };

    UserName = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        This optional key specifies the user to run the job as. This key is only applicable when launchd is
        running as root.
      '';
    };

    GroupName = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        This optional key specifies the group to run the job as. This key is only applicable when launchd is
        running as root. If UserName is set and GroupName is not, the the group will be set to the default
        group of the user.
      '';
    };

    inetdCompatibility = mkOption {
      default = null;
      example = { Wait = true; };
      description = ''
        The presence of this key specifies that the daemon expects to be run as if it were launched from inetd.
      '';
      type = types.nullOr (types.submodule {
        options = {
          Wait = mkOption {
            type = types.nullOr (types.either types.bool types.str);
            default = null;
            description = ''
              This flag corresponds to the "wait" or "nowait" option of inetd. If true, then the listening
              socket is passed via the standard in/out/error file descriptors. If false, then <literal>accept(2)</literal> is
              called on behalf of the job, and the result is passed via the standard in/out/error descriptors.
            '';
          };
        };
      });
    };

    LimitLoadToHosts = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = ''
        This configuration file only applies to the hosts listed with this key. Note: One should set kern.host-name kern.hostname
        name in <literal>sysctl.conf(5)</literal> for this feature to work reliably.
      '';
    };

    LimitLoadFromHosts = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = ''
        This configuration file only applies to hosts NOT listed with this key. Note: One should set kern.host-name kern.hostname
        name in <literal>sysctl.conf(5)</literal> for this feature to work reliably.
      '';
    };

    LimitLoadToSessionType = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        This configuration file only applies to sessions of the type specified. This key is used in concert
        with the -S flag to <command>launchctl</command>.
      '';
    };

    Program = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        This key maps to the first argument of <literal>execvp(3)</literal>.  If this key is missing, then the first element of
        the array of strings provided to the ProgramArguments will be used instead.  This key is required in
        the absence of the ProgramArguments key.
      '';
    };

    ProgramArguments = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = ''
        This key maps to the second argument of <literal>execvp(3)</literal>.  This key is required in the absence of the Program
        key. Please note: many people are confused by this key. Please read <literal>execvp(3)</literal> very carefully!
      '';
    };

    EnableGlobbing = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        This flag causes launchd to use the <literal>glob(3)</literal> mechanism to update the program arguments before invocation.
      '';
    };

    EnableTransactions = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        This flag instructs launchd that the job promises to use <literal>vproc_transaction_begin(3)</literal> and
        <literal>vproc_transaction_end(3)</literal> to track outstanding transactions that need to be reconciled before the
        process can safely terminate. If no outstanding transactions are in progress, then launchd is free to
        send the SIGKILL signal.
      '';
    };

    OnDemand = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        This key was used in Mac OS X 10.4 to control whether a job was kept alive or not. The default was
        true.  This key has been deprecated and replaced in Mac OS X 10.5 and later with the more powerful
        KeepAlive option.
      '';
    };

    KeepAlive = mkOption {
      type = types.nullOr (types.either types.bool (types.submodule {
        options = {

          SuccessfulExit = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = ''
              If true, the job will be restarted as long as the program exits and with an exit status of zero.
              If false, the job will be restarted in the inverse condition.  This key implies that "RunAtLoad"
              is set to true, since the job needs to run at least once before we can get an exit status.
            '';
          };

          NetworkState = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = ''
              If true, the job will be kept alive as long as the network is up, where up is defined as at least
              one non-loopback interface being up and having IPv4 or IPv6 addresses assigned to them.  If
              false, the job will be kept alive in the inverse condition.
            '';
          };

          PathState = mkOption {
            type = types.nullOr (types.attrsOf types.bool);
            default = null;
            description = ''
              Each key in this dictionary is a file-system path. If the value of the key is true, then the job
              will be kept alive as long as the path exists.  If false, the job will be kept alive in the
              inverse condition. The intent of this feature is that two or more jobs may create semaphores in
              the file-system namespace.
            '';
          };

          OtherJobEnabled = mkOption {
            type = types.nullOr (types.attrsOf types.bool);
            default = null;
            description = ''
              Each key in this dictionary is the label of another job. If the value of the key is true, then
              this job is kept alive as long as that other job is enabled. Otherwise, if the value is false,
              then this job is kept alive as long as the other job is disabled.  This feature should not be
              considered a substitute for the use of IPC.
            '';
          };

          # NOTE: this was missing in the original source at the time of writing
          Crashed = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = ''
              If true, the the job will be restarted as long as it exited due to a signal which is typically
              associated with a crash (SIGILL, SIGSEGV, etc.). If false, the job will be restarted in the inverse
              condition.
            '';
          };

        };
      }));
      default = null;
      description = ''
        This optional key is used to control whether your job is to be kept continuously running or to let
        demand and conditions control the invocation. The default is false and therefore only demand will start
        the job. The value may be set to true to unconditionally keep the job alive. Alternatively, a dictionary
        of conditions may be specified to selectively control whether launchd keeps a job alive or not. If
        multiple keys are provided, launchd ORs them, thus providing maximum flexibility to the job to refine
        the logic and stall if necessary. If launchd finds no reason to restart the job, it falls back on
        demand based invocation.  Jobs that exit quickly and frequently when configured to be kept alive will
        be throttled to conserve system resources.
      '';
    };

    RunAtLoad = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        This optional key is used to control whether your job is launched once at the time the job is loaded.
        The default is false.
      '';
    };

    RootDirectory = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        This optional key is used to specify a directory to <literal>chroot(2)</literal> to before running the job.
      '';
    };

    WorkingDirectory = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        This optional key is used to specify a directory to <literal>chdir(2)</literal> to before running the job.
      '';
    };

    EnvironmentVariables = mkOption {
      type = types.nullOr (types.attrsOf types.str);
      default = null;
      description = ''
        This optional key is used to specify additional environment variables to be set before running the
        job.
      '';
    };

    Umask = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        This optional key specifies what value should be passed to <literal>umask(2)</literal> before running the job. Known bug:
        Property lists don't support octal, so please convert the value to decimal.
      '';
    };

    TimeOut = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        The recommended idle time out (in seconds) to pass to the job. If no value is specified, a default time
        out will be supplied by launchd for use by the job at check in time.
      '';
    };

    ExitTimeOut = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        The amount of time launchd waits before sending a SIGKILL signal. The default value is 20 seconds. The
        value zero is interpreted as infinity.
      '';
    };

    ThrottleInterval = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        This key lets one override the default throttling policy imposed on jobs by launchd.  The value is in
        seconds, and by default, jobs will not be spawned more than once every 10 seconds.  The principle
        behind this is that jobs should linger around just in case they are needed again in the near future.
        This not only reduces the latency of responses, but it encourages developers to amortize the cost of
        program invocation.
      '';
    };

    InitGroups = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        This optional key specifies whether <literal>initgroups(3)</literal> should be called before running the job.  The default
        is true in 10.5 and false in 10.4. This key will be ignored if the UserName key is not set.
      '';
    };

    WatchPaths = mkOption {
      type = types.nullOr (types.listOf types.path);
      default = null;
      description = ''
        This optional key causes the job to be started if any one of the listed paths are modified.
      '';
    };

    QueueDirectories = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = ''
        Much like the WatchPaths option, this key will watch the paths for modifications. The difference being
        that the job will only be started if the path is a directory and the directory is not empty.
      '';
    };

    StartOnMount = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        This optional key causes the job to be started every time a filesystem is mounted.
      '';
    };

    StartInterval = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        This optional key causes the job to be started every N seconds.  If the system is asleep, the job will
        be started the next time the computer wakes up.  If multiple intervals transpire before the computer is
        woken, those events will be coalesced into one event upon wake from sleep.
      '';
    };

    StartCalendarInterval = mkOption {
      default = null;
      example = {
        Hour = 2;
        Minute = 30;
      };
      description = ''
        This optional key causes the job to be started every calendar interval as specified. Missing arguments
        are considered to be wildcard. The semantics are much like <literal>crontab(5)</literal>.  Unlike cron which skips job
        invocations when the computer is asleep, launchd will start the job the next time the computer wakes
        up.  If multiple intervals transpire before the computer is woken, those events will be coalesced into
        one event upon wake from sleep.
      '';
      type = types.nullOr (types.listOf (types.submodule {
        options = {
          Minute = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The minute on which this job will be run.
            '';
          };

          Hour = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The hour on which this job will be run.
            '';
          };

          Day = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The day on which this job will be run.
            '';
          };

          Weekday = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The weekday on which this job will be run (0 and 7 are Sunday).
            '';
          };

          Month = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The month on which this job will be run.
            '';
          };
        };
      }));
    };

    StandardInPath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        This optional key specifies what file should be used for data being supplied to stdin when using
        <literal>stdio(3)</literal>.
      '';
    };

    StandardOutPath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        This optional key specifies what file should be used for data being sent to stdout when using <literal>stdio(3)</literal>.
      '';
    };

    StandardErrorPath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        This optional key specifies what file should be used for data being sent to stderr when using <literal>stdio(3)</literal>.
      '';
    };

    Debug = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        This optional key specifies that launchd should adjust its log mask temporarily to LOG_DEBUG while
        dealing with this job.
      '';
    };

    WaitForDebugger = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        This optional key specifies that launchd should instruct the kernel to have the job wait for a debugger
        to attach before any code in the job is executed.
      '';
    };

    SoftResourceLimits = mkOption {
      default = null;
      description = ''
        Resource limits to be imposed on the job. These adjust variables set with <literal>setrlimit(2)</literal>.  The following
        keys apply:
      '';
      type = types.nullOr (types.submodule {
        options = {
          Core = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The largest size (in bytes) core file that may be created.
            '';
          };

          CPU = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The maximum amount of cpu time (in seconds) to be used by each process.
            '';
          };

          Data = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The maximum size (in bytes) of the data segment for a process; this defines how far a program may
              extend its break with the <literal>sbrk(2)</literal> system call.
            '';
          };

          FileSize = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The largest size (in bytes) file that may be created.
            '';
          };

          MemoryLock = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The maximum size (in bytes) which a process may lock into memory using the mlock(2) function.
            '';
          };

          NumberOfFiles = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The maximum number of open files for this process.  Setting this value in a system wide daemon
              will set the <literal>sysctl(3)</literal> kern.maxfiles (SoftResourceLimits) or kern.maxfilesperproc (HardResource-Limits) (HardResourceLimits)
              Limits) value in addition to the <literal>setrlimit(2)</literal> values.
            '';
          };

          NumberOfProcesses = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The maximum number of simultaneous processes for this user id.  Setting this value in a system
              wide daemon will set the <literal>sysctl(3)</literal> kern.maxproc (SoftResourceLimits) or kern.maxprocperuid
              (HardResourceLimits) value in addition to the <literal>setrlimit(2)</literal> values.
            '';
          };

          ResidentSetSize = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The maximum size (in bytes) to which a process's resident set size may grow.  This imposes a
              limit on the amount of physical memory to be given to a process; if memory is tight, the system
              will prefer to take memory from processes that are exceeding their declared resident set size.
            '';
          };

          Stack = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The maximum size (in bytes) of the stack segment for a process; this defines how far a program's
              stack segment may be extended.  Stack extension is performed automatically by the system.
            '';
          };
        };
      });
    };

    HardResourceLimits = mkOption {
      default = null;
      example = { NumberOfFiles = 4096; };
      description = ''
        Resource limits to be imposed on the job. These adjust variables set with <literal>setrlimit(2)</literal>.  The following
        keys apply:
      '';
      type = types.nullOr (types.submodule {
        options = {
          Core = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The largest size (in bytes) core file that may be created.
            '';
          };

          CPU = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The maximum amount of cpu time (in seconds) to be used by each process.
            '';
          };

          Data = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The maximum size (in bytes) of the data segment for a process; this defines how far a program may
              extend its break with the <literal>sbrk(2)</literal> system call.
            '';
          };

          FileSize = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The largest size (in bytes) file that may be created.
            '';
          };

          MemoryLock = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The maximum size (in bytes) which a process may lock into memory using the <literal>mlock(2)</literal> function.
            '';
          };

          NumberOfFiles = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The maximum number of open files for this process.  Setting this value in a system wide daemon
              will set the <literal>sysctl(3)</literal> kern.maxfiles (SoftResourceLimits) or kern.maxfilesperproc (HardResource-Limits) (HardResourceLimits)
              Limits) value in addition to the <literal>setrlimit(2)</literal> values.
            '';
          };

          NumberOfProcesses = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The maximum number of simultaneous processes for this user id.  Setting this value in a system
              wide daemon will set the <literal>sysctl(3)</literal> kern.maxproc (SoftResourceLimits) or kern.maxprocperuid
              (HardResourceLimits) value in addition to the <literal>setrlimit(2)</literal> values.
            '';
          };

          ResidentSetSize = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The maximum size (in bytes) to which a process's resident set size may grow.  This imposes a
              limit on the amount of physical memory to be given to a process; if memory is tight, the system
              will prefer to take memory from processes that are exceeding their declared resident set size.
            '';
          };

          Stack = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              The maximum size (in bytes) of the stack segment for a process; this defines how far a program's
              stack segment may be extended.  Stack extension is performed automatically by the system.
            '';
          };
        };
      });
    };

    Nice = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        This optional key specifies what nice(3) value should be applied to the daemon.
      '';
    };

    ProcessType = mkOption {
      type = types.nullOr
        (types.enum [ "Background" "Standard" "Adaptive" "Interactive" ]);
      default = null;
      example = "Background";
      description = ''
        This optional key describes, at a high level, the intended purpose of the job.  The system will apply
        resource limits based on what kind of job it is. If left unspecified, the system will apply light
        resource limits to the job, throttling its CPU usage and I/O bandwidth. The following are valid values:

           Background
           Background jobs are generally processes that do work that was not directly requested by the user.
           The resource limits applied to Background jobs are intended to prevent them from disrupting the
           user experience.

           Standard
           Standard jobs are equivalent to no ProcessType being set.

           Adaptive
           Adaptive jobs move between the Background and Interactive classifications based on activity over
           XPC connections. See <literal>xpc_transaction_begin(3)</literal> for details.

           Interactive
           Interactive jobs run with the same resource limitations as apps, that is to say, none. Interactive
           jobs are critical to maintaining a responsive user experience, and this key should only be
           used if an app's ability to be responsive depends on it, and cannot be made Adaptive.
      '';
    };

    AbandonProcessGroup = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        When a job dies, launchd kills any remaining processes with the same process group ID as the job.  Setting
        this key to true disables that behavior.
      '';
    };

    LowPriorityIO = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        This optional key specifies whether the kernel should consider this daemon to be low priority when
        doing file system I/O.
      '';
    };

    LaunchOnlyOnce = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        This optional key specifies whether the job can only be run once and only once.  In other words, if the
        job cannot be safely respawned without a full machine reboot, then set this key to be true.
      '';
    };

    MachServices = mkOption {
      default = null;
      example = { ResetAtClose = true; };
      description = ''
        This optional key is used to specify Mach services to be registered with the Mach bootstrap sub-system.
        Each key in this dictionary should be the name of service to be advertised. The value of the key must
        be a boolean and set to true.  Alternatively, a dictionary can be used instead of a simple true value.

        Finally, for the job itself, the values will be replaced with Mach ports at the time of check-in with
        launchd.
      '';
      type = types.nullOr (types.submodule {
        options = {
          ResetAtClose = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = ''
              If this boolean is false, the port is recycled, thus leaving clients to remain oblivious to the
              demand nature of job. If the value is set to true, clients receive port death notifications when
              the job lets go of the receive right. The port will be recreated atomically with respect to boot-strap_look_up() bootstrap_look_up()
              strap_look_up() calls, so that clients can trust that after receiving a port death notification,
              the new port will have already been recreated. Setting the value to true should be done with
              care. Not all clients may be able to handle this behavior. The default value is false.
            '';
          };

          HideUntilCheckIn = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = ''
              Reserve the name in the namespace, but cause bootstrap_look_up() to fail until the job has
              checked in with launchd.
            '';
          };
        };
      });
    };

    Sockets = mkOption {
      default = null;
      description = ''
        This optional key is used to specify launch on demand sockets that can be used to let launchd know when
        to run the job. The job must check-in to get a copy of the file descriptors using APIs outlined in
        launch(3).  The keys of the top level Sockets dictionary can be anything. They are meant for the application
        developer to use to differentiate which descriptors correspond to which application level protocols
        (e.g. http vs. ftp vs. DNS...).  At check-in time, the value of each Sockets dictionary key will
        be an array of descriptors. Daemon/Agent writers should consider all descriptors of a given key to be
        to be effectively equivalent, even though each file descriptor likely represents a different networking
        protocol which conforms to the criteria specified in the job configuration file.

        The parameters below are used as inputs to call <literal>getaddrinfo(3)</literal>.
      '';
      type = types.nullOr (types.attrsOf (types.submodule {
        options = {
          SockType = mkOption {
            type = types.nullOr (types.enum [ "stream" "dgram" "seqpacket" ]);
            default = null;
            description = ''
              This optional key tells launchctl what type of socket to create. The default is "stream" and
              other valid values for this key are "dgram" and "seqpacket" respectively.
            '';
          };

          SockPassive = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = ''
              This optional key specifies whether <literal>listen(2)</literal> or <literal>connect(2)</literal> should be called on the created file
              descriptor. The default is true ("to listen").
            '';
          };

          SockNodeName = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              This optional key specifies the node to <literal>connect(2)</literal> or <literal>bind(2)</literal> to.
            '';
          };

          SockServiceName = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              This optional key specifies the service on the node to <literal>connect(2)</literal> or <literal>bind(2)</literal> to.
            '';
          };

          SockFamily = mkOption {
            type = types.nullOr (types.enum [ "IPv4" "IPv6" ]);
            default = null;
            description = ''
              This optional key can be used to specifically request that "IPv4" or "IPv6" socket(s) be created.
            '';
          };

          SockProtocol = mkOption {
            type = types.nullOr (types.enum [ "TCP" ]);
            default = null;
            description = ''
              This optional key specifies the protocol to be passed to <literal>socket(2)</literal>.  The only value understood by
              this key at the moment is "TCP".
            '';
          };

          SockPathName = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = ''
              This optional key implies SockFamily is set to "Unix". It specifies the path to <literal>connect(2)</literal> or
              <literal>bind(2)</literal> to.
            '';
          };

          SecureSocketWithKey = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              This optional key is a variant of SockPathName. Instead of binding to a known path, a securely
              generated socket is created and the path is assigned to the environment variable that is inherited
              by all jobs spawned by launchd.
            '';
          };

          SockPathMode = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = ''
              This optional key specifies the mode of the socket. Known bug: Property lists don't support
              octal, so please convert the value to decimal.
            '';
          };

          Bonjour = mkOption {
            type =
              types.nullOr (types.either types.bool (types.listOf types.str));
            default = null;
            description = ''
              This optional key can be used to request that the service be registered with the
              <literal>mDNSResponder(8)</literal>.  If the value is boolean, the service name is inferred from the SockService-Name. SockServiceName.
              Name.
            '';
          };

          MulticastGroup = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              This optional key can be used to request that the datagram socket join a multicast group.  If the
              value is a hostname, then <literal>getaddrinfo(3)</literal> will be used to join the correct multicast address for a
              given socket family.  If an explicit IPv4 or IPv6 address is given, it is required that the Sock-Family SockFamily
              Family family also be set, otherwise the results are undefined.
            '';
          };
        };
      }));
    };
  };

  config = { };
}
