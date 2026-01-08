(define non-nixos-gpu
  (service
   '(non-nixos-gpu)
   #:documentation
   "Install GPU drivers for running GPU accelerated programs from Nix."
   #:start
   (make-forkexec-constructor
    '("/run/current-system/profile/bin/ln" "-nsf" "@@env@@" "/run/opengl-driver"))
   #:stop
   (make-kill-destructor)
   #:one-shot? #t))

(register-services (list non-nixos-gpu))
(start-in-the-background '(non-nixos-gpu))
