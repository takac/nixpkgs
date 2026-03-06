{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.linux-voice-assistant;
in
{
  meta.maintainers = with lib.maintainers; [ takac ];

  options.services.linux-voice-assistant = {
    enable = lib.mkEnableOption "Linux Voice Assistant, a voice satellite for Home Assistant";

    package = lib.mkPackageOption pkgs "linux-voice-assistant" { };

    user = lib.mkOption {
      type = lib.types.str;
      default = "linux-voice-assistant";
      description = "User under which Linux Voice Assistant runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "linux-voice-assistant";
      description = "Group under which Linux Voice Assistant runs.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 6053;
      description = "TCP port for the ESPHome API server.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "IP address the ESPHome API server listens on.";
    };

    pulseServer = lib.mkOption {
      type = lib.types.str;
      default = "unix:/run/user/1000/pulse/native";
      example = "unix:/run/user/1000/pulse/native";
      description = ''
        PulseAudio or PipeWire socket used for microphone capture and audio
        playback. Set this to the socket of the user whose audio session
        should be used.
      '';
    };

    audioInputDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "default";
      description = ''
        soundcard name for the microphone input device.
        Run `linux-voice-assistant --list-input-devices` to enumerate available
        devices. Defaults to the system default microphone when null.
      '';
    };

    audioOutputDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "default";
      description = ''
        mpv audio output device for speaker playback.
        Run `linux-voice-assistant --list-output-devices` to enumerate available
        devices. Defaults to the system default speaker when null.
      '';
    };

    wakeModel = lib.mkOption {
      type = lib.types.str;
      default = "okay_nabu";
      description = "ID of the wake word model to activate.";
    };

    stopModel = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "stop";
      description = "ID of the wake word model used to cancel an active voice command. Uses the upstream default when null.";
    };

    refractorySeconds = lib.mkOption {
      type = lib.types.nullOr lib.types.number;
      default = null;
      example = 3.0;
      description = "Seconds that must pass after a wake word detection before it can trigger again. Uses the upstream default when null.";
    };

    wakeWordDirs = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      example = lib.literalExpression ''[ "/var/lib/linux-voice-assistant/custom-models" ]'';
      description = ''
        Additional directories to search for wake word models
        (`.tflite` files and their `.json` configs). The built-in models
        bundled with the package are always available; only set this to load
        custom models.
      '';
    };

    name = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "Living Room";
      description = ''
        Friendly display name shown in Home Assistant. Defaults to an
        auto-generated name based on the MAC address when null.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the firewall for the ESPHome API port.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--debug" ];
      description = "Extra command-line arguments passed to linux-voice-assistant.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    users = {
      groups.${cfg.group} = { };
      users.${cfg.user} = {
        description = "Linux Voice Assistant service user";
        group = cfg.group;
        # Member of audio so the PulseAudio/PipeWire client libraries can
        # access shared memory segments created by the sound server.
        extraGroups = [ "audio" ];
        isSystemUser = true;
      };
    };

    systemd.services.linux-voice-assistant = {
      description = "Linux Voice Assistant";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "network-online.target"
        "sound.target"
      ];
      wants = [ "network-online.target" ];

      environment = {
        PULSE_SERVER = cfg.pulseServer;
        XDG_RUNTIME_DIR = "/run/linux-voice-assistant";
      };

      serviceConfig =
        let
          args =
            [
              "--host"
              cfg.host
              "--port"
              (toString cfg.port)
              "--wake-model"
              cfg.wakeModel
            ]
            ++ lib.optionals (cfg.stopModel != null) [
              "--stop-model"
              cfg.stopModel
            ]
            ++ lib.optionals (cfg.refractorySeconds != null) [
              "--refractory-seconds"
              (toString cfg.refractorySeconds)
            ]
            ++ lib.concatMap (d: [ "--wake-word-dir" (toString d) ]) cfg.wakeWordDirs
            ++ lib.optionals (cfg.name != null) [
              "--name"
              cfg.name
            ]
            ++ lib.optionals (cfg.audioInputDevice != null) [
              "--audio-input-device"
              cfg.audioInputDevice
            ]
            ++ lib.optionals (cfg.audioOutputDevice != null) [
              "--audio-output-device"
              cfg.audioOutputDevice
            ]
            ++ cfg.extraArgs;
        in
        {
          ExecStart = lib.escapeShellArgs ([ (lib.getExe cfg.package) ] ++ args);
          User = cfg.user;
          Group = cfg.group;
          Restart = "on-failure";
          RestartSec = "5s";
          StateDirectory = "linux-voice-assistant";
          RuntimeDirectory = "linux-voice-assistant";
          RuntimeDirectoryMode = "0750";

          # Hardening
          AmbientCapabilities = "";
          CapabilityBoundingSet = "";
          DevicePolicy = "closed";
          DeviceAllow = [ "char-alsa rw" ];
          LockPersonality = true;
          NoNewPrivileges = true;
          PrivateMounts = true;
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          ProtectSystem = "strict";
          ProcSubset = "pid";
          RemoveIPC = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
            "AF_NETLINK"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];
          UMask = "0077";
        };
    };
  };
}
