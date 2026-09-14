;; -*- lexical-binding: t; -*-

;;; init-ui.el --- UI-related configuration

;;; Commentary:
;;

;;; Code:

;;; Fonts

;; (set-face-attribute 'default nil :family "FiraCode Nerd Font Mono" :height 110)
;; (set-face-attribute 'fixed-pitch nil :family "FiraCode Nerd Font Mono" :height 110)
;; (set-face-attribute 'variable-pitch nil :family "Fira Sans" :height 115)

(set-face-attribute 'default nil :family "AporeticSansMonoNerdFont" :height 125)
(set-face-attribute 'fixed-pitch nil :family "AporeticSansMonoNerdFont" :height 125)
(set-face-attribute 'variable-pitch nil :family "Aporetic Sans" :height 125)

;;; Modus theme setup

;; Do not use-package as its a theme, not a package !
;; Require `modus-themes' without loading it, making `modus-themes-with-colors' available.
(require-theme 'modus-themes)

;; Those need to be set before a modus theme is loaded (by circadian)
(setopt modus-themes-bold-constructs t)
(setopt modus-themes-italic-constructs nil)
(setopt modus-themes-mixed-fonts t)

(setq modus-themes-common-palette-overrides
      `(;; From the section "Make the mode line borderless"
        (border-mode-line-active unspecified)
        (border-mode-line-inactive unspecified)
	;; Make it closer to the background color
	(bg-mode-line-active bg-inactive)
	(bg-mode-line-inactive bg-dim)
	;; Colorful background for active tab
	(bg-tab-bar bg-inactive)
        (bg-tab-current bg-cyan-subtle)
        (bg-tab-other bg-dim)

	;; (fg-heading-1 blue-warmer)
        ;;      (fg-heading-2 yellow-cooler)
        ;;      (fg-heading-3 cyan-cooler)
	(fg-heading-1 fg-main)
        (bg-heading-1 bg-dim)
        (overline-heading-1 border)
	(fg-heading-2 fg-alt)
        (bg-heading-2 bg-main)
        (overline-heading-2 border)))

(setq modus-themes-headings
      '((0 . 3.0)
	(1 . (1.2))
	(2 . (1.1))))

;;; Color selected window mode-line buffer ID

(defun nol/set-modus-dependent-faces ()
  (modus-themes-with-colors
    (let ((heading-1-fg (color-darken-name fg-main 5))
	  (heading-2-fg (color-darken-name fg-main 10)))
      (custom-theme-set-faces
     'user
     `(mode-line-buffer-id		; this will be bold if `modus-themes-bold-constructs' is set before a modus theme is loaded
       ((t (:inherit bold :foreground ,accent-0))))

     `(modus-themes-heading-0
       ((t (:family "Aldrich" :height 3.0 :underline t))))

     ;; `(modus-themes-heading-1
     ;;   ((t (:foreground ,heading-1-fg))))

     ;; `(modus-themes-heading-2
     ;;   ((t :foreground ,heading-2-fg)))

     `(org-todo
       ((t (:font "Aldrich" :background ,bg-main :foreground ,red :weight bold))))))))

(add-hook 'modus-themes-after-load-theme-hook #'nol/set-modus-dependent-faces)

(defun nol/propertized-buffer-identification (fmt)
  "Like `propertized-buffer-identification', but use a special face in the selected window."
  (list
   (propertize fmt
               'face (if (mode-line-window-selected-p)
                         'mode-line-buffer-id
                       'bold)
               'help-echo
               (purecopy "Buffer name
mouse-1: Previous buffer
mouse-3: Next buffer")
               'mouse-face 'mode-line-highlight
               'local-map mode-line-buffer-identification-keymap)))

(setq-default mode-line-buffer-identification
              '(:eval (nol/propertized-buffer-identification "%12b")))

;;; Circadian

(defun nol/run-modus-after-load-theme-hook (theme)
  "Run Modus after-load hook when Circadian loads a Modus THEME."
  (when (string-prefix-p "modus-" (symbol-name theme))
    (run-hooks 'modus-themes-after-load-theme-hook)))

(defun nol/circadian-after-load-theme (theme)
  "Extra things to do after Circadian loads THEME."
  (nol/run-modus-after-load-theme-hook theme)

  (when (and (bound-and-true-p od/exwm-enabled)
             (fboundp 'nol/set-xsettings-theme))
    (nol/set-xsettings-theme theme)))

;; Keep this package first as it load a modus themes and enable the use of
;; `modus-themes-with-colors' macro.
(require 'circadian)
(setopt circadian-verbose t
	circadian-themes '((:sunrise . modus-operandi)
			   (:sunset . modus-vivendi)))

(add-hook 'circadian-after-load-theme-hook #'nol/circadian-after-load-theme)

(circadian-setup)

(defun nol/fix-gnus-modus-face-cycle (theme &rest _)
  "Prevent a Gnus/Modus inheritance cycle in Emacs 31."
  (when (and (string-prefix-p "modus-" (symbol-name theme))
	     (facep 'gnus-group-news-6))
    (set-face-attribute 'gnus-group-news-6 nil :inherit nil)))

(advice-add 'load-theme :before #'nol/fix-gnus-modus-face-cycle)

(defun nol/set-theme (theme-or-name)
  (interactive
   (list
    (intern (completing-read "Load custom theme: "
                             (mapcar #'symbol-name
				     (custom-available-themes))))))
  "Load `THEME' and disable currently enabled themes."
  (let ((theme-or-name (if (stringp theme-or-name)
			   (intern theme-or-name)
			 theme-or-name)))
    (mapc #'disable-theme custom-enabled-themes)
    (load-theme theme-or-name t)
    (nol/custom-set-faces)
    (when (and od/exwm-enabled
	       (fboundp 'nol/set-xsettings-theme))
      (nol/set-xsettings-theme theme-or-name))))

;; Might wanna take a look at `modify-all-frame-parameters'
(defun od/set-all-fonts (fixed-face variable-face default-height &optional variable-factor)
  "Set FIXED-FACE and VARIABLE-FACE fonts with DEFAULT-HEIGHT for all frames.
Optionally, change the size of VARIABLE-FACE fonts according to VARIABLE-FACTOR."
  (let ((vf (or variable-factor 1.0)))
    (set-face-attribute 'default nil
			:family fixed-face
			:height default-height
			:weight 'regular)
    (set-face-attribute 'fixed-pitch nil
			:family fixed-face
			:weight 'regular)
    (set-face-attribute 'variable-pitch nil
			:family variable-face
			:height vf
			:weight 'regular)
    (set-face-attribute 'mode-line-active nil ;; Save a bit of screen estate by reducing mode-line height
			:height 0.9)
    (set-face-attribute 'mode-line-inactive nil
			:height 0.9)))

;; Use linum-mode for versions before 29.1
(use-package display-line-numbers
  :if (not (version< emacs-version "29"))
  :hook ((prog-mode . (lambda () (display-line-numbers-mode 1)))
	 (text-mode . (lambda () (display-line-numbers-mode -1)))))

(use-package eros
  :demand t
  :config
  (defun edebug-compute-previous-result (previous-value)
    (if edebug-unwrap-results
	(setq previous-value
              (edebug-unwrap* previous-value)))
    (setq edebug-previous-result
          (concat "Result: "
                  (edebug-safe-prin1-to-string previous-value)
                  (eval-expression-print-format previous-value))))

  (defun edebug-previous-result ()
    "Print the previous result."
    (interactive)
    (message "%s" edebug-previous-result))

  (defun adviced:edebug-compute-previous-result (_ &rest r)
    "Adviced `edebug-compute-previous-result'."
    (let ((previous-value (nth 0 r)))
      (if edebug-unwrap-results
          (setq previous-value
		(edebug-unwrap* previous-value)))
      (setq edebug-previous-result
            (edebug-safe-prin1-to-string previous-value))))

  (advice-add #'edebug-compute-previous-result
              :around
              #'adviced:edebug-compute-previous-result)

  (defun adviced:edebug-previous-result (_ &rest r)
    "Adviced `edebug-previous-result'."
    (eros--make-result-overlay edebug-previous-result
      :where (point)
      :duration eros-eval-result-duration))

  (advice-add #'edebug-previous-result
              :around
              #'adviced:edebug-previous-result)

  (eros-mode))

(use-package faces)

;; `initial-frame-alist' and `default-frame-alist' should be set in early-init.el
(use-package frame)

(use-package ligature
  :config
  ;; Enable the "www" ligature in every possible major mode
  (ligature-set-ligatures 't '("www"))
  ;; Enable traditional ligature support in eww-mode, if the
  ;; `variable-pitch' face supports it
  (ligature-set-ligatures 'eww-mode '("ff" "fi" "ffi"))
  ;; Enable all Cascadia and Fira Code ligatures in programming modes
  (ligature-set-ligatures 'prog-mode
                          '(;; == === ==== => =| =>>=>=|=>==>> ==< =/=//=// =~
                            ;; =:= =!=
                            ("=" (rx (+ (or ">" "<" "|" "/" "~" ":" "!" "="))))
                            ;; ;; ;;;
                            (";" (rx (+ ";")))
                            ;; && &&&
                            ("&" (rx (+ "&")))
                            ;; !! !!! !. !: !!. != !== !~
                            ("!" (rx (+ (or "=" "!" "\." ":" "~"))))
                            ;; ?? ??? ?:  ?=  ?.
                            ("?" (rx (or ":" "=" "\." (+ "?"))))
                            ;; %% %%%
                            ("%" (rx (+ "%")))
                            ;; |> ||> |||> ||||> |] |} || ||| |-> ||-||
                            ;; |->>-||-<<-| |- |== ||=||
                            ;; |==>>==<<==<=>==//==/=!==:===>
                            ("|" (rx (+ (or ">" "<" "|" "/" ":" "!" "}" "\]"
                                            "-" "=" ))))
                            ;; \\ \\\ \/
                            ("\\" (rx (or "/" (+ "\\"))))
                            ;; ++ +++ ++++ +>
                            ("+" (rx (or ">" (+ "+"))))
                            ;; :: ::: :::: :> :< := :// ::=
                            (":" (rx (or ">" "<" "=" "//" ":=" (+ ":"))))
                            ;; // /// //// /\ /* /> /===:===!=//===>>==>==/
                            ("/" (rx (+ (or ">"  "<" "|" "/" "\\" "\*" ":" "!"
                                            "="))))
                            ;; .. ... .... .= .- .? ..= ..<
                            ("\." (rx (or "=" "-" "\?" "\.=" "\.<" (+ "\."))))
                            ;; -- --- ---- -~ -> ->> -| -|->-->>->--<<-|
                            ("-" (rx (+ (or ">" "<" "|" "~" "-"))))
                            ;; *> */ *)  ** *** ****
                            ("*" (rx (or ">" "/" ")" (+ "*"))))
                            ;; www wwww
                            ("w" (rx (+ "w")))
                            ;; <> <!-- <|> <: <~ <~> <~~ <+ <* <$ </  <+> <*>
                            ;; <$> </> <|  <||  <||| <|||| <- <-| <-<<-|-> <->>
                            ;; <<-> <= <=> <<==<<==>=|=>==/==//=!==:=>
                            ;; << <<< <<<<
                            ("<" (rx (+ (or "\+" "\*" "\$" "<" ">" ":" "~"  "!"
                                            "-"  "/" "|" "="))))
                            ;; >: >- >>- >--|-> >>-|-> >= >== >>== >=|=:=>>
                            ;; >> >>> >>>>
                            (">" (rx (+ (or ">" "<" "|" "/" ":" "=" "-"))))
                            ;; #: #= #! #( #? #[ #{ #_ #_( ## ### #####
                            ("#" (rx (or ":" "=" "!" "(" "\?" "\[" "{" "_(" "_"
					 (+ "#"))))
                            ;; ~~ ~~~ ~=  ~-  ~@ ~> ~~>
                            ("~" (rx (or ">" "=" "-" "@" "~>" (+ "~"))))
                            ;; __ ___ ____ _|_ __|____|_
                            ("_" (rx (+ (or "_" "|"))))
                            ;; Fira code: 0xFF 0x12
                            ("0" (rx (and "x" (+ (in "A-F" "a-f" "0-9")))))
                            ;; Fira code:
                            "Fl"  "Tl"  "fi"  "fj"  "fl"  "ft"
                            ;; The few not covered by the regexps.
                            "{|"  "[|"  "]#"  "(*"  "}#"  "$>"  "^="))
  ;; Enables ligature checks globally in all buffers. You can also do it
  ;; per mode with `ligature-mode'.
  (global-ligature-mode t))

;; Starting at emacs 29.1, use display-line-numbers-mode
(use-package linum
  :if (version< emacs-version "29.1")
  :init
  (add-hook 'prog-mode-hook #'(lambda () (linum-mode 1)))
  (add-hook 'text-mode-hook #'(lambda () (linum-mode -1))))

(use-package moody
  :demand t
  :hook ((buffer-list-update . nol/update-all))
  :init
  ;; Not sure if still necessary
  (defun nol/update-all ()
    (force-mode-line-update t))
  :config
  (setq-default moody-mode-line-buffer-identification
                '( :eval (moody-tab (car (nol/propertized-buffer-identification "%b"))
				    20 'down)))

  (defun nol/moody-mode-line-height ()
    (+ 3 (frame-char-height)))

  (setq moody-mode-line-height 'nol/moody-mode-line-height
	x-underline-at-descent-line t)
  (moody-replace-mode-line-buffer-identification)
  (moody-replace-vc-mode)
  (moody-replace-eldoc-minibuffer-message-function))

(use-package nerd-icons
  :config
  ;; Used by `nerd-icons-completion' and `nerd-icons-dired'.
  (setq nerd-icons-font-family "FiraCode Nerd Font"))

(use-package nerd-icons-completion
  :unless (string= (tty-type) "linux")	; Those icons can't be displayed on TTYs.
  :demand t
  :custom
  ;; Having the same icon for all items is useless. Though it is useful for buffer
  ;; selection. Use `nf-cod-blank' to have the same alignment between buffer
  ;; selection and the other categories.
  (nerd-icons-completion-category-icons
   '((command nerd-icons-codicon "nf-cod-blank" nerd-icons-blue)
     (theme nerd-icons-codicon "nf-cod-blank" nerd-icons-yellow)
     (symbol nerd-icons-codicon "nf-cod-blank" nerd-icons-dblue)
     (variable nerd-icons-codicon "nf-cod-blank" nerd-icons-lpurple)
     (function nerd-icons-codicon "nf-cod-blank" nerd-icons-blue)
     (package nerd-icons-codicon "nf-cod-blank" nerd-icons-orange)
     (symbol-help nerd-icons-codicon "nf-cod-blank" nerd-icons-lpurple)
     (face nerd-icons-codicon "nf-cod-blank" nerd-icons-pink)
     (input-method nerd-icons-codicon "nf-cod-blank" nerd-icons-blue-alt)
     (org-roam-node nerd-icons-codicon "nf-cod-blank" nerd-icons-silver)
     (imenu nerd-icons-codicon "nf-cod-blank" nerd-icons-lblue)
     (kill-ring nerd-icons-codicon "nf-cod-blank" nerd-icons-silver)
     (coding-system nerd-icons-codicon "nf-cod-blank" nerd-icons-lpurple)
     (library nerd-icons-codicon "nf-cod-blank" nerd-icons-lpurple)
     (nil nerd-icons-codicon "nf-cod-blank" nerd-icons-silver)))
  :config
  (nerd-icons-completion-mode))

(use-package nerd-icons-dired
  :unless (string= (tty-type) "linux")	; Those icons can't be displayed on TTYs.
  :demand t
  :hook ((dired-mode . (lambda ()
			 (unless (file-remote-p dired-directory)
			   (nerd-icons-dired-mode)))))
  :init
  (add-to-list 'mode-line-collapse-minor-modes 'nerd-icons-dired-mode))

(use-package prism
  :demand t
  :after modus-themes
  :hook
  ((emacs-lisp-mode . prism-mode)
   (lisp-interaction-mode . prism-mode)
   (modus-themes-after-load-theme .
				  (lambda ()
				    (prism-set-colors
				      :desaturations '(0) ; do not change---may lower the contrast ratio
				      :lightens '(0)      ; same
				      :colors (modus-themes-with-colors
						(list blue
						      magenta
						      magenta-cooler
						      cyan-cooler
						      fg-main
						      blue-warmer
						      red-cooler
						      cyan))))))
  :config
  (setq prism-num-faces 8
	prism-parens nil))

(use-package shrface
  :disabled t
  :after eww
  :bind (:map shrface-mode-map
	      (("C-c C-p" . shrface-previous-headline)
	       ("C-c C-n" . shrface-next-headline)
	       ("TAB" . shrface-outline-cycle)))
  :hook ((eww-mode . shrface-mode))
  :config
  (shrface-basic)
  (shrface-trial)
  (setq shrface-href-versatile t))

(use-package spacious-padding
  :demand t
  :custom
  (spacious-padding-widths '( :internal-border-width 5
			      :header-line-width 4
			      :mode-line-width 2
			      :tab-width 10
			      :right-divider-width 10
			      :scroll-bar-width 8
			      :fringe-width 2))
  :custom
  (spacious-padding-mode 1))

(provide 'init-ui)

;;; init-ui.el ends here
