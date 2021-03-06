;; == Set up bundled Emacs packages ==

;; ido
(require 'ido)
(ido-mode t)
(setq ido-enable-flex-matching t) ;; fuzzy matching

;; Move between windows using M-Arrows
(require 'windmove)
(windmove-default-keybindings 'meta)

;; When opening another file with the same name, instead of <N> suffix,
;; use directory name
(require 'uniquify)
(setq uniquify-buffer-name-style 'reverse)
(setq uniquify-separator "|")
(setq uniquify-after-kill-buffer t)
(setq uniquify-ignore-buffers-ru "^\\*")

;; Support ANSI control sequences in shell
(require 'ansi-color)
(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)
(setq comint-prompt-read-only t)

;; orgmode
(require 'org-install)
(define-key global-map "\C-cl" 'org-store-link)
(define-key global-map "\C-ca" 'org-agenda)
(setq org-log-done t)

;; == Set up external packages ==

(add-to-list 'load-path (concat emacs-root "site-lisp"))
(setq packages-root (concat emacs-root "site-lisp/"))

;; Whitespace highlighting
(require 'show-wspace)
(add-hook 'font-lock-mode-hook 'show-ws-highlight-trailing-whitespace)

;; == OS-specific setup ==
(if (eq system-type 'windows-nt)
    (load-file (concat emacs-root "dot-windows.el")))


;; == Other packages ==

;; Haskell
(load (concat packages-root "haskell-mode-2.4/haskell-site-file"))
(add-hook 'haskell-mode-hook 'turn-on-haskell-doc-mode)
(add-hook 'haskell-mode-hook 'turn-on-haskell-indent)
(add-hook 'haskell-mode-hook 'font-lock-mode)


;; Fill-Column-Indicator
(setq-default fill-column 80)
(require 'fill-column-indicator)
(add-hook 'c++-mode-hook 'fci-mode)
(add-hook 'python-mode-hook 'fci-mode)
(add-hook 'java-mode-hook 'fci-mode)
(add-hook 'html-mode-hook 'fci-mode)
(add-hook 'javascript-mode-hook 'fci-mode)
(add-hook 'js2-mode-hook 'fci-mode)


;; Gambit Scheme
(require 'gambit)


;; GIT VC support
(add-to-list 'load-path (concat packages-root "git"))
(require 'git)
(require 'vc-git)
(add-to-list 'vc-handled-backends 'GIT)
(global-auto-revert-mode)
;; Buffer for Git
(shell (generate-new-buffer "=git="))


;; C++ style
(unless use-google-stuff
    (require 'google-c-style)
    (unless (string-match "v8" use-project)
            (add-hook 'c-mode-common-hook 'google-set-c-style))
    (add-hook 'c-mode-common-hook 'google-make-newline-indent))

;; Global
(require 'gtags)
(add-hook 'c-mode-common-hook '(lambda () (gtags-mode 1)))

;; JS2
(autoload 'js2-mode (format "js2-emacs%d" emacs-major-version) nil t)
(add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))
(add-hook 'js2-mode-hook 'js2-mode-reset nil t)
(if use-google-stuff
    (require 'js2-google))


;; MMM
;; (require 'javascript-mode)
;; (add-to-list 'load-path (concat packages-root "mmm-mode-0.4.8"))

;; (defun fix-javascript-mode ()
;;   "Various personal customizations for javascript-mode."
;;   (setq c-basic-offset 2)
;;   (setq fill-column 80)
;;   (font-lock-mode 1)
;;   (local-set-key "\C-c\C-c" 'comment-region)
;;   (local-set-key "\C-c\C-u" 'uncomment-region))

;; (autoload 'javascript-fix-indentation "javascript-indent")
;; (add-hook 'javascript-mode-hook 'javascript-fix-indentation)
;; (add-hook 'javascript-mode-hook 'fix-javascript-mode)

;; (require 'mmm-auto)
;; (setq mmm-global-mode 'maybe)
;; (add-to-list 'mmm-mode-ext-classes-alist
;;              '(html-mode "\\.s?html?\\'" html-js))


;; NXML
(add-to-list 'load-path (concat packages-root "nxml-mode"))
(load "rng-auto.el")
(setq auto-mode-alist
      (cons '("\\.\\(xml\\|xsl\\|rng\\|xhtml\\|gxp\\)\\'" . nxml-mode)
            auto-mode-alist))


;; Yasnippet
(add-to-list 'load-path (concat packages-root "yasnippet-0.5.6"))
(require 'yasnippet)
(setq yas/extra-mode-hooks '(nxml-mode-hook js2-mode-hook))
(yas/initialize)
(yas/load-directory (concat packages-root "yasnippet-0.5.6/snippets"))

;; gyp
(require 'gyp)
