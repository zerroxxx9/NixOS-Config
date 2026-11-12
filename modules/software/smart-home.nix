{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.software.smart-home;

  mqttPasswordFile = cfg.passwordFile;

  z2mStart = pkgs.writeShellScript "zigbee2mqtt-start" ''
    ZIGBEE2MQTT_CONFIG_MQTT_PASSWORD="$(cat "$CREDENTIALS_DIRECTORY/mqtt-password")"
    export ZIGBEE2MQTT_CONFIG_MQTT_PASSWORD
    exec ${config.services.zigbee2mqtt.package}/bin/zigbee2mqtt
  '';
in {
  options.modules.software.smart-home = {
    enable = lib.mkEnableOption "Mosquitto, Zigbee2MQTT and Home Assistant";

    passwordFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/secrets/mqtt-password";
      description = "Root-readable file with the MQTT password, created manually on the host.";
    };

    desktop = {
      mac = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "MAC address of the PC to wake. Enables a Home Assistant power switch when set.";
      };
      host = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "IP/hostname of the PC, used to ping its on/off state and to SSH in for shutdown.";
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "zerrox";
        description = "User on the PC that Home Assistant logs in as for shutdown.";
      };
      sshKeyFile = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/hass/.ssh/desktop-shutdown";
        description = "Private key Home Assistant uses to run the shutdown command on the PC.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.mosquitto = {
      enable = true;
      listeners = [
        {
          address = "127.0.0.1";
          port = 1883;
          users.zigbee2mqtt = {
            acl = ["readwrite #"];
            passwordFile = mqttPasswordFile;
          };
        }
      ];
    };

    services.zigbee2mqtt = {
      enable = true;
      settings = {
        homeassistant.enabled = true;
        permit_join = false;
        mqtt = {
          base_topic = "zigbee2mqtt";
          server = "mqtt://127.0.0.1:1883";
          user = "zigbee2mqtt";
        };
        serial = {
          port = "tcp://192.168.178.124:8888";
          adapter = "ember";
        };
        frontend = {
          enabled = true;
          host = "0.0.0.0";
          port = 8080;
        };
      };
    };

    systemd.services.mosquitto.unitConfig.ConditionPathExists = mqttPasswordFile;

    systemd.services.zigbee2mqtt = {
      unitConfig.ConditionPathExists = mqttPasswordFile;
      after = ["mosquitto.service"];
      wants = ["mosquitto.service"];
      serviceConfig = {
        LoadCredential = "mqtt-password:${mqttPasswordFile}";
        ExecStart = lib.mkForce "${z2mStart}";
      };
    };

    services.home-assistant = {
      enable = true;
      extraComponents = ["default_config" "mqtt" "met" "radio_browser" "wake_on_lan" "reolink"];
      config = {
        default_config = {};

        shell_command.desktop_shutdown = lib.mkIf (cfg.desktop.mac != null) (
          "ssh -i ${cfg.desktop.sshKeyFile} -o BatchMode=yes -o StrictHostKeyChecking=accept-new "
          + "-o UserKnownHostsFile=/var/lib/hass/.ssh/known_hosts "
          + "${cfg.desktop.user}@${cfg.desktop.host} systemctl poweroff"
        );

        switch = lib.mkIf (cfg.desktop.mac != null) [
          {
            platform = "wake_on_lan";
            name = "Desktop PC";
            mac = cfg.desktop.mac;
            host = cfg.desktop.host;
            turn_off = [{action = "shell_command.desktop_shutdown";}];
          }
        ];

        http = {
          server_host = "0.0.0.0";
          server_port = 8123;
        };
      };
    };

    systemd.services.home-assistant.path = lib.mkIf (cfg.desktop.mac != null) [
      pkgs.openssh
      "/run/wrappers"
    ];

    networking.firewall.allowedTCPPorts = [8080 8123];
  };
}
