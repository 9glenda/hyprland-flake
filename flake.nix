{
  description = "9glenda's simple Hyprland flake for easy configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, hyprland, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            hyprland.overlays.default
            (final: prev: {
              wofi-bluetooth = prev.rofi-bluetooth.overrideAttrs (oldAttrs: {
                patchPhase = ''
                  sed -i -e 's/rofi/wofi/g' ./rofi-bluetooth
                '';
              });
            })
          ];
        };

        hyprlandBuilder = { configPath ? ./config/hyprland.conf, extraConfig ? "" }: let
          cfg = path: "${builtins.readFile configPath}";
        in 
          pkgs.writeShellScriptBin "Hyprland" ''
              ${pkgs.hyprland}/bin/Hyprland --config ${pkgs.writeText "hyprland.conf" ''
                ${cfg configPath}
                ${extraConfig}
              ''}
          '';

        in rec {

        packages = {
          hyprlandGlenda = hyprlandBuilder {
            extraConfig = ''
              bind = $mainMod, Return, exec, ${pkgs.foot}/bin/foot
              bind = $mainMod SHIFT, Return, exec, ${pkgs.foot}/bin/foot firejail
              bind = $mainMod SHIFT, C, killactive
              bind = $mainMod SHIFT, Q, exit
              bind = $mainMod, P, exec, ${pkgs.wofi}/bin/wofi --show drun
              bind = $mainMod SHIFT, P, exec, ${pkgs.foot}/bin/foot -a float proton togglenotify
              bind = $mainMod, V, togglefloating,
              bind = $mainMod, F, fullscreen,
              bind = $mainMod, W, exec, ${pkgs.cliphist}/bin/cliphist  list | ${pkgs.wofi}/bin/wofi -dmenu | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy

              # Screenshot
              bind = $mainMod SHIFT, S, exec, ${pkgs.sway-contrib.grimshot}/bin/grimshot copy screen
              bind = $mainMod , S, exec, ${pkgs.sway-contrib.grimshot}/bin/grimshot copy area

              # Wofi
              bind = $mainMod, b, exec, ${pkgs.wofi-bluetooth}/bin/rofi-bluetooth
            '';
          };
          default = packages.hyprlandGlenda;
        };
      # nixosConfigurations.test = {
      #   imports = [
      #     self.nixosModules.default
      #   ];
      #   config = {
      #      boot.loader.grub.enable = true;
 # boot.loader.grub.devices = [ "nodev" ];
 # boot.loader.grub.efiInstallAsRemovable = true;
 # boot.loader.grub.efiSupport = true;
 # boot.loader.grub.useOSProber = true;

      #   };
      # };

    }) // {

      nixosModules = {
        default = inputs@{ pkgs, lib, config, ... }:
          let
          in {
            imports = [
              hyprland.nixosModules.default
            ];
            config = {
              security.pam.services.swaylock = {
                text = ''
                  auth include login
                '';
              };

              xdg.portal = {
                extraPortals = with pkgs; [   
                  #xdg-desktop-portal-hyprland
                ];
                xdgOpenUsePortal = true;
                wlr = {
                  enable = true;
                  settings = {
                    screencast = {
                      output_name = "HDMI-A-1";
                      max_fps = 60;
                      exec_before = "disable_notifications.sh";
                      exec_after = "enable_notifications.sh";
                      chooser_type = "simple";
                      chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
                    };
                  };
                };
              };
              programs.hyprland = {
                enable = true;
                xwayland = {
                  enable = true;
                };
                package = inputs.self.packages.default;
              };

            };
          } inputs;  
      };
    };
}
