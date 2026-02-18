{ self }: { config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkOption mkIf types getExe;
  cfg = config.programs.oxwm;

  # Converts a nix submodule into a single oxwm bar block
  blockToLua = block: let
    common = ''
      interval = ${toString block.interval},
      color = "#${block.color}",
      underline = ${lib.boolToString block.underline},'';
  in "oxwm.bar.block.${block.kind}({\n" +
    (if block.kind == "static" then ''
      text = "${block.text}",
      ${common}
    '' else if block.kind == "shell" then ''
      format = "${block.format}",
      command = "${block.command}",
      ${common}
    '' else if block.kind == "datetime" then ''
      format = "${block.format}",
      date_format = "${block.date_format}",
      ${common}
    '' else if block.kind == "battery" then ''
      format = "${block.format}",
      charging = "${block.charging}",
      discharging = "${block.discharging}",
      full = "${block.full}",
      ${common}
    '' else ''
      format = "${block.format}",
      ${common}
    '') + "})";

    ruleToLua = rule: let
      fields = lib.concatStringsSep ", " (
        lib.optional (rule.match.class != null)    ''class = "${rule.match.class}"''    ++
        lib.optional (rule.match.instance != null) ''instance = "${rule.match.instance}"'' ++
        lib.optional (rule.match.title != null)    ''title = "${rule.match.title}"''    ++
        lib.optional (rule.match.role != null)     ''role = "${rule.match.role}"''      ++
        lib.optional (rule.floating != null)       ''floating = ${lib.boolToString rule.floating}'' ++
        lib.optional (rule.tag != null)            ''tag = ${toString rule.tag}''       ++
        lib.optional (rule.fullscreen != null)     ''fullscreen = ${lib.boolToString rule.fullscreen}''
      );
    in "oxwm.rule.add({ ${fields} })";
in
{
  options.programs.oxwm = {
    enable = mkEnableOption "oxwm window manager";
    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      description = "The oxwm package to use";
    };
    extraSessionCommands = mkOption {
      type = types.lines;
      default = "";
      description = "Shell commands executed just before oxwm is started";
    };
    terminal = mkOption { type = types.str; default = "alacritty"; };
    modkey = mkOption { type = types.str; default = "Mod4"; };
    tags = mkOption { type = types.listOf types.str;
      default = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" ];
    };
    layoutSymbol = {
      tiling = mkOption { type = types.str; default = "[T]"; };
      normie = mkOption { type = types.str; default = "[F]"; };
      tabbed = mkOption { type = types.str; default = "[=]"; };
    };
    autostart = mkOption {
      type = types.listOf types.str;
      default = [];
    };
    binds = mkOption {
      type = types.listOf (types.submodule {
        options = {
          mods = mkOption { type = types.listOf types.str; default = [ "${cfg.modkey}" ]; };
          key  = mkOption { type = types.str; };
          action = mkOption { type = types.str; };
        };
      });
      default = [];
    };
    border = {
      width = mkOption { type = types.int; default = 2; };
      focusedColor = mkOption { type = types.str; default = "6dade3"; };
      unfocusedColor = mkOption { type = types.str; default = "bbbbbb"; };
    };
    gaps = {
      smart = mkOption { type = types.enum [ "enabled"  "disabled" ]; default = "enabled"; };
      inner = mkOption { type = types.listOf types.int; default = [ 5 5 ];};
      outer = mkOption { type = types.listOf types.int; default = [ 5 5 ];};
    };
    bar = {
      font = mkOption { type = types.str; default = "monospace 10"; };
      hideVacantTags = mkOption { type = types.bool; default = false; };
      unoccupiedScheme = mkOption {
        type = types.listOf types.str;
        default = [ "bbbbbb" "1a1b26" "444444" ];
      };
      occupiedScheme = mkOption {
        type = types.listOf types.str;
        default = [ "0db9d7" "1a1b26" "0db9d7" ];
      };
      selectedScheme = mkOption {
        type = types.listOf types.str;
        default = [ "0db9d7" "1a1b26" "ad8ee6" ];
      };
      urgentScheme = mkOption {
        type = types.listOf types.str;
        default = [ "f7768e" "1a1b26" "f7768e" ];
      };
      blocks = mkOption { type = types.listOf (types.submodule {
        options = {
          kind = mkOption {
            type = types.enum [ "ram" "static" "shell" "datetime" "battery" ];
            default = "static";
          };
          interval = mkOption { type = types.int; default = 5; };
          color = mkOption { type = types.str; default = ""; };
          underline = mkOption { type = types.bool; default = true; };
          text = mkOption { type = types.str; default = "|"; };
          format = mkOption { type = types.str; default = "{}"; };
          command = mkOption { type = types.str; default = "uname -r"; };
          date_format = mkOption { type = types.str; default = "%a, %b %d - %-I:%M %P"; };
          charging = mkOption { type = types.str; default = "⚡ Bat: {}%"; };
          discharging = mkOption { type = types.str; default = "- Bat: {}%"; };
          full = mkOption { type = types.str; default = "✓ Bat: {}%"; };
        };
      }); };
    };
    rules = mkOption { type = types.listOf (types.submodule {
      options = {
        match = {
          class = mkOption { type = types.nullOr types.str; default = null; };
          instance = mkOption { type = types.nullOr types.str; default = null; };
          title = mkOption { type = types.nullOr types.str; default = null; };
          role = mkOption { type = types.nullOr types.str; default = null; };
        };
        floating = mkOption { type = types.nullOr types.bool; default = null; };
        tag = mkOption { type = types.nullOr types.int; default = null; };
        fullscreen = mkOption { type = types.nullOr types.bool; default = null; };
      };
    }); };
    extraConfig = mkOption { type = types.lines; default = ""; };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xsession.windowManager.command = ''
      ${cfg.extraSessionCommands}
      export _JAVA_AWT_WM_NONREPARENTING=1
      exec ${getExe cfg.package}
    '';

    xdg.configFile."oxwm/config.lua".text = ''
      @meta
      @module 'oxwm'

      oxwm.set_terminal("${cfg.terminal}")
      oxwm.set_modkey("${cfg.modkey}")
      oxwm.set_tags({${lib.concatMapStringsSep ", " (t: ''"${t}"'') cfg.tags}})

      local blocks = {
        ${lib.concatMapStringsSep ",\n" blockToLua cfg.bar.blocks}
      };
      oxwm.bar.set_blocks(blocks)
      oxwm.bar.set_font("${cfg.bar.font}")
      oxwm.bar.set_scheme_normal(${lib.concatMapStringsSep ", " (c: ''"#${c}"'') cfg.bar.unoccupiedScheme})
      oxwm.bar.set_scheme_occupied(${lib.concatMapStringsSep ", " (c: ''"#${c}"'') cfg.bar.occupiedScheme})
      oxwm.bar.set_scheme_selected(${lib.concatMapStringsSep ", " (c: ''"#${c}"'') cfg.bar.selectedScheme})
      oxwm.bar.set_scheme_urgent(${lib.concatMapStringsSep ", " (c: ''"#${c}"'') cfg.bar.urgentScheme})
      oxwm.bar.set_hide_vacant_tags(${lib.boolToString cfg.bar.hideVacantTags})

      oxwm.border.set_width(${toString cfg.border.width})
      oxwm.border.set_focused_color("#${cfg.border.focusedColor}")
      oxwm.border.set_unfocused_color("#${cfg.border.unfocusedColor}")

      oxwm.gaps.set_smart(${cfg.gaps.smart})
      oxwm.gaps.set_inner(${lib.concatMapStringsSep ", " toString cfg.gaps.inner})
      oxwm.gaps.set_outer(${lib.concatMapStringsSep ", " toString cfg.gaps.outer})

      oxwm.set_layout_symbol("tiling", "${cfg.layoutSymbol.tiling}")
      oxwm.set_layout_symbol("normie", "${cfg.layoutSymbol.normie}")
      oxwm.set_layout_symbol("tabbed", "${cfg.layoutSymbol.tabbed}")

      ${lib.concatMapStrings (cmd: ''
          oxwm.autostart("${cmd}")
      '') cfg.autostart}
      ${lib.concatMapStrings (bind: ''
        oxwm.key.bind({ ${lib.concatMapStringsSep ", " (m: ''"${m}"'') bind.mods} }, "${bind.key}", ${bind.action})
      '') cfg.binds}
      ${cfg.extraConfig}
      ${lib.concatMapStrings (rule: ''
        ${ruleToLua rule}
      '') cfg.rules}
    '';
  };
}
