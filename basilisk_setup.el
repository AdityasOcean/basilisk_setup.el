;;; basilisk_setup.el --- Comprehensive Basilisk enhancements for C mode
;; Author: Arun K Eswara, eswara.arun@gmail.com
;; Version: 1.12
;; Date: 28th February 2025
;;; Commentary:
;; This package provides extensive syntax highlighting, editing features,
;; and compilation support for Basilisk CFD code, with a focus on MPI
;; and parallel constructs. Enhanced based on official documentation
;; from http://basilisk.fr/. Runs commands through a shell interpreter.

;;; Code:

(require 'cc-mode)
(require 'compile)  ; Ensure compilation-mode is available
(require 'easymenu)  ; Required for menu definition

;;; =========================================================
;;; Comprehensive Basilisk keywords, organized by category
;;; =========================================================

(defvar basilisk-control-keywords
  '("event" "foreach" "foreach_face" "foreach_boundary" "foreach_vertex"
    "foreach_dimension" "foreach_level" "foreach_leaf" "foreach_neighbor"
    "foreach_cell" "foreach_child"
    "foreach_process" "foreach_tile" "foreach_thread" "foreach_reduction"
    "foreach_shared" "foreach_block" "foreach_partition" "foreach_slice"
    "break" "continue" "return")
  "Basilisk control flow keywords.")

(defvar basilisk-mpi-keywords
  '("MPI_Allreduce" "MPI_Barrier" "MPI_Bcast" "MPI_Comm" "MPI_Comm_rank"
    "MPI_Comm_size" "MPI_Finalize" "MPI_Gather" "MPI_Gatherv" "MPI_Init"
    "MPI_Recv" "MPI_Reduce" "MPI_Scatter" "MPI_Send" "MPI_Datatype"
    "MPI_INT" "MPI_FLOAT" "MPI_DOUBLE" "MPI_COMM_WORLD"
    "mpi_all_reduce" "mpi_all_reduce_array" "mpi_boundary_update"
    "mpi_boundary_refine" "mpi_boundary_coarsen" "mpi_boundary_iterate"
    "mpi_sync" "mpi_distribute" "mpi_collect" "mpi_allreduce"
    "mpi_broadcast" "mpi_gather" "mpi_waitall" "mpi_no_neighbours")
  "MPI-related keywords and functions in Basilisk.")

(defvar basilisk-types
  '("face" "vector" "scalar" "coord" "vertex" "matrix" "point"
    "Cell" "position" "norm" "Location" "Point" "Grid" "Boundary"
    "face vector" "face scalar" "vertex scalar" "vertex vector"
    "Vector" "Tensor" "Metrics" "Data" "Array"
    "grid" "multigrid" "cartesian" "quadtree" "octree" "adaptive" "periodic"
    "Tree" "Quadtree" "Octree" "Refinement")
  "Basilisk type names.")

(defvar basilisk-constants
  '("PI" "M_PI" "true" "false" "TRUE" "FALSE" "NULL"
    "MPI_SUCCESS" "MPI_ERROR" "MPI_ANY_SOURCE" "MPI_ANY_TAG"
    "MPI_TAG_UB" "MPI_UNDEFINED" "pid()" "npe()" "MPI_STATUS_SIZE")
  "Standard Basilisk and MPI constants.")

(defvar basilisk-functions
  '("solve" "restriction" "prolongation" "refine" "unrefine" "adapt"
    "adapt_wavelet" "run" "init_grid" "init_flow" "output"
    "pid" "npe" "rank" "synchronize" "barrier" "broadcast"
    "reduce" "gather" "scatter" "distribute" "collect")
  "Standard Basilisk functions and macros.")

(defvar basilisk-variables
  '("f" "u" "p" "rho" "mu" "g" "dt" "Delta" "x" "y" "z" "G" "t" "level" "depth"
    "force_x" "force_y" "force_z" "moment" "velocity" "acceleration" "position"
    "dx" "dy" "dz" "nx" "ny" "nz" "coord" "origin" "mass" "energy" "momentum"
    "face vector" "face scalar" "vertex scalar" "vertex vector"
    "face gradient" "normal" "tangent" "volume" "area" "mass")
  "Common Basilisk variables and fields.")

(defvar basilisk-preprocessor
  '("#include" "#if" "#undef" "#define" "#endif" "#else" "#elif" "#pragma"
    "_MPI" "_OPENMP" "_CADNA" "LAYERS" "BGHOSTS" "BASILISK")
  "Basilisk preprocessor directives and symbols.")

(defvar basilisk-grid-directives
  '("grid/multigrid.h" "grid/quadtree.h" "grid/octree.h" "grid/cartesian.h"
    "grid/bitree.h" "grid/multigrid1D.h" "grid/multigrid3D.h"
    "grid/tree.h" "grid/balance.h" "grid/adaptive.h" "grid/neighbors.h")
  "Basilisk grid directives and includes.")

(defvar basilisk-modules
  '("navier-stokes/centered.h" "two-phase.h" "tension.h"
    "navier-stokes/mac.h" "vof.h" "diffusion.h" "poisson.h"
    "embed.h" "curvature.h" "reduced.h" "tracer.h"
    "particles.h" "view.h" "output.h" "grid/refinement.h"
    "run.h" "utils.h" "fpe.h" "profile.h" "grid/multigrid.h")
  "Common Basilisk modules and includes.")

(defvar basilisk-mpi-reduction-patterns
  '("foreach_reduction" "foreach_leaf_reduction" "reduction" "reduction\\("
    "mpi_all_reduce" "MPI_Allreduce" "MPI_Reduce"
    "foreach[[:space:]]+\\(reduction" "foreach_cell[[:space:]]+\\(reduction"
    "foreach_face[[:space:]]+\\(reduction" "foreach_vertex[[:space:]]+\\(reduction"
    "\\+=" "\\*=" "min=" "max=" "reduction\\(\\+\\)" "reduction\\(\\*\\)"
    "reduction\\(min\\)" "reduction\\(max\\)")
  "Patterns for MPI reductions and parallel operations in Basilisk.")

(defvar basilisk-multiline-patterns
  '(("\\<event\\>[[:space:]]+\\(\\sw+\\)[[:space:]]*(\\(.*?\\))"
     (1 font-lock-function-name-face)
     (2 font-lock-string-face))
    ("\\<\\(\\sw+\\)[[:space:]]*\\((.*?)\\)[[:space:]]*{"
     (1 font-lock-function-name-face))
    ("\\<typedef[[:space:]]+struct[[:space:]]+\\(\\sw+\\)"
     (1 font-lock-type-face))
    ("\\<foreach[_a-z]*[[:space:]]+\\(reduction[[:space:]]*(\\([^)]+\\))\\)"
     (1 font-lock-preprocessor-face)
     (2 font-lock-variable-name-face)))
  "Multiline patterns for Basilisk code constructs.")

;; Define the keymap for basilisk-mode
(defvar basilisk-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c e") 'basilisk-insert-event)
    (define-key map (kbd "C-c f") 'basilisk-insert-foreach)
    (define-key map (kbd "C-c a") 'basilisk-insert-foreach-face)
    (define-key map (kbd "C-c r") 'basilisk-insert-foreach-reduction)
    (define-key map (kbd "C-c m") 'basilisk-insert-mpi-function)
    (define-key map (kbd "C-c i") 'basilisk-insert-main)
    (define-key map (kbd "C-c o") 'basilisk-insert-main-mpi)
    (define-key map (kbd "C-c s") 'basilisk-insert-struct)
    (define-key map (kbd "C-c v") 'basilisk-insert-solver)
    (define-key map (kbd "C-c c") 'basilisk-compile-command-generator)
    (define-key map (kbd "C-c x") 'basilisk-run)
    (define-key map (kbd "C-c z") 'basilisk-compile-and-run)
    (define-key map (kbd "C-c d") 'basilisk-browse-documentation)
    (define-key map (kbd "C-c h") 'basilisk-show-compilation-help)
    (define-key map (kbd "C-c C-f") 'basilisk-find-event-definition)
    (define-key map (kbd "C-c C-t") 'basilisk-toggle-mpi)
    map)
  "Keymap for basilisk-mode.")

;;; =========================================================
;;; Enhanced font-lock and syntax highlighting
;;; =========================================================

(defun basilisk-setup-font-lock ()
  "Set up comprehensive font-lock for Basilisk code in C mode."
  (font-lock-add-keywords
   nil
   `((,(regexp-opt basilisk-control-keywords 'words) . font-lock-keyword-face)
     (,(regexp-opt basilisk-mpi-keywords 'words) . font-lock-builtin-face)
     (,(regexp-opt basilisk-types 'words) . font-lock-type-face)
     (,(regexp-opt basilisk-constants 'words) . font-lock-constant-face)
     (,(regexp-opt basilisk-functions 'words) . font-lock-function-name-face)
     (,(regexp-opt basilisk-variables 'words) . font-lock-variable-name-face)
     (,(regexp-opt basilisk-preprocessor 'words) . font-lock-preprocessor-face)
     ("\\<event\\>[[:space:]]+\\(\\sw+\\)"
      (1 font-lock-function-name-face))
     ("\\<\\(t[[:space:]]*+=\\|t[[:space:]]*=\\)[[:space:]]*\\([^;{]+\\)"
      (2 font-lock-string-face))
     ,@(mapcar (lambda (pattern)
                 `(,pattern . font-lock-warning-face))
               basilisk-mpi-reduction-patterns)
     ("\\(\\w+\\)\\(\\[\\]\\)"
      (1 font-lock-variable-name-face))
     ("\\(\\w+\\)\\(\\[[xyz]\\]\\)"
      (1 font-lock-variable-name-face)
      (2 font-lock-constant-face))
     (,(concat "#include[[:space:]]+\"\\("
               (regexp-opt basilisk-grid-directives)
               "\\)\"")
      (1 font-lock-string-face t))
     (,(concat "#include[[:space:]]+\"\\("
               (regexp-opt basilisk-modules)
               "\\)\"")
      (1 font-lock-string-face t))))
  (font-lock-flush))

;;; =========================================================
;;; Enhanced code templates and snippets
;;; =========================================================

(defun basilisk-insert-event ()
  "Insert an event block template."
  (interactive)
  (let ((event-name (read-string "Event name: "))
        (event-time (read-string "Event time (e.g., t = 0): ")))
    (insert (format "event %s (%s) {\n  \n}\n" event-name event-time))
    (forward-line -2)
    (c-indent-line)))

(defun basilisk-insert-foreach ()
  "Insert a foreach loop template."
  (interactive)
  (insert "foreach() {\n  \n}")
  (forward-line -1)
  (c-indent-line))

(defun basilisk-insert-foreach-face ()
  "Insert a foreach_face loop template."
  (interactive)
  (let ((direction (read-string "Direction (x/y/z): ")))
    (insert (format "foreach_face(%s) {\n  \n}" direction))
    (forward-line -1)
    (c-indent-line)))

(defun basilisk-insert-foreach-reduction ()
  "Insert a foreach reduction loop template."
  (interactive)
  (let ((var (read-string "Reduction variable: "))
        (op (completing-read "Reduction operator: " '("+" "*" "min" "max"))))
    (insert (format "foreach (reduction(%s:%s)) {\n  %s %s= ...\n}"
                    op var var op))
    (forward-line -1)
    (end-of-line)
    (backward-char 3)
    (c-indent-line)))

(defun basilisk-insert-mpi-function ()
  "Insert an MPI function template."
  (interactive)
  (let ((func-type (completing-read "MPI Function type: "
                                    '("Allreduce" "Bcast" "Send/Recv" "Gather" "Scatter"))))
    (cond
     ((string= func-type "Allreduce")
      (insert "mpi_all_reduce(local_value, MPI_DOUBLE, MPI_SUM);"))
     ((string= func-type "Bcast")
      (insert "MPI_Bcast(&value, 1, MPI_DOUBLE, 0, MPI_COMM_WORLD);"))
     ((string= func-type "Send/Recv")
      (insert "if (pid() == 0) {\n  MPI_Send(&value, 1, MPI_DOUBLE, 1, 0, MPI_COMM_WORLD);\n} else {\n  MPI_Recv(&value, 1, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);\n}"))
     ((string= func-type "Gather")
      (insert "MPI_Gather(&local_value, 1, MPI_DOUBLE, all_values, 1, MPI_DOUBLE, 0, MPI_COMM_WORLD);"))
     ((string= func-type "Scatter")
      (insert "MPI_Scatter(all_values, 1, MPI_DOUBLE, &local_value, 1, MPI_DOUBLE, 0, MPI_COMM_WORLD);")))))

(defun basilisk-insert-main ()
  "Insert a main function template for Basilisk."
  (interactive)
  (insert "int main() {\n  init_grid (N);\n  run();\n  return 0;\n}")
  (forward-line -3)
  (c-indent-line))

(defun basilisk-insert-main-mpi ()
  "Insert a main function template with MPI initialization."
  (interactive)
  (insert "int main(int argc, char * argv[]) {\n  MPI_Init(&argc, &argv);\n  init_grid (N);\n  run();\n  MPI_Finalize();\n  return 0;\n}")
  (forward-line -4)
  (c-indent-line))

(defun basilisk-insert-struct ()
  "Insert a struct template."
  (interactive)
  (let ((struct-name (read-string "Struct name: ")))
    (insert (format "typedef struct {\n  double x, y, z;\n} %s;\n" struct-name))
    (forward-line -2)
    (c-indent-line)))

(defun basilisk-insert-solver ()
  "Insert a basic solver template."
  (interactive)
  (insert "scalar p[];\nvector u[];\n\ndiffusion (p, dt, u);\n")
  (c-indent-region (mark) (point)))

;;; =========================================================
;;; Enhanced compilation and execution methods
;;; =========================================================

(defvar basilisk-compilation-methods
  '(("Basic (No MPI)" . "qcc -Wall -O2 %s -o %s -lm")
    ("Optimized (No MPI)" . "qcc -Wall -O2 %s -o %s -lm")
    ("Debug (No MPI)" . "qcc -Wall -g -O0 %s -o %s -lm")
    ("Makefile (No MPI)" . "make %s.tst")
    ("MPI Manual" . "CC99='mpicc -std=c99' qcc -Wall -O2 -D_MPI=%d %s -o %s -lm")
    ("MPI with Makefile" . "export CC='mpicc -D_MPI=%d'; make %s.tst")
    ("MPI Portable Source" . "qcc -source -D_MPI=%d %s && mpicc -Wall -std=c99 -O2 -D_MPI=%d _%s -o %s -lm"))
  "List of compilation methods for Basilisk code. First %s is source (with .c), second %s is output, %d is for MPI processes.")

(defvar basilisk-run-methods
  '(("Basic (No MPI)" . "./%s")
    ("Valgrind (No MPI)" . "valgrind --leak-check=full ./%s")
    ("MPI" . "mpirun --oversubscribe -np %d ./%s")
    ("MPI with Slurm" . "srun -n %d ./%s"))
  "List of run methods for Basilisk code. %s is output filename, %d is for MPI processes.")

(defun basilisk-get-base-filename ()
  "Get the base filename without extension, or prompt to save if nil."
  (interactive)
  (let ((filename (buffer-file-name)))
    (if filename
        (file-name-base filename)
      (progn
        (when (called-interactively-p 'interactive)
          (message "Buffer has no file; please save it first.")
          (call-interactively 'save-buffer))
        (file-name-base (buffer-file-name))))))

(defun basilisk-get-source-filename ()
  "Get the full source filename with extension, or prompt to save if nil."
  (interactive)
  (let ((filename (buffer-file-name)))
    (if filename
        (file-name-nondirectory filename)  ; Keep extension
      (progn
        (when (called-interactively-p 'interactive)
          (message "Buffer has no file; please save it first.")
          (call-interactively 'save-buffer))
        (file-name-nondirectory (buffer-file-name))))))

(defun basilisk-get-output-filename ()
  "Get the output filename based on the source file."
  (interactive)
  (let ((filename (buffer-file-name)))
    (if filename
        (file-name-base filename)
      (progn
        (when (called-interactively-p 'interactive)
          (message "Buffer has no file; please save it first.")
          (call-interactively 'save-buffer))
        (file-name-base (buffer-file-name))))))

(defun basilisk-copy-to-clipboard (text)
  "Copy TEXT to the system clipboard if possible."
  (cond
   ((fboundp 'gui-set-selection) (gui-set-selection 'CLIPBOARD text))
   ((fboundp 'x-set-selection) (x-set-selection 'CLIPBOARD text))
   (t (message "Clipboard not supported; command printed to *Messages* only: %s" text))))

(defun basilisk-is-mpi-method (method-name)
  "Check if METHOD-NAME is an MPI compilation or run method."
  (and (string-match "MPI" method-name)
       (not (string-match "No MPI" method-name))))

(defun basilisk-compile-command-generator ()
  "Generate and execute a compile command for the current Basilisk file via shell."
  (interactive)
  (unless (buffer-file-name)
    (message "No file associated with buffer; saving now...")
    (call-interactively 'save-buffer))
  (let* ((src-file (or (buffer-file-name) (error "No file to compile; please save the buffer")))
         (source-name (basilisk-get-source-filename))  ; Full filename with .c
         (output-name (basilisk-get-output-filename))  ; Base name for output
         (compile-methods (mapcar #'car basilisk-compilation-methods))
         (compile-method (completing-read "Compilation method: " compile-methods nil t "Basic (No MPI)"))
         (compile-template (cdr (assoc compile-method basilisk-compilation-methods)))
         (default-directory (file-name-directory src-file))  ; Set working directory
         compile-cmd use-terminal shell-cmd)
    (message "Selected method: %s" compile-method)
    (if (basilisk-is-mpi-method compile-method)
        (let ((nproc (string-to-number (read-string "Number of MPI processes (1-200): " "1"))))
          (message "MPI mode: prompting for processes")
          (setq nproc (max 1 (min 200 nproc)))
          (cond
           ((string-match "MPI Portable Source" compile-method)
            (setq compile-cmd (format compile-template nproc source-name nproc (concat "_" output-name) output-name)))
           ((string-match "MPI with Makefile" compile-method)
            (setq compile-cmd (format compile-template nproc output-name)))
           (t
            (setq compile-cmd (format compile-template nproc source-name output-name)))))
      (progn
        (message "Non-MPI mode: no process prompt")
        (cond
         ((string-match "Makefile" compile-method)
          (setq compile-cmd (format compile-template output-name)))
         (t
          (setq compile-cmd (format compile-template source-name output-name))))))
    (setq shell-cmd (format "bash -c \"source ~/.bashrc && %s\"" compile-cmd))
    (message "Generated compile command: %s" compile-cmd)
    (setq use-terminal (y-or-n-p "Run in terminal instead of Emacs? "))
    (if use-terminal
        (progn
          (basilisk-copy-to-clipboard compile-cmd)
          (message "Command copied to clipboard: %s. Paste it into your terminal." compile-cmd))
      (progn
        (compile shell-cmd)
        (with-current-buffer "*compilation*"
          (compilation-mode)
          (when (and (boundp 'compilation-exit-code) (= compilation-exit-code 127))
            (message "Compilation failed (e.g., mpicc not found). Command copied to clipboard: %s" compile-cmd)
            (basilisk-copy-to-clipboard compile-cmd)))))))

(defun basilisk-run ()
  "Run the compiled Basilisk program via shell."
  (interactive)
  (unless (buffer-file-name)
    (message "No file associated with buffer; saving now...")
    (call-interactively 'save-buffer))
  (let* ((src-file (or (buffer-file-name) (error "No file to run; please save the buffer")))
         (output-name (basilisk-get-output-filename))  ; Base name for output
         (run-methods (mapcar #'car basilisk-run-methods))
         (run-method (completing-read "Run method: " run-methods nil t "Basic (No MPI)"))
         (run-template (cdr (assoc run-method basilisk-run-methods)))
         (default-directory (file-name-directory src-file))  ; Set working directory
         run-cmd use-terminal shell-cmd)
    (if (basilisk-is-mpi-method run-method)
        (let ((nproc (string-to-number (read-string "Number of MPI processes (1-200): " "1"))))
          (setq nproc (max 1 (min 200 nproc)))
          (setq run-cmd (format run-template nproc output-name)))
      (setq run-cmd (format run-template output-name)))
    (setq shell-cmd (format "bash -c \"source ~/.bashrc && %s\"" run-cmd))
    (message "Generated run command: %s" run-cmd)
    (setq use-terminal (y-or-n-p "Run in terminal instead of Emacs? "))
    (if use-terminal
        (progn
          (basilisk-copy-to-clipboard run-cmd)
          (message "Command copied to clipboard: %s. Paste it into your terminal." run-cmd))
      (progn
        (compile shell-cmd)
        (with-current-buffer "*compilation*"
          (compilation-mode)
          (when (and (boundp 'compilation-exit-code) (= compilation-exit-code 127))
            (message "Run failed (e.g., mpirun not found). Command copied to clipboard: %s" run-cmd)
            (basilisk-copy-to-clipboard run-cmd)))))))

(defun basilisk-compile-and-run ()
  "Compile and then run the Basilisk program via shell."
  (interactive)
  (unless (buffer-file-name)
    (message "No file associated with buffer; saving now...")
    (call-interactively 'save-buffer))
  (let* ((src-file (or (buffer-file-name) (error "No file to compile; please save the buffer")))
         (source-name (basilisk-get-source-filename))  ; Full filename with .c
         (output-name (basilisk-get-output-filename))  ; Base name for output
         (compile-methods (mapcar #'car basilisk-compilation-methods))
         (run-methods (mapcar #'car basilisk-run-methods))
         (compile-method (completing-read "Compilation method: " compile-methods nil t "Basic (No MPI)"))
         (run-method (completing-read "Run method: " run-methods nil t "Basic (No MPI)"))
         (compile-template (cdr (assoc compile-method basilisk-compilation-methods)))
         (run-template (cdr (assoc run-method basilisk-run-methods)))
         (default-directory (file-name-directory src-file))  ; Set working directory
         compile-cmd run-cmd use-terminal shell-cmd)
    (message "Selected compile method: %s" compile-method)
    (if (basilisk-is-mpi-method compile-method)
        (let ((nproc (string-to-number (read-string "Number of MPI processes (1-200): " "1"))))
          (message "MPI mode: prompting for processes")
          (setq nproc (max 1 (min 200 nproc)))
          (cond
           ((string-match "MPI Portable Source" compile-method)
            (setq compile-cmd (format compile-template nproc source-name nproc (concat "_" output-name) output-name)))
           ((string-match "MPI with Makefile" compile-method)
            (setq compile-cmd (format compile-template nproc output-name)))
           (t
            (setq compile-cmd (format compile-template nproc source-name output-name)))))
      (progn
        (message "Non-MPI mode: no process prompt")
        (cond
         ((string-match "Makefile" compile-method)
          (setq compile-cmd (format compile-template output-name)))
         (t
          (setq compile-cmd (format compile-template source-name output-name))))))
    (if (basilisk-is-mpi-method run-method)
        (let ((nproc (string-to-number (read-string "Number of MPI processes (1-200): " "1"))))
          (setq nproc (max 1 (min 200 nproc)))
          (setq run-cmd (format run-template nproc output-name)))
      (setq run-cmd (format run-template output-name)))
    (let ((full-cmd (format "%s && %s" compile-cmd run-cmd)))
      (setq shell-cmd (format "bash -c \"source ~/.bashrc && %s\"" full-cmd))
      (message "Generated compile-and-run command: %s" full-cmd)
      (setq use-terminal (y-or-n-p "Run in terminal instead of Emacs? "))
      (if use-terminal
          (progn
            (basilisk-copy-to-clipboard full-cmd)
            (message "Command copied to clipboard: %s. Paste it into your terminal." full-cmd))
        (progn
          (compile shell-cmd)
          (with-current-buffer "*compilation*"
            (compilation-mode)
            (when (and (boundp 'compilation-exit-code) (= compilation-exit-code 127))
              (message "Compile/run failed (e.g., mpicc/mpirun not found). Command copied to clipboard: %s" full-cmd)
              (basilisk-copy-to-clipboard full-cmd))))))))

;;; =========================================================
;;; Help and documentation
;;; =========================================================

(defun basilisk-browse-documentation ()
  "Open the Basilisk documentation in a web browser."
  (interactive)
  (let ((doc-type (completing-read "Documentation type: "
                                   '("Main" "Functions" "Examples" "Tutorial"))))
    (cond
     ((string= doc-type "Main")
      (browse-url "http://basilisk.fr/src/README"))
     ((string= doc-type "Functions")
      (browse-url "http://basilisk.fr/src/README"))
     ((string= doc-type "Examples")
      (browse-url "http://basilisk.fr/src/examples/"))
     ((string= doc-type "Tutorial")
      (browse-url "http://basilisk.fr/Tutorial")))))

(defun basilisk-show-compilation-help ()
  "Display help information about different compilation methods."
  (interactive)
  (with-output-to-temp-buffer "*Basilisk Compilation Help*"
    (princ "Basilisk Compilation Methods:\n\n")
    (princ "=== Without MPI ===\n")
    (princ "- Basic: qcc -Wall -O2 code.c -o code -lm\n")
    (princ "- Optimized: qcc -Wall -O2 code.c -o code -lm\n")
    (princ "- Debug: qcc -Wall -g -O0 code.c -o code -lm\n")
    (princ "- Makefile: make code.tst\n\n")
    (princ "=== With MPI ===\n")
    (princ "- Manual: CC99='mpicc -std=c99' qcc -Wall -O2 -D_MPI=n code.c -o code -lm\n")
    (princ "- Makefile: export CC='mpicc -D_MPI=n'; make code.tst\n")
    (princ "- Portable: qcc -source -D_MPI=n code.c && mpicc -Wall -std=c99 -O2 -D_MPI=n _code.c -o code -lm\n\n")
    (princ "=== Running ===\n")
    (princ "- Basic: ./code\n")
    (princ "- MPI: mpirun --oversubscribe -np n ./code\n")
    (princ "- Slurm: srun -n n ./code\n\n")
    (princ "Note: MPI process count (n) must match between compile and run time.\n")
    (princ "Commands run via 'bash -c \"source ~/.bashrc && ...\"' in *compilation* buffer by default.\n")
    (princ "Choose terminal to copy to clipboard instead.\n")
    (princ "See http://basilisk.fr/src/Tips for more details.")))

;;; =========================================================
;;; Advanced Navigation and Refactoring
;;; =========================================================

(defun basilisk-find-event-definition ()
  "Find the definition of the event at point."
  (interactive)
  (let ((event-name (thing-at-point 'symbol)))
    (when event-name
      (let ((regexp (format "event[[:space:]]+%s[[:space:]]*(.*)" event-name)))
        (if (re-search-backward regexp nil t)
            (message "Found event: %s" event-name)
          (if (re-search-forward regexp nil t)
              (message "Found event: %s" event-name)
            (message "Event not found: %s" event-name)))))))

(defun basilisk-toggle-mpi ()
  "Toggle MPI-related preprocessor directives in the current buffer."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (if (re-search-forward "#define[[:space:]]+_MPI" nil t)
        (progn
          (replace-match "// #define _MPI")
          (message "MPI support disabled"))
      (if (re-search-forward "//[[:space:]]*#define[[:space:]]+_MPI" nil t)
          (progn
            (replace-match "#define _MPI")
            (message "MPI support enabled"))
        (goto-char (point-min))
        (if (re-search-forward "#include" nil t)
            (progn
              (beginning-of-line)
              (insert "#define _MPI\n")
              (message "MPI support added"))
          (insert "#define _MPI\n")
          (message "MPI support added"))))))

;;; =========================================================
;;; Setup and integration - TRADITIONAL APPROACH 
;;; =========================================================

;; Define basilisk-menu only once
(defvar basilisk-menu nil
  "Menu for Basilisk mode commands.")

;; Set up indentation
(defun basilisk-setup-indentation ()
  "Set up indentation for Basilisk code."
  (setq c-basic-offset 2)
  (c-set-offset 'substatement-open 0)
  (c-set-offset 'statement-cont 'c-lineup-math)
  (c-set-offset 'innamespace 0)
  (c-set-offset 'case-label '+)
  (c-set-offset 'access-label '-))

;; Set up keybindings
(defun basilisk-setup-keybindings ()
  "Apply keybindings from basilisk-mode-map to the current buffer."
  (let ((map (current-local-map)))
    (define-key map (kbd "C-c e") 'basilisk-insert-event)
    (define-key map (kbd "C-c f") 'basilisk-insert-foreach)
    (define-key map (kbd "C-c a") 'basilisk-insert-foreach-face)
    (define-key map (kbd "C-c r") 'basilisk-insert-foreach-reduction)
    (define-key map (kbd "C-c m") 'basilisk-insert-mpi-function)
    (define-key map (kbd "C-c i") 'basilisk-insert-main)
    (define-key map (kbd "C-c o") 'basilisk-insert-main-mpi)
    (define-key map (kbd "C-c s") 'basilisk-insert-struct)
    (define-key map (kbd "C-c v") 'basilisk-insert-solver)
    (define-key map (kbd "C-c c") 'basilisk-compile-command-generator)
    (define-key map (kbd "C-c x") 'basilisk-run)
    (define-key map (kbd "C-c z") 'basilisk-compile-and-run)
    (define-key map (kbd "C-c d") 'basilisk-browse-documentation)
    (define-key map (kbd "C-c h") 'basilisk-show-compilation-help)
    (define-key map (kbd "C-c C-f") 'basilisk-find-event-definition)
    (define-key map (kbd "C-c C-t") 'basilisk-toggle-mpi)))

;;;###autoload
(defun basilisk-setup ()
  "Set up C mode for editing Basilisk files."
  (interactive)
  (when (derived-mode-p 'c-mode)
    ;; Setup features
    (basilisk-setup-font-lock)
    (basilisk-setup-indentation)
    (basilisk-setup-keybindings)
    
    ;; Define the menu - must be INSIDE this function to work properly
    (easy-menu-define basilisk-menu (current-local-map) "Basilisk Commands"
      '("Basilisk"
        ["Insert Event Block" basilisk-insert-event t]
        ["Insert Foreach Loop" basilisk-insert-foreach t]
        ["Insert Foreach_face Loop" basilisk-insert-foreach-face t]
        ["Insert Foreach Reduction" basilisk-insert-foreach-reduction t]
        ["Insert MPI Function" basilisk-insert-mpi-function t]
        ["Insert Main Function" basilisk-insert-main t]
        ["Insert MPI Main Function" basilisk-insert-main-mpi t]
        ["Insert Struct" basilisk-insert-struct t]
        ["Insert Solver Template" basilisk-insert-solver t]
        "---"
        ["Compile with Options" basilisk-compile-command-generator t]
        ["Run Compiled Program" basilisk-run t]
        ["Compile and Run" basilisk-compile-and-run t]
        ["Toggle MPI Support" basilisk-toggle-mpi t]
        "---"
        ["Find Event Definition" basilisk-find-event-definition t]
        "---"
        ["Compilation Help" basilisk-show-compilation-help t]
        ["Browse Documentation" basilisk-browse-documentation t]))
    
    (message "Basilisk features enabled in C mode")))

;; Hook into C-mode
(add-hook 'c-mode-hook 'basilisk-setup)

;; Define a derived mode for standalone use
(define-derived-mode basilisk-mode c-mode "Basilisk"
  "Major mode for editing Basilisk CFD code files."
  (basilisk-setup-font-lock)
  (basilisk-setup-indentation)
  (basilisk-setup-keybindings)
  
  ;; Define menu for standalone mode
  (easy-menu-define basilisk-menu basilisk-mode-map "Basilisk Commands"
    '("Basilisk"
      ["Insert Event Block" basilisk-insert-event t]
      ["Insert Foreach Loop" basilisk-insert-foreach t]
      ["Insert Foreach_face Loop" basilisk-insert-foreach-face t]
      ["Insert Foreach Reduction" basilisk-insert-foreach-reduction t]
      ["Insert MPI Function" basilisk-insert-mpi-function t]
      ["Insert Main Function" basilisk-insert-main t]
      ["Insert MPI Main Function" basilisk-insert-main-mpi t]
      ["Insert Struct" basilisk-insert-struct t]
      ["Insert Solver Template" basilisk-insert-solver t]
      "---"
      ["Compile with Options" basilisk-compile-command-generator t]
      ["Run Compiled Program" basilisk-run t]
      ["Compile and Run" basilisk-compile-and-run t]
      ["Toggle MPI Support" basilisk-toggle-mpi t]
      "---"
      ["Find Event Definition" basilisk-find-event-definition t]
      "---"
      ["Compilation Help" basilisk-show-compilation-help t]
      ["Browse Documentation" basilisk-browse-documentation t]))
  
  (setq comment-start "// "
        comment-end "")
  (message "Basilisk mode enabled"))

;; Associate with file extensions
(add-to-list 'auto-mode-alist '("\\.c\\'" . c-mode))
(add-to-list 'auto-mode-alist '("\\.h\\'" . c-mode))

(provide 'basilisk_setup)

;;; basilisk_setup.el ends here
