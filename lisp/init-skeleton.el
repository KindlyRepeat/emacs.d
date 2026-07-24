;; -*- lexical-binding: t; -*-

(define-skeleton sh-skeleton
  "A skeleton for bash scripts"
  "Description: "
  "#!/usr/bin/env bash\n"
  "# ----------------------------------------------------------------------------\n"
  "# File:\t\t"
  (file-name-nondirectory (buffer-file-name)) "\n"
  "# Author:\t"
  (user-full-name) "\n"
  "# Date:\t\t"
  (format-time-string "%A, %e %B %Y.") "\n"
  "# Description:\t" str "\n"
  "# Usage:\t" "\n"
  "# ----------------------------------------------------------------------------\n\n")
(define-auto-insert '(sh-mode . "Sh skeleton") 'sh-skeleton)

(define-skeleton py-skeleton
  "A skeleton for python scripts"
  "Description: "
  "#!/usr/bin/env python3\n"
  "# ----------------------------------------------------------------------------\n"
  "# File:\t\t"
  (file-name-nondirectory (buffer-file-name)) "\n"
  "# Author:\t"
  (user-full-name) "\n"
  "# Date:\t\t"
  (format-time-string "%A, %e %B %Y.") "\n"
  "# Description:\t" str "\n"
  "# Usage:\t" "\n"
  "# ----------------------------------------------------------------------------\n\n")

(define-auto-insert '(python-mode . "Python skeleton") 'py-skeleton)
(auto-insert-mode)
(provide 'init-skeleton)
