;;f ~/.config/emacs/lean-deps.el

;; Carga lsp-mode desde repositorio clonado
(add-to-list 'load-path "/home/mushira/.config/lean4-mode")
(load-file "/home/mushira/.config/lean4-mode/lean4-mode.el")
(require 'lean4-mode)
(add-hook 'lean4-mode-hook #'eglot-ensure)
(setenv "PATH" (concat (getenv "PATH") ":/home/mushira/.elan/bin"))
(setq exec-path (append exec-path '("/home/mushira/.elan/bin")))
