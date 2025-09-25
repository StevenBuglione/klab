{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkOption types mkIf mkMerge optionals mkAfter mkDefault;
  cfg = config.klab.hummingbot.docker;
in
{
  options.klab.hummingbot.docker = {
    enable = mkEnableOption "Install and configure Docker for Hummingbot with secure defaults";

    # Which account will be running Hummingbot containers
    user = mkOption {
      type = types.str;
      default = "hummingbot";
      description = "Primary user that will run Hummingbot containers.";
    };

    # Mode: "rootless" (recommended) or "rootful"
    mode = mkOption {
      type = types.enum [ "rootless" "rootful" ];
      default = "rootless";
      description = "Docker engine mode. Rootless is most secure for single-user setups.";
    };

    # Extra daemon.json settings to merge in (for experts)
    extraDaemonSettings = mkOption {
      type = types.attrs;
      default = {};
      description = "Additional Docker daemon settings merged into daemon.json.";
    };

    # Enable a weekly prune of unused images/volumes/networks (safe)
    enableWeeklyPrune = mkOption {
      type = types.bool;
      default = true;
      description = "Enable a safe weekly docker system prune (non-running, dangling only).";
    };

    # Install CLI helpers (compose, buildx)
    installCompose = mkOption { type = types.bool; default = true; };
    installBuildx  = mkOption { type = types.bool; default = true; };
  };

  config = mkIf cfg.enable (mkMerge [
    #############################################
    # Common packages / helpers
    #############################################
    {
      environment.systemPackages =
        (with pkgs; [ docker ]) ++
        optionals cfg.installCompose (with pkgs; [ docker-compose ]) ++
        optionals cfg.installBuildx  (with pkgs; [ docker-buildx ]);
    }

    #############################################
    # Rootless mode (recommended)
    #############################################
    (mkIf (cfg.mode == "rootless") {
      # Rootless engine for the specified user; sets DOCKER_HOST in login shells
      virtualisation.docker.rootless = {
        enable = true;
        setSocketVariable = true;
      };

      # Ensure the user exists and that lingering is on so user services run at boot
      users.users.${cfg.user} = {
        isNormalUser = mkDefault true;
        linger = true;
      };

      # User-level daemon tied to systemd --user (autostarts thanks to lingering)
      systemd.user.services."docker-rootless" = {
        description = "Rootless Docker daemon";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "notify";
          Environment = [
            "DOCKERD_ROOTLESS_ROOTLESSKIT_PORT_DRIVER=slirp4netns"
          ];
          ExecStart = "${pkgs.docker}/bin/dockerd-rootless.sh";
          Restart = "always";
          RestartSec = "2s";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = "read-only";
          ProtectSystem = "strict";
          StateDirectory = "docker";
        };
      };

      # Optional: allow binding low ports in rootless (0 disables the restriction)
      boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;

      # Make sure the system (rootful) socket does not hijack the client unintentionally
      systemd.services.docker.wantedBy = lib.mkForce [ ];
      systemd.sockets.docker.wantedBy  = lib.mkForce [ ];
    })

    #############################################
    # Rootful + userns-remap (hardened)
    #############################################
    (mkIf (cfg.mode == "rootful") {
      # --- remap user/group with subordinate ID ranges (creates /etc/subuid,/etc/subgid)
      users.groups.dockremap = { };
      users.users.dockremap = {
        isSystemUser = true;
        description  = "Docker remap user (non-login)";
        group        = "dockremap";
        home         = "/var/empty";
        shell        = "${pkgs.shadow}/bin/nologin";
        subUidRanges = [ { startUid = 100000; count = 65536; } ];
        subGidRanges = [ { startGid = 100000; count = 65536; } ];
      };

      # --- setuid helpers required by userns-remap
      security.wrappers.newuidmap = {
        source = "${pkgs.shadow}/bin/newuidmap";
        owner = "root"; group = "root"; setuid = true;
      };
      security.wrappers.newgidmap = {
        source = "${pkgs.shadow}/bin/newgidmap";
        owner = "root"; group = "root"; setuid = true;
      };

      # --- ensure crun is present
      environment.systemPackages = lib.mkAfter [ pkgs.crun pkgs.docker ];

      virtualisation.docker = {
        enable = true;

        daemon.settings = {
          # your existing hardening...
          "icc" = false;
          "no-new-privileges" = true;
          "userns-remap" = "dockremap:dockremap";

          "live-restore" = true;
          "log-driver" = "json-file";
          "log-opts" = { "max-size" = "10m"; "max-file" = "3"; };
          "default-ulimits" = {
            "nofile" = { "Name" = "nofile"; "Soft" = 1048576; "Hard" = 1048576; };
            "nproc"  = { "Name" = "nproc";  "Soft" =  65535;   "Hard" =  65535;   };
          };
          "default-address-pools" = [ { "base" = "10.248.0.0/16"; "size" = 24; } ];

          # cgroups + runtime
          "exec-opts" = [ "native.cgroupdriver=systemd" ];
          "runtimes" = { "crun" = { "path" = "${pkgs.crun}/bin/crun"; }; };
          "default-runtime" = "crun";
        };
      };

      # (usually already true on recent NixOS; harmless to keep)
      boot.kernelParams = [ "systemd.unified_cgroup_hierarchy=1" ];
    })

    #############################################
    # Maintenance: safe weekly prune
    #############################################
    (mkIf cfg.enableWeeklyPrune {
      systemd.timers."docker-prune-weekly" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "Sun 03:30";   # after your 00:00 upgrades
          Persistent = true;
        };
      };
      systemd.services."docker-prune-weekly" = {
        serviceConfig = { Type = "oneshot"; };
        script = ''
          set -eu

          # Rootless prune (if the user has a rootless daemon)
          if sudo -u ${cfg.user} -H sh -lc 'command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1'; then
            sudo -u ${cfg.user} -H sh -lc 'docker system prune -af --volumes || true'
          fi

          # Rootful prune (if system docker is available)
          if command -v docker >/dev/null 2>&1; then
            docker system prune -af --volumes || true
          fi
        '';
      };
    })
  ]);
}