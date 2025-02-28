```markdown
# Basilisk Mode for Emacs

`basilisk_setup.el` is a custom Emacs mode enhancing `cc-mode` for editing [Basilisk CFD](http://basilisk.fr/) code. Basilisk is a free software for solving partial differential equations on adaptive Cartesian meshes, and this mode provides syntax highlighting, code templates, and advanced compilation/run features tailored to its C-based syntax, including MPI support.

## Features

### Syntax Highlighting
- **Control Keywords**: Highlights Basilisk constructs like `event`, `foreach`, `foreach_face` in `font-lock-keyword-face`.
- **MPI Keywords**: Highlights MPI functions (e.g., `MPI_Allreduce`, `mpi_all_reduce`) in `font-lock-builtin-face`.
- **Types and Constants**: Marks Basilisk types (e.g., `scalar`, `vector`) and constants (e.g., `PI`, `MPI_INT`) appropriately.
- **Functions and Variables**: Highlights standard functions (e.g., `solve`, `adapt_wavelet`) and variables (e.g., `u`, `rho`).
- **Preprocessor Directives**: Highlights `#include`, `_MPI`, etc., with special patterns for grid/module includes.

### Code Templates
- Insert templates via keybindings or the "Basilisk" menu:
  - `C-c e`: `event` block.
  - `C-c f`: `foreach()` loop.
  - `C-c a`: `foreach_face(direction)` loop.
  - `C-c r`: `foreach (reduction(op:var))`.
  - `C-c m`: MPI functions (e.g., `MPI_Allreduce`).
  - `C-c i`: Basic `main()` function.
  - `C-c o`: MPI-enabled `main()`.
  - `C-c s`: `typedef struct`.
  - `C-c v`: Solver template (e.g., diffusion).

### Compilation and Execution
- **Flexible Compilation**: Supports multiple methods with proper `.c` extension handling:
  - Non-MPI: `qcc -Wall code.c -o code -lm`, optimized/debug variants, Makefile.
  - MPI: `CC99='mpicc -std=c99' qcc -Wall -O2 -D_MPI=n code.c -o code -lm` (1-200 processes), Makefile, portable source.
- **Run Options**: `C-c x` runs compiled programs:
  - `./code`, Valgrind, `mpirun --oversubscribe -np n ./code`, Slurm.
- **Dual-Mode Execution**:
  - **Emacs Mode**: Runs via `bash -c "source ~/.bashrc && ..."` in `*compilation*` buffer (`C-c c`, `C-c x`, `C-c z`).
    - Displays errors/warnings with navigation (`M-g n`, `M-g p`).
  - **Terminal Mode**: Copies command to clipboard for manual execution if "Run in terminal?" is answered "Yes".
- **Compile and Run**: `C-c z` combines compilation and execution in one step.

### Navigation and Refactoring
- **Find Event**: `C-c C-f` jumps to event definitions.
- **Toggle MPI**: `C-c C-t` enables/disables `#define _MPI`.

### Help and Documentation
- **Browse Docs**: `C-c d` opens Basilisk pages (Main, Functions, Examples, Tutorial).
- **Compilation Help**: `C-c h` shows method details in `*Basilisk Compilation Help*`.

### Integration
- **Keybindings**: `C-c` prefix for all commands (see below).
- **Menu**: "Basilisk" menu in the Emacs menu bar.
- **Indentation**: 2-space offset, Basilisk-friendly C style.

## Requirements

- **Emacs**: Version 24.3+ (tested on 29.1).
- **Basilisk**: `qcc` compiler in PATH.
- **MPI (Optional)**: `mpicc`, `mpirun` (e.g., OpenMPI) for MPI support, configured in `.bashrc`.
- **Shell**: Bash (for `bash -c` execution; modify `.bashrc` for environment setup).

## Installation

1. **Download**:
   - Save `basilisk_setup.el` to `~/.emacs.d/lisp/`:
     ```sh
     mkdir -p ~/.emacs.d/lisp/
     wget -O ~/.emacs.d/lisp/basilisk_setup.el <URL-to-file>
     ```

2. **Configure Emacs**:
   - Add to `~/.emacs` or `~/.emacs.d/init.el`:
     ```emacs-lisp
     (add-to-list 'load-path "~/.emacs.d/lisp/")
     (require 'basilisk_setup)
     ```
   - Or load manually: `M-x load-file RET ~/.emacs.d/lisp/basilisk_setup.el RET`.

3. **Verify**:
   - Restart Emacs or `M-x eval-buffer` in `init.el`.
   - Open a `.c` file; see "Basilisk features enabled in C mode" in `*Messages*`.
   - Check the "Basilisk" menu or try `C-c c`.

## Usage

1. **Edit Code**:
   - Open `code.c`, use `C-c e` for an event, `C-c f` for a loop.

2. **Compile**:
   - `C-c c`: Choose method (e.g., "MPI Manual"), enter processes (e.g., "12"), select "No" for Emacs mode.
   - `*compilation*` shows output; navigate errors with `M-g n`.

3. **Run**:
   - `C-c x`: Choose "MPI", "12", "No"; see runtime output in `*compilation*`.

4. **Compile and Run**:
   - `C-c z`: Combine steps; errors appear in `*compilation*`.

5. **Terminal Alternative**:
   - Answer "Yes" to "Run in terminal?"; paste command from clipboard into your terminal.

## Keybindings

| Keybinding  | Function                          | Description                           |
|-------------|-----------------------------------|---------------------------------------|
| `C-c e`     | `basilisk-insert-event`          | Insert event block                    |
| `C-c f`     | `basilisk-insert-foreach`        | Insert foreach loop                   |
| `C-c a`     | `basilisk-insert-foreach-face`   | Insert foreach_face loop              |
| `C-c r`     | `basilisk-insert-foreach-reduction` | Insert reduction loop            |
| `C-c m`     | `basilisk-insert-mpi-function`   | Insert MPI function                   |
| `C-c i`     | `basilisk-insert-main`           | Insert basic main                     |
| `C-c o`     | `basilisk-insert-main-mpi`       | Insert MPI main                       |
| `C-c s`     | `basilisk-insert-struct`         | Insert struct                         |
| `C-c v`     | `basilisk-insert-solver`         | Insert solver template                |
| `C-c c`     | `basilisk-compile-command-generator` | Compile with options          |
| `C-c x`     | `basilisk-run`                   | Run compiled program                  |
| `C-c z`     | `basilisk-compile-and-run`       | Compile and run                       |
| `C-c d`     | `basilisk-browse-documentation`  | Browse Basilisk docs                  |
| `C-c h`     | `basilisk-show-compilation-help` | Show compilation help                 |
| `C-c C-f`   | `basilisk-find-event-definition` | Find event definition                 |
| `C-c C-t`   | `basilisk-toggle-mpi`            | Toggle MPI support                    |

## Troubleshooting

- **"mpicc not found" in `*compilation*`**:
  - Ensure `.bashrc` sets PATH (e.g., `export PATH=$PATH:/path/to/mpicc`).
  - Choose terminal mode (`Yes`) and run manually if needed.

- **Errors Not Highlighted**:
  - Verify GUI Emacs for visual markers; use `M-g n` to navigate.
  - Check `compilation-error-regexp-alist` includes `gcc` pattern.

- **Missing `.c` in Command**:
  - Should be fixed; if not, check `*Messages*` for command output.

- **Syntax Errors**:
  - Deliberate errors (e.g., missing semicolon) appear in `*compilation*` with navigation.

## Contributing

- **Author**: Arun K Eswara (eswara.arun@gmail.com)
- **Issues**: Email feedback or suggest enhancements.
- **Version**: 1.0 adds shell interpreter, fixes filename extensions.

## License

MIT License — provided "as is" with no warranties.

---

Happy Basilisk coding in Emacs!
```

---

### Changes from Previous README

1. **Version**: Updated to 1.0, reflecting latest fixes.
2. **Compilation Section**:
   - Added shell interpreter detail (`bash -c "source ~/.bashrc && ..."`).
   - Clarified dual-mode execution (Emacs `*compilation*` vs. clipboard).
   - Noted `.c` extension fix for source files.
3. **Requirements**:
   - Added shell dependency (Bash) and `.bashrc` setup note.
4. **Usage**:
   - Updated examples to show dual-mode prompts and error navigation.
5. **Troubleshooting**:
   - Included specific fixes (e.g., `.c` extension, `mpicc` PATH).
6. **Contributing**:
   - Updated version history with key enhancements.

### Next Steps
- **Save**: Place this `README.md` in `~/.emacs.d/lisp/` alongside `basilisk_setup.el`.
- **Review**: Check if it captures your workflow accurately; tweak examples if needed.

This is the README file for the `basilisk_setup.el`. 

Let me know if you've any suggestions, feedback or issues
