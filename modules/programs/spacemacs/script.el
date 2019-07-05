(require 'which-key)
(defconst spacemacs-version "@version@" "Spacemacs version.")
(setq user-emacs-directory "./")
(load-file "./core/core-load-paths.el")
(require 'core-spacemacs)
(require 'core-configuration-layer)
(configuration-layer/initialize)
(defun configuration-layer//configure-packages (x) t)
(configuration-layer/sync 'no-install)

(defun printInfo (x)
  (format "%s" x ))

(defun printList (x)
  (if (cdr x) (concat (printInfo (car x)) "\n" (printList (cdr x))) (printInfo (car x))))

(write-region (printList configuration-layer--used-packages) nil "../packages.txt")
