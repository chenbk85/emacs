;; proof-compat.el   Operating system and Emacs version compatibility
;;
;; Copyright (C) 2000-2002 LFCS Edinburgh. 
;; Author:      David Aspinall <David.Aspinall@ed.ac.uk> and others
;; License:     GPL (GNU GENERAL PUBLIC LICENSE)
;;
;; proof-compat.el,v 10.0 2008/07/24 10:00:19 da Exp
;;
;; This file collects together compatibility hacks for different
;; operating systems and Emacs versions.  This is to help keep
;; track of them.
;;
;; The development policy for Proof General (since v3.7) is for the
;; main codebase to be written for the latest stable version of 
;; GNU Emacs, following GNU Emacs advice on obsolete function calls.
;;
;; Since Proof General 4.0, XEmacs is not supported at all.
;;

(eval-when-compile
  (require 'cl)
  (require 'easymenu))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Architecture flags
;;;

;; can use eval-and-compile to allow optimisation, but that would
;; require recompilation for Windows
(defvar proof-running-on-win32 (memq system-type '(win32 windows-nt cygwin))
  "Non-nil if Proof General is running on a windows variant system.")


;; Workaround a small bug in Carbon Emacs Winter 2008 (at least)
;; Menu presses query this variable, but it's not bound unless 
;; mode engaged.  Not noticeable in normal use, but it is as soon
;; as debug-on-error is engaged.
(if (and (boundp 'carbon-emacs-package-version)
	 (not (boundp 'mac-key-mode)))
    (setq mac-key-mode nil))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Modifications and adjustments
;;;

;; Remove a custom setting.  Needed to support dynamic reconfiguration.
;; (We'd prefer that repeated defcustom calls acted like repeated
;;  "defvar treated as defconst" in XEmacs)
(defun pg-custom-undeclare-variable (symbol)
  "Remove a custom setting SYMBOL.
Done by `makunbound' and removing all properties mentioned by custom library."
  (mapcar (lambda (prop) (remprop symbol prop))
	  '(default 
	     standard-value 
	     force-value 
	     variable-comment
	     saved-variable-comment
	     variable-documentation
	     group-documentation
	     custom-set
	     custom-get
	     custom-options
	     custom-requests
	     custom-group
	     custom-prefix
	     custom-tag
	     custom-links
	     custom-version
	     saved-value
	     theme-value
	     theme-face))
  (makunbound symbol))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; XEmacs compatibility
;;;

;; Compatibility with XEmacs 20.3
(or (fboundp 'split-path)
    (defun split-path (path)
      "Explode a search path into a list of strings.
The path components are separated with the characters specified
with `path-separator'."
      (split-string path (regexp-quote path-separator))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; GNU Emacs compatibility with XEmacs
;;;

(unless (fboundp 'save-selected-frame)
(defmacro save-selected-frame (&rest body)
  "Execute forms in BODY, then restore the selected frame.
The value returned is the value of the last form in BODY."
  (let ((old-frame (gensym "ssf")))
    `(let ((,old-frame (selected-frame)))
       (unwind-protect
           (progn ,@body)
         (select-frame ,old-frame))))))

;; Missing function, but anyway Emacs has no datatype for events...

(unless (fboundp 'events-to-keys)
  (defalias 'events-to-keys 'identity))

;; completion not autoloaded in GNU 20.6.1; we must call 
;; dynamic-completion-mode after loading it.
(or (fboundp 'complete)
    (autoload 'complete "completion"))

;; Replace in string: XEmacs original now in GNU Emacs as replace-regexp-in-string
(or (fboundp 'replace-in-string)
    (defun replace-in-string (str regexp newtext &optional literal)
      (replace-regexp-in-string regexp newtext str 'fixedcase literal)))


;; An implemenation of buffer-syntactic-context for GNU Emacs
(defun proof-buffer-syntactic-context-emulate (&optional buffer)
  "Return the syntactic context of BUFFER at point.
If BUFFER is nil or omitted, the current buffer is assumed.
The returned value is one of the following symbols:

	nil		; meaning no special interpretation
	string		; meaning point is within a string
	comment		; meaning point is within a line comment"
  (save-excursion
    (if buffer (set-buffer buffer))
    (let ((pp (parse-partial-sexp (point-min) (point))))
      (cond
       ((nth 3 pp) 'string)
       ;; ((nth 7 pp) 'block-comment)
       ;; "Stefan Monnier" <monnier+misc/news@rum.cs.yale.edu> suggests
       ;; distinguishing between block comments and ordinary comments
       ;; is problematic: not what XEmacs claims and different to what
       ;; (nth 7 pp) tells us in GNU Emacs.
       ((nth 4 pp) 'comment)))))


;; In case Emacs is not aware of the function read-shell-command,
;; we duplicate some code adjusted from minibuf.el distributed 
;; with XEmacs 21.1.9.  Bothering with this just to give completion for
;; when proof-prog-name-ask=t is a bit of an overkill!
;; Still, now it's here we'll leave it in as a pleasant surprise.
;;	
(or (fboundp 'read-shell-command)
(defvar read-shell-command-map
  (let ((map (make-sparse-keymap 'read-shell-command-map)))
    (if (fboundp 'set-keymap-parents)
      ;; XEmacs versions without read-shell-command?
	(set-keymap-parents map minibuffer-local-map)
      (if (fboundp 'set-keymap-parent)
	  ;; GNU Emacs 20.2
	  (set-keymap-parent map minibuffer-local-map)
	;; Earlier GNU Emacs
	(setq map (append minibuffer-local-map map))))
    (define-key map "\t" 'comint-dynamic-complete)
    (define-key map "\M-\t" 'comint-dynamic-complete)
    (define-key map "\M-?" 'comint-dynamic-list-completions)
    map)
  "Minibuffer keymap used by `shell-command' and related commands."))


(or (fboundp 'read-shell-command)
(defun read-shell-command (prompt &optional initial-input history)
      "Just like read-string, but uses read-shell-command-map:
\\{read-shell-command-map}"
      (let ((minibuffer-completion-table nil))
        (read-from-minibuffer prompt initial-input read-shell-command-map
                              nil (or history 'shell-command-history)))))


(or (fboundp 'frames-of-buffer)
;; From XEmacs 21.4.12, aliases expanded
(defun frames-of-buffer (&optional buffer visible-only)
  "Return list of frames that BUFFER is currently being displayed on.
If the buffer is being displayed on the currently selected frame, that frame
is first in the list.  VISIBLE-ONLY will only list non-iconified frames."
  (let ((list (get-buffer-window-list buffer))
	(cur-frame (selected-frame))
	next-frame frames save-frame)

    (while list
      (if (memq (setq next-frame (window-frame (car list)))
		frames)
	  nil
	(if (eq cur-frame next-frame)
	    (setq save-frame next-frame)
	  (and
	   (or (not visible-only)
	       (frame-visible-p next-frame))
	   (setq frames (append frames (list next-frame))))))
	(setq list (cdr list)))

    (if save-frame
	(append (list save-frame) frames)
      frames))))

;; These functions are used in the intricate logic around
;; shrink-to-fit.  

;; window-leftmost-p, window-rightmost-p: my implementations
(or (fboundp 'window-leftmost-p)
    (defun window-leftmost-p (window)
      (zerop (car (window-edges window)))))

(or (fboundp 'window-rightmost-p)
    (defun window-rightmost-p (window)
      (>= (nth 2 (window-edges window))
	  (frame-width (window-frame window)))))

(or (fboundp 'window-bottom-p)
    (defun window-bottom-p (window)
      (>= (nth 3 (window-edges window))
	  (frame-height (window-frame window)))))

;; with-selected-window from XEmacs 21.4.12
(or (fboundp 'with-selected-window)
(defmacro with-selected-window (window &rest body)
  "Execute forms in BODY with WINDOW as the selected window.
The value returned is the value of the last form in BODY."
  `(save-selected-window
     (select-window ,window)
     ,@body)))


;; find-coding-system emulation for GNU Emacs
(unless (fboundp 'find-coding-system)
  (defun find-coding-system (name)
    "Retrieve the coding system of the given name, or nil if non-such."
    (condition-case nil
	(check-coding-system name)
      (error nil))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; A naughty hack to completion.el 
;;;
;;; At the moment IMO completion too eagerly adds stuff to
;;; its database: the completion-before-command function
;;; makes every suffix be added as a completion!

(eval-after-load "completion"
'(defun completion-before-command ()
  (if (and (symbolp this-command) (get this-command 'completion-function))
	(funcall (get this-command 'completion-function)))))
      

(or (fboundp 'process-live-p)
(defun process-live-p (obj)
  "Return t if OBJECT is a process that is alive"
  (and (processp obj)
       (memq (process-status obj) '(open run stop)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; General Emacs version compatibility
;;;


(defalias 'proof-buffer-syntactic-context 
	  'proof-buffer-syntactic-context-emulate)

   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Nasty: Emacs bug/problem fix section
;;;


;; End of proof-compat.el
(provide 'proof-compat)
