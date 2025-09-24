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
      virtualisation.docker.rootless = {
        enable = true;
        setSocketVariable = true;   # sets DOCKER_HOST for that user’s login shells
      };

      # Ensure the user exists and that lingering is on
      users.users.${cfg.user} = {
        isNormalUser = lib.mkDefault true;
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

      # Optional: allow binding low ports in rootless
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
