(ido-mode 1)
(scroll-bar-mode -1)
(menu-bar-mode -1)
(tool-bar-mode -1)
(load-theme 'doom-one t)
(setq inhibit-startup-screen t)
(setq-default indent-tabs-mode nil)
;; vc runs git on every file open, and a repo's own .git/config can name
;; an fsmonitor program for git to run. Config from the environment
;; overrides the repo's, so turn it off for every git Emacs starts.
(setenv "GIT_CONFIG_COUNT" "1")
(setenv "GIT_CONFIG_KEY_0" "core.fsmonitor")
(setenv "GIT_CONFIG_VALUE_0" "false")
