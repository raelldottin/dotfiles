{ config, lib, pkgs, username, homeDirectory, workConfigured, ... }:
let
  # Only public code is copied into the store. Identity is read at activation.
  guardSource = pkgs.runCommand "dotfiles-work-guard" { } ''
    mkdir -p "$out/config/git/hooks"
    cp ${../workstation.py} "$out/workstation.py"
    cp ${../dotfiles_manifest.py} "$out/dotfiles_manifest.py"
    cp ${../config/git/work.conf} "$out/config/git/work.conf"
    cp ${../config/git/hooks/pre-commit} "$out/config/git/hooks/pre-commit"
    cp ${../config/git/hooks/prepare-commit-msg} "$out/config/git/hooks/prepare-commit-msg"
    cp ${../config/git/hooks/pre-rebase} "$out/config/git/hooks/pre-rebase"
    chmod u+w "$out/config/git/hooks/"*
    substituteInPlace "$out/config/git/hooks/"* \
      --replace-fail '#!/usr/bin/env python3' '#!${pkgs.python3}/bin/python3'
    chmod +x "$out/config/git/hooks/"*
  '';
  workCommand = pkgs.writeShellScriptBin "dotfiles-work" ''
    if [ "${lib.boolToString workConfigured}" != true ]; then
      echo "Set DOTFILES_WORK_USER and DOTFILES_WORK_HOME and evaluate with --impure." >&2
      exit 1
    fi
    export PATH="${pkgs.git}/bin:$PATH"
    exec ${pkgs.python3}/bin/python3 ${guardSource}/workstation.py \
      --expected-home ${lib.escapeShellArg homeDirectory} "$@"
  '';
in
{
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "26.05";
  assertions = [
    {
      assertion = pkgs.stdenv.isDarwin && username != "" && lib.hasPrefix "/" homeDirectory;
      message = "The work profile requires macOS and explicit DOTFILES_WORK_USER / DOTFILES_WORK_HOME.";
    }
  ];

  # User-only Home Manager: no company system settings or personal module.
  home.packages = with pkgs; [
    git gh neovim pure-prompt atuin tmux uv python3 ripgrep fd tree jq
    bash-language-server ruff cargo rustc rust-analyzer rustfmt shfmt
    checkmake shellcheck luaPackages.luacheck pyright
    workCommand
  ];
  home.sessionPath = [ "$HOME/.local/bin" ];
  xdg = {
    enable = true;
    dataHome = "${homeDirectory}/.local/share/work";
    stateHome = "${homeDirectory}/.local/state/work";
    cacheHome = "${homeDirectory}/.cache/work";
    configFile."nvim-work" = {
      source = ../config/nvim;
      recursive = true;
    };
    configFile."atuin-work/config.toml".source = ../config/atuin/config.toml;
    configFile."dotfiles/git.conf".source = ../config/git/work.conf;
  };
  home.file.".pylintrc".source = ../pylintrc;
  home.sessionVariables = {
    DOTFILES_PROFILE = "work";
    ATUIN_CONFIG_DIR = "${homeDirectory}/.config/atuin-work";
    NVIM_APPNAME = "nvim-work";
    GIT_CONFIG_GLOBAL = "${homeDirectory}/.gitconfig";
  };

  # Fail before Home Manager's write boundary. No identity is evaluated by Nix.
  home.activation.workProfilePreflight = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    ${workCommand}/bin/dotfiles-work preflight
  '';
  home.activation.workProfileInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${workCommand}/bin/dotfiles-work install
  '';

  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = false;
    history.path = "${homeDirectory}/.local/state/work/zsh/history";
    initContent = ''
      DOTFILES_PURE_SITE_FUNCTIONS="${pkgs.pure-prompt}/share/zsh/site-functions"
    '' + builtins.readFile ../zshrc;
  };
  programs.tmux = {
    enable = true;
    prefix = "C-z";
    historyLimit = 10000;
    mouse = true;
    keyMode = "vi";
    shell = "${pkgs.zsh}/bin/zsh";
    plugins = [ pkgs.tmuxPlugins.vim-tmux-navigator ];
    # Personal pane capture and automatic session restoration are not enabled.
    extraConfig = ''
      unbind %
      bind | split-window -h
      unbind '"'
      bind - split-window -v
    '';
  };
  programs.home-manager.enable = true;
}
