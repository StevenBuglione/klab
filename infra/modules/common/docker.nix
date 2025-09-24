{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkOption types mkIf mkMerge;
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
        lib.optionals cfg.installCompose (with pkgs; [ docker-compose ]) ++
        lib.optionals cfg.installBuildx  (with pkgs; [ docker-buildx ]);
    }

    #############################################
    # Rootless mode (recommended)
    #############################################
    (mkIf (cfg.mode == "rootless") {
      # Rootless engine for the specified user
      virtualisation.docker.rootless = {
        enable = true;
        setSocketVariable = true;   # exports DOCKER_HOST in that user's login shells
      };

      # Ensure the user exists (merges safely if already defined elsewhere)
      users.users.${cfg.user} = {
        isNormalUser = lib.mkDefault true;
      };

      # Keep the user's systemd --user instance running even when not logged in
      services.logind.lingerUsers = lib.mkAfter [ cfg.user ];

      # Declarative user service that runs the rootless dockerd
      # (This mirrors what 'dockerd-rootless-setuptool.sh install' would do,
      #  but in a NixOS-friendly, reproducible way.)
      systemd.user.services."docker-rootless" = {
        description = "Rootless Docker daemon";
        # Start for all users; in practice only the lingered user will keep it running
        wantedBy = [ "default.target" ];

        serviceConfig = {
          Type = "notify";
          # Helpful environment for rootless networking
          Environment = [
            "DOCKERD_ROOTLESS_ROOTLESSKIT_PORT_DRIVER=slirp4netns"
            # XDG_RUNTIME_DIR is already set in user services (%t), no need to override
          ];
          ExecStart = "${pkgs.docker}/bin/dockerd-rootless.sh";
          Restart = "always";
          RestartSec = 2s;

          # Hardening (safe defaults)
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = "read-only";
          ProtectSystem = "strict";
          StateDirectory = "docker";  # creates ~/.local/state/docker for this service if needed
        };
      };

      # Optional: allow binding low ports in rootless (0 disables the restriction)
      boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;
    })


    #############################################
    # Rootful + userns-remap (hardened)
    #############################################
    (mkIf (cfg.mode == "rootful") {
      virtualisation.docker = {
        enable = true;

        # daemon.json hardened defaults
        daemon = {
          settings = {
            # Security hardening
            "userns-remap" = "default";           # map container root → subuid/subgid
            "icc" = false;                        # disable inter-container comm on default bridge
            "no-new-privileges" = true;           # requires recent dockerd; safer default

            # Stability & observability
            "live-restore" = true;
            "log-driver" = "json-file";
            "log-opts" = {
              "max-size" = "10m";
              "max-file" = "3";
            };
            "default-ulimits" = {
              "nofile" = { "Name" = "nofile"; "Hard" = 1048576; "Soft" = 1048576; };
            };

            # Avoid address clashes for user-defined bridges (adjust as you like)
            "default-address-pools" = [
              { "base" = "10.248.0.0/16"; "size" = 24; }
            ];
          } // cfg.extraDaemonSettings;
        };
      };

      # In rootful mode, add the user to the docker group (so they can run docker without sudo)
      users.users.${cfg.user}.extraGroups = lib.mkAfter [ "docker" ];

      # Optional: firewall stays closed by default; only open what you publish intentionally.
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
        serviceConfig = {
          Type = "oneshot";
          # Rootless vs rootful: try both; failures are fine.
        };
        script = ''
          set -eu
          # Rootless prune (if the user has a rootless daemon)
          if sudo -u ${cfg.user} -H sh -lc 'command -v docker >/dev/null && docker info >/dev/null 2>&1'; then
            sudo -u ${cfg.user} -H sh -lc 'docker system prune -af --volumes || true'
          fi

          # Rootful prune (requires docker group or sudo)
          if command -v docker >/dev/null; then
            docker system prune -af --volumes || true
          fi
        '';
      };
    })
  ]);
}
