{ config, lib, pkgs, username, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  copyCommand = if isDarwin then "pbcopy" else "xclip -selection clipboard";
in
{
  home.username = username;
  home.homeDirectory = if isDarwin then "/Users/${username}" else "/home/${username}";
  home.stateVersion = "26.05";

  xdg.enable = true;

  home.packages =
    (with pkgs; [
      atuin
      black
      cargo
      checkmake
      curl
      fd
      gcc
      gh
      go
      hyperfine
      jq
      kubectl
      lua-language-server
      mypy
      neovim
      nil
      nixfmt
      nodejs
      openjdk
      pandoc
      php
      phpPackages.composer
      pyright
      python3
      ripgrep
      ruff
      rustc
      shellcheck
      stylua
      tmux
      tree
      wget
      zsh-powerlevel10k
    ])
    ++ lib.optionals pkgs.stdenv.isLinux [
      pkgs.xclip
    ];

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/bin"
  ];

  home.file.".pylintrc".source = ../pylintrc;

  # Modern tmux reads ~/.config/tmux/tmux.conf. Keep a tiny ~/.tmux.conf
  # shim so older muscle memory and tools still land on the managed config.
  home.file.".tmux.conf".text = ''
    source-file ~/.config/tmux/tmux.conf
  '';

  xdg.configFile."nvim" = {
    source = ../config/nvim;
    recursive = true;
  };

  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };

    localVariables = {
      COMPLETION_WAITING_DOTS = "true";
      POWERLEVEL9K_INSTANT_PROMPT = "quiet";
    };

    shellAliases = {
      vi = "nvim";
      vim = "nvim";
      ls = "ls -laGF";
      tree = "tree -a";
    };

    initContent = lib.mkMerge [
      (lib.mkOrder 900 ''
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      '')
      (lib.mkOrder 1500 ''
        if [[ -n "$SSH_CONNECTION" ]]; then
          export EDITOR="vim"
        else
          export EDITOR="nvim"
        fi

        [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

        if [[ -x "/usr/local/microsoft/powershell/7/pwsh" ]]; then
          alias powershell="/usr/local/microsoft/powershell/7/pwsh"
        fi

        if [[ -x "$HOME/bin/gamadv-xtd3/gam" ]]; then
          alias gam="$HOME/bin/gamadv-xtd3/gam"
        fi
      '')
    ];
  };

  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    prefix = "C-z";
    historyLimit = 10000;
    escapeTime = 10;
    focusEvents = true;
    mouse = true;
    keyMode = "vi";
    shell = "${pkgs.zsh}/bin/zsh";

    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      {
        plugin = resurrect;
        extraConfig = "set -g @resurrect-capture-pane-contents 'on'";
      }
      {
        plugin = continuum;
        extraConfig = "set -g @continuum-restore 'on'";
      }
      copycat
      extrakto
      power-theme
    ];

    extraConfig = ''
      set-option -sa terminal-features ',xterm-256color:RGB'
      set-option -s set-clipboard off

      unbind %
      bind | split-window -h

      unbind '"'
      bind - split-window -v

      unbind l
      bind-key l next-window

      unbind h
      bind-key h previous-window

      bind-key -T copy-mode-vi C-h select-pane -L
      bind-key -T copy-mode-vi C-j select-pane -D
      bind-key -T copy-mode-vi C-k select-pane -U
      bind-key -T copy-mode-vi C-l select-pane -R
      bind-key -T copy-mode-vi 'C-\\' select-pane -l

      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel '${copyCommand}'
      bind-key p paste-buffer
    '';
  };

  programs.home-manager.enable = true;
}
