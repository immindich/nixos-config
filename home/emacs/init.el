(ido-mode 1)
(scroll-bar-mode -1)
(menu-bar-mode -1)
(tool-bar-mode -1)
(load-theme 'doom-one t)
(setq inhibit-startup-screen t)
(setq-default indent-tabs-mode nil)
;; Reload buffers when their file changes on disk (e.g. edited by an agent).
(global-auto-revert-mode 1)
;; vc runs git on every file open, and a repo's own .git/config can name
;; an fsmonitor program for git to run. Config from the environment
;; overrides the repo's, so turn it off for every git Emacs starts.
(setenv "GIT_CONFIG_COUNT" "1")
(setenv "GIT_CONFIG_KEY_0" "core.fsmonitor")
(setenv "GIT_CONFIG_VALUE_0" "false")

;; agent-shell: always use Claude Code, open it in a split, and bind C-c a.
;; Installed by Nix (home/common.nix), so no :ensure.
(use-package agent-shell
  :bind ("C-c a" . agent-shell)
  :custom
  (agent-shell-preferred-agent-config 'claude-code)
  (agent-shell-display-action
   '((display-buffer-reuse-window display-buffer-pop-up-window)))
  (agent-shell-show-session-id t)
  (agent-shell-session-restore-verbosity 'full)
  (agent-shell-anthropic-default-session-mode-id "auto"))
