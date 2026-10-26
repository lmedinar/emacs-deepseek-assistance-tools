;;; init.el --- Emacs + DeepSeek para programación asistida -*- lexical-binding: t; -*-

;;; Commentary:
;; Configuración mínima para la guía:
;;   https://github.com/lmedinar/emacs-deepseek-assistance-tools
;;
;; Requisitos: Emacs 29+, git, python3, pytest, black y ripgrep.
;; Clave de DeepSeek: variable DEEPSEEK_API_KEY o archivo ~/.emacs.d/.deepseek-key.
;; GitHub/Forge: archivo ~/.authinfo (ver docs/instalacion.md).
;;
;; Uso:
;;   emacs --init-directory /ruta/a/emacs-deepseek-assistance-tools/emacs

;;; Code:

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(setq use-package-always-ensure t)

;; --- Claves ---
(defun mi-leer-clave (archivo)
  "Lee una API key desde ARCHIVO, sin espacios ni saltos de línea."
  (let ((ruta (expand-file-name archivo)))
    (when (file-exists-p ruta)
      (with-temp-buffer
        (insert-file-contents ruta)
        (string-trim (buffer-string))))))

(defun mi-clave-deepseek ()
  "Devuelve la clave de DeepSeek desde el entorno o desde el archivo local."
  (or (getenv "DEEPSEEK_API_KEY")
      (mi-leer-clave "~/.emacs.d/.deepseek-key")))

;; --- gptel + DeepSeek ---
(use-package gptel
  :ensure t
  :config
  (require 'gptel-rewrite)

  (defvar mi-deepseek-backend
    (gptel-make-deepseek "DeepSeek"
      :key (mi-clave-deepseek)
      :stream t))

  (defvar mi-gemini-backend
    (when-let ((key (getenv "GEMINI_API_KEY")))
      (gptel-make-gemini "Gemini" :key key :stream t)))

  (setq gptel-backend mi-deepseek-backend)
  (setq gptel-model 'deepseek-flash)

  (defvar mi-prompt-programador
    "Rol: Experto Senior en Linux, Python, Octave y Bash.
Meta: Código elegante, optimizado y didáctico.
Requisitos en comentarios:
1. Claridad: Explica el 'por qué', no solo el 'qué'.
2. Enseñanza: Destaca conceptos avanzados usados en la solución.")

  (setq-default gptel-system-prompt mi-prompt-programador)
  (add-to-list 'gptel-directives
               (cons 'programador mi-prompt-programador))

  (defun gptel-cambiar-entorno (backend modelo nombre-buffer)
    "Cambia de modelo y aísla el contexto en NOMBRE-BUFFER."
    (interactive)
    (setq gptel-backend backend
          gptel-model modelo)
    (gptel nombre-buffer)
    (message "Activo: %s. Contexto en %s" modelo nombre-buffer))

  (defun gptel-usar-deepseek ()
    "DeepSeek Flash (rápido, para código)."
    (interactive)
    (gptel-cambiar-entorno mi-deepseek-backend 'deepseek-flash "*gptel-deepseek*"))

  (defun gptel-usar-deepseek-pro ()
    "DeepSeek V4 Pro (más potente)."
    (interactive)
    (gptel-cambiar-entorno mi-deepseek-backend 'deepseek-v4-pro "*gptel-deepseek-pro*"))

  (defun gptel-usar-gemini ()
    "Gemini 2.5 Flash (opcional; define GEMINI_API_KEY)."
    (interactive)
    (if mi-gemini-backend
        (gptel-cambiar-entorno mi-gemini-backend 'gemini-2.5-flash "*gptel-gemini*")
      (user-error "Define GEMINI_API_KEY para usar Gemini")))

  (unless (mi-clave-deepseek)
    (display-warning 'gptel "Configura DEEPSEEK_API_KEY o ~/.emacs.d/.deepseek-key")))

;; --- Python: LSP, flycheck y black ---
(use-package flycheck
  :ensure t
  :init (global-flycheck-mode 1))

(use-package lsp-mode
  :ensure t
  :hook ((python-mode . lsp-deferred)))

(use-package lsp-pyright
  :ensure t
  :hook (python-mode . (lambda () (require 'lsp-pyright))))

(use-package blacken
  :ensure t)

;; --- Comandos de IA y Python (se añaden a continuación) ---

;; ============================================================

;; Comandos de IA y Python

;; ============================================================


;; Se apoya en la sección anterior (gptel + DeepSeek).
(require 'gptel)
(require 'gptel-rewrite)

;; --- Contexto: archivo, lenguaje y región (o buffer completo) ---
(defun ia--lenguaje ()
  (cond ((derived-mode-p 'python-mode) "python")
        ((derived-mode-p 'emacs-lisp-mode) "emacs-lisp")
        ((derived-mode-p 'sh-mode) "bash")
        (t "text")))

(defun ia--contexto ()
  "Devuelve la región activa o el buffer completo, con archivo y lenguaje."
  (let* ((src (if (use-region-p)
                  (buffer-substring-no-properties (region-beginning) (region-end))
                (buffer-substring-no-properties (point-min) (point-max))))
         (archivo (or (buffer-file-name) (buffer-name))))
    (format "Archivo: %s\n```%s\n%s\n```" archivo (ia--lenguaje) src)))

(defun ia--consulta (accion instruccion)
  "Envía INSTRUCCION + contexto a gptel en un buffer *IA: ACCION*."
  (let* ((nombre (format "*IA: %s*" accion))
         (prompt (concat instruccion "\n\n" (ia--contexto)))
         (buf (get-buffer-create nombre)))
    (with-current-buffer buf
      (unless (bound-and-true-p gptel-mode)
        (gptel nombre nil nil nil))
      (erase-buffer)
      (insert prompt)
      (goto-char (point-max))
      (gptel-send))
    (display-buffer buf)))

(defun ia--error-actual ()
  "Extrae el error de *compilation* (pytest) o de flycheck."
  (cond
   ((and (get-buffer "*compilation*")
         (with-current-buffer "*compilation*"
           (> (point-max) (point-min))))
    (with-current-buffer "*compilation*"
      (buffer-substring-no-properties
       (max (point-min) (- (point-max) 4000)) (point-max))))
   ((bound-and-true-p flycheck-current-errors)
    (mapconcat #'flycheck-error-message flycheck-current-errors "\n"))
   (t (buffer-substring-no-properties
       (line-beginning-position) (line-end-position)))))

;; --- Acciones de IA ---
(defun ia-explicar ()
  "Explica el código seleccionado (o el buffer)."
  (interactive)
  (ia--consulta "explicar"
                "Explica este código paso a paso: qué hace, qué recibe, qué devuelve y qué casos límite tiene. Sé breve y concreto."))

(defun ia-tests ()
  "Genera tests pytest para el código seleccionado."
  (interactive)
  (ia--consulta "tests"
                "Escribe tests de pytest para este código. Incluye casos normales, bordes y errores esperados. Devuelve solo el archivo de test completo, listo para guardar."))

(defun ia-implementar ()
  "Implementa el código a partir del test seleccionado."
  (interactive)
  (ia--consulta "implementar"
                "Implementa el código que hace pasar estos tests. Devuelve solo el código de producción, sin explicaciones."))

(defun ia-revisar ()
  "Revisa el código buscando bugs y mejoras."
  (interactive)
  (ia--consulta "revisar"
                "Revisa este código como un senior: bugs, casos límite, claridad y rendimiento. Ordena los hallazgos por gravedad y propone el parche mínimo para cada uno."))

(defun ia-docstrings ()
  "Añade docstrings y type hints."
  (interactive)
  (ia--consulta "docstrings"
                "Añade docstrings (estilo Google) y type hints a este código sin cambiar su comportamiento. Devuelve solo el código completo."))

(defun ia-corregir ()
  "Corrige el error actual de *compilation* o de flycheck."
  (interactive)
  (let ((error (ia--error-actual)))
    (ia--consulta "corregir"
                  (format "Este es el error que obtengo:\n\n%s\n\nCorrige el código. Devuelve solo el código completo y, al final, una línea con la causa." error))))

(defun ia-refactor ()
  "Refactoriza la región con diff aceptable/rechazable."
  (interactive)
  (unless (use-region-p)
    (user-error "Selecciona primero el código a refactorizar"))
  (let ((gptel--rewrite-directive
         "Eres un refactorizador experto en Python. Devuelve SOLO el código reemplazado, sin explicaciones ni bloques markdown."))
    (gptel--suffix-rewrite
     "Refactoriza sin cambiar el comportamiento: nombres claros, funciones pequeñas y sin duplicación.")))

(defun ia-aceptar ()
  "Acepta el diff pendiente de gptel."
  (interactive)
  (if gptel--rewrite-overlays
      (gptel--rewrite-accept gptel--rewrite-overlays)
    (message "No hay ningún diff pendiente")))

(defun ia-rechazar ()
  "Rechaza el diff pendiente de gptel."
  (interactive)
  (if gptel--rewrite-overlays
      (gptel--rewrite-reject gptel--rewrite-overlays)
    (message "No hay ningún diff pendiente")))

(defun ia-diff ()
  "Muestra el diff pendiente de gptel."
  (interactive)
  (if gptel--rewrite-overlays
      (gptel--rewrite-diff gptel--rewrite-overlays)
    (message "No hay ningún diff pendiente")))

(defun ia-chat ()
  "Abre un chat libre con el backend activo."
  (interactive)
  (gptel "*IA: chat*"))

;; --- Comandos de Python ---
(defun py--raiz ()
  "Raíz del proyecto Python (o el directorio actual)."
  (or (locate-dominating-file default-directory "pyproject.toml")
      (locate-dominating-file default-directory "pytest.ini")
      (locate-dominating-file default-directory "setup.cfg")
      (locate-dominating-file default-directory ".git")
      default-directory))

(defun py-ejecutar ()
  "Ejecuta el archivo Python actual."
  (interactive)
  (unless (buffer-file-name)
    (user-error "Guarda el archivo antes de ejecutarlo"))
  (compile (format "python3 %s" (shell-quote-argument (buffer-file-name)))))

(defun py-pytest ()
  "Ejecuta pytest desde la raíz del proyecto."
  (interactive)
  (let ((default-directory (py--raiz)))
    (compile "python3 -m pytest -q")))

(defun py-black ()
  "Formatea el buffer con black."
  (interactive)
  (if (fboundp 'blacken-buffer)
      (blacken-buffer)
    (user-error "blacken no está disponible")))

(defun py-lint ()
  "Muestra los diagnósticos de Pyright/flycheck."
  (interactive)
  (if (fboundp 'flycheck-list-errors)
      (flycheck-list-errors)
    (user-error "flycheck no está disponible")))

(defun py-repl ()
  "Abre un REPL de Python."
  (interactive)
  (run-python (python-shell-calculate-command) nil t))

;; --- Atajos ---
(defvar mi-ia-map (make-sparse-keymap) "Atajos de IA.")
(define-key mi-ia-map (kbd "e") #'ia-explicar)
(define-key mi-ia-map (kbd "t") #'ia-tests)
(define-key mi-ia-map (kbd "i") #'ia-implementar)
(define-key mi-ia-map (kbd "r") #'ia-revisar)
(define-key mi-ia-map (kbd "f") #'ia-refactor)
(define-key mi-ia-map (kbd "d") #'ia-docstrings)
(define-key mi-ia-map (kbd "x") #'ia-corregir)
(define-key mi-ia-map (kbd "a") #'ia-aceptar)
(define-key mi-ia-map (kbd "K") #'ia-rechazar)
(define-key mi-ia-map (kbd "D") #'ia-diff)
(define-key mi-ia-map (kbd "c") #'ia-chat)
(define-key mi-ia-map (kbd "m") #'gptel-menu)
(define-key mi-ia-map (kbd "s") #'gptel-send)
(define-key mi-ia-map (kbd "1") #'gptel-usar-deepseek)
(define-key mi-ia-map (kbd "2") #'gptel-usar-deepseek-pro)
(define-key mi-ia-map (kbd "3") #'gptel-usar-gemini)
(global-set-key (kbd "C-c I") mi-ia-map)

(defvar mi-python-map (make-sparse-keymap) "Atajos de Python.")
(define-key mi-python-map (kbd "r") #'py-ejecutar)
(define-key mi-python-map (kbd "t") #'py-pytest)
(define-key mi-python-map (kbd "f") #'py-black)
(define-key mi-python-map (kbd "l") #'py-lint)
(define-key mi-python-map (kbd "c") #'py-repl)
(global-set-key (kbd "C-c P") mi-python-map)


;; ============================================================

;; Git y GitHub

;; ============================================================


;; --- Magit: la interfaz de Git ---
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

;; --- Forge: issues y pull requests de GitHub ---
;; Requiere un token en ~/.authinfo (ver la guía).
(use-package forge
  :ensure t
  :after magit)

;; --- diff-hl: cambios en el margen ---
(use-package diff-hl
  :ensure t
  :config
  (global-diff-hl-mode 1)
  (diff-hl-flydiff-mode 1)
  :hook (magit-post-refresh . diff-hl-update))

;; --- git-link: copiar la URL de GitHub ---
(use-package git-link
  :ensure t)

;; --- Atajos globales C-c G ---
(defvar mi-git-map (make-sparse-keymap) "Atajos de Git.")
(define-key mi-git-map (kbd "s") #'magit-status)
(define-key mi-git-map (kbd "c") #'magit-commit-create)
(define-key mi-git-map (kbd "p") #'magit-push)
(define-key mi-git-map (kbd "f") #'magit-fetch)
(define-key mi-git-map (kbd "l") #'magit-log-current)
(define-key mi-git-map (kbd "d") #'magit-diff-working-tree)
(define-key mi-git-map (kbd "b") #'magit-branch-checkout)
(define-key mi-git-map (kbd "B") #'magit-blame)
(define-key mi-git-map (kbd "S") #'magit-stash)
(define-key mi-git-map (kbd "g") #'git-link)
(define-key mi-git-map (kbd "F") #'forge-dispatch)
(global-set-key (kbd "C-c G") mi-git-map)


;; ============================================================

;; Agente de proyecto

;; ============================================================


;; Herramientas para que la IA explore, edite y verifique el proyecto.
;; Todo queda confinado a la raíz del proyecto actual.

(defvar-local ia--raiz-fija nil
  "Raíz fijada por el agente de proyecto en su buffer.")

(defun ia--raiz-proyecto ()
  "Raíz del proyecto actual o el directorio por defecto."
  (or ia--raiz-fija
      (expand-file-name
       (or (when-let* ((p (project-current nil default-directory)))
             (project-root p))
           default-directory))))

(defun ia--ruta-segura (ruta &optional no-exigir)
  "Resuelve RUTA dentro de la raíz del proyecto.
Señala error si se sale de la raíz.  Si NO-EXIGIR es nil, exige que exista."
  (let* ((raiz (file-truename (file-name-as-directory (ia--raiz-proyecto))))
         (abs  (expand-file-name ruta raiz))
         (real (if (file-exists-p abs)
                   (file-truename abs)
                 (file-truename (file-name-directory abs)))))
    (unless (string-prefix-p raiz (file-name-as-directory real))
      (error "Ruta fuera del proyecto: %s" ruta))
    (unless (or no-exigir (file-exists-p abs))
      (error "No existe: %s" ruta))
    abs))

(defun ia--relativa (abs)
  (file-relative-name abs (ia--raiz-proyecto)))

(defun ia--ejecutar (programa args dir &optional timeout)
  "Ejecuta PROGRAMA con ARGS en DIR.  Devuelve (CODIGO . SALIDA)."
  (condition-case err
      (let* ((buf (generate-new-buffer " *ia-proc*"))
             (default-directory dir)
             (proc (make-process :name "ia-proc" :buffer buf
                                 :command (cons programa args)
                                 :noquery t :connection-type 'pipe))
             (limite (+ (float-time) (or timeout 120)))
             (fin nil))
        (while (and (not fin) (< (float-time) limite))
          (accept-process-output proc 0.2)
          (setq fin (not (process-live-p proc))))
        (when (process-live-p proc)
          (delete-process proc)
          (with-current-buffer buf
            (goto-char (point-max))
            (insert "\n[tiempo de espera agotado]")))
        (let ((codigo (process-exit-status proc)))
          (with-current-buffer buf
            (let ((salida (buffer-string)))
              (kill-buffer buf)
              (cons codigo
                    (if (> (length salida) 20000)
                        (concat (substring salida 0 20000) "\n... [truncado]")
                      salida))))))
    (error (cons 1 (format "No se pudo ejecutar %s: %s"
                           programa (error-message-string err))))))

(defun ia--resultado (par)
  (format "exit=%s\n%s" (car par)
          (if (string-empty-p (cdr par)) "(sin salida)" (cdr par))))

;; --- Lectura ---
(defun ia--arbol (&optional ruta max)
  (let* ((dir (ia--ruta-segura (or ruta ".")))
         (max (or max 300))
         (bruto (if (project-current nil dir)
                    (project-files (project-current nil dir))
                  (directory-files-recursively
                   dir ".*" nil
                   (lambda (f) (string-match-p "/\\.git/\\|/__pycache__/\\|/\\.pytest_cache/" f)))))
         (rel (sort (mapcar #'ia--relativa bruto) #'string<)))
    (when (> (length rel) max)
      (setq rel (append (seq-take rel max)
                        (list (format "... [%d archivos más]" (- (length rel) max))))))
    (mapconcat #'identity rel "\n")))

(defun ia--leer (ruta)
  (let ((abs (ia--ruta-segura ruta)))
    (when (file-directory-p abs)
      (error "Es un directorio: %s" ruta))
    (when (> (nth 7 (file-attributes abs)) 300000)
      (error "Archivo demasiado grande (>300 KB): %s" ruta))
    (with-temp-buffer
      (insert-file-contents abs)
      (when (search-forward "\0" nil t)
        (error "Archivo binario: %s" ruta))
      (let ((txt (buffer-substring-no-properties (point-min) (point-max))))
        (if (> (length txt) 40000)
            (concat (substring txt 0 40000) "\n... [truncado]")
          txt)))))

(defun ia--buscar (patron &optional ruta)
  (unless (executable-find "rg")
    (error "ripgrep (rg) no está instalado"))
  (let* ((dir (ia--ruta-segura (or ruta ".")))
         (default-directory (if (file-directory-p dir) dir (file-name-directory dir)))
         (buf (generate-new-buffer " *ia-rg*")))
    (unwind-protect
        (progn
          (with-current-buffer buf (erase-buffer))
          (call-process "rg" nil buf nil
                        "--line-number" "--no-heading" "--color" "never"
                        "-m" "20" patron ".")
          (with-current-buffer buf
            (let ((salida (buffer-string)))
              (if (string-empty-p salida)
                  (format "Sin coincidencias para %S en %s" patron (ia--relativa dir))
                (if (> (length salida) 20000)
                    (concat (substring salida 0 20000) "\n... [truncado]")
                  salida)))))
      (kill-buffer buf))))

;; --- Escritura ---
(defun ia--diff-y-confirmar (abs contenido)
  (let ((actual (if (file-exists-p abs)
                    (with-temp-buffer
                      (insert-file-contents abs)
                      (buffer-string))
                  "")))
    (if (string= actual contenido)
        (progn (message "Sin cambios en %s" (ia--relativa abs)) t)
      (let* ((tmp1 (make-temp-file "ia-actual-"))
             (tmp2 (make-temp-file "ia-nuevo-"))
             (buf (get-buffer-create "*IA: cambio propuesto*")))
        (write-region actual nil tmp1 nil 'silent)
        (write-region contenido nil tmp2 nil 'silent)
        (with-current-buffer buf
          (erase-buffer)
          (insert (format "Archivo: %s\n\n" (ia--relativa abs)))
          (call-process "diff" nil buf nil "-u"
                        "--label" (concat "a/" (ia--relativa abs))
                        "--label" (concat "b/" (ia--relativa abs))
                        tmp1 tmp2)
          (goto-char (point-min)))
        (delete-file tmp1)
        (delete-file tmp2)
        (display-buffer buf)
        (y-or-n-p (format "¿Aplicar cambios en %s? " (ia--relativa abs)))))))

(defun ia--escribir-archivo (abs contenido)
  (let ((buf (find-buffer-visiting abs)))
    (if buf
        (with-current-buffer buf
          (let ((inhibit-read-only t))
            (erase-buffer)
            (insert contenido)
            (save-buffer)))
      (with-temp-buffer
        (insert contenido)
        (write-region (point-min) (point-max) abs nil 'silent)))))

(defun ia--escribir (ruta contenido)
  (let ((abs (ia--ruta-segura ruta)))
    (if (ia--diff-y-confirmar abs contenido)
        (progn (ia--escribir-archivo abs contenido)
               (format "Escrito: %s" ruta))
      "Cambio cancelado.")))

(defun ia--reemplazar (ruta viejo nuevo)
  (let* ((abs (ia--ruta-segura ruta))
         (actual (with-temp-buffer (insert-file-contents abs) (buffer-string)))
         (cuenta 0)
         (pos 0))
    (while (string-match (regexp-quote viejo) actual pos)
      (setq cuenta (1+ cuenta)
            pos (match-end 0)))
    (cond
     ((zerop cuenta) (error "No se encontró el fragmento en %s" ruta))
     ((> cuenta 1)
      (error "El fragmento aparece %d veces en %s; añade más contexto" cuenta ruta))
     (t (let ((nuevo-texto (replace-regexp-in-string
                            (regexp-quote viejo) (lambda (_) nuevo) actual t t)))
          (if (ia--diff-y-confirmar abs nuevo-texto)
              (progn (ia--escribir-archivo abs nuevo-texto)
                     (format "Reemplazado en: %s" ruta))
            "Cambio cancelado."))))))

(defun ia--crear (ruta contenido)
  (let ((abs (ia--ruta-segura ruta t)))
    (when (file-exists-p abs)
      (error "Ya existe: %s" ruta))
    (make-directory (file-name-directory abs) t)
    (let ((buf (get-buffer-create "*IA: archivo nuevo*")))
      (with-current-buffer buf
        (erase-buffer)
        (insert (format "Archivo nuevo: %s\n\n%s" ruta contenido))
        (goto-char (point-min)))
      (display-buffer buf)
      (if (y-or-n-p (format "¿Crear %s? " ruta))
          (progn (ia--escribir-archivo abs contenido)
                 (format "Creado: %s" ruta))
        "Creación cancelada."))))

(defun ia--borrar (ruta)
  (let ((abs (ia--ruta-segura ruta)))
    (when (file-directory-p abs)
      (error "No borro directorios: %s" ruta))
    (let ((buf (get-buffer-create "*IA: borrar archivo*")))
      (with-current-buffer buf
        (erase-buffer)
        (insert (format "Archivo: %s\n\n%s" ruta
                        (with-temp-buffer
                          (insert-file-contents abs)
                          (buffer-substring-no-properties
                           (point-min) (min (point-max) 2000)))))
        (goto-char (point-min)))
      (display-buffer buf)
      (if (y-or-n-p (format "¿Mover a la papelera %s? " ruta))
          (progn (delete-file abs t)
                 (format "Borrado: %s" ruta))
        "Borrado cancelado."))))

;; --- Verificación ---
(defun ia--pytest (&optional ruta)
  (let* ((raiz (ia--raiz-proyecto))
         (args (append (list "-m" "pytest" "-q")
                       (when (and ruta (not (string-empty-p ruta)))
                         (list ruta)))))
    (ia--resultado (ia--ejecutar "python3" args raiz 180))))

(defun ia--git (accion &optional commit)
  (let* ((raiz (ia--raiz-proyecto))
         (args (pcase accion
                 ("status" '("status" "--short" "--branch"))
                 ("diff"   '("diff" "--stat" "--patch"))
                 ("log"    '("log" "--oneline" "--graph" "-n" "20"))
                 ("branch" '("branch" "-vv"))
                 ("show"   (if (and commit
                                    (string-match-p "\\`[0-9a-fA-F]\\{4,40\\}\\'" commit))
                               (list "show" "--stat" "--patch" commit)
                             (error "Commit inválido para show: %s" commit)))
                 (_ (error "Acción git no permitida: %s" accion)))))
    (ia--resultado (ia--ejecutar "git" args raiz 30))))

(defun ia--commit (mensaje)
  (let* ((raiz (ia--raiz-proyecto))
         (_ (ia--ejecutar "git" '("add" "-A") raiz 30))
         (vacio (ia--ejecutar "git" '("diff" "--cached" "--quiet") raiz 30))
         (stat (ia--ejecutar "git" '("diff" "--cached" "--stat") raiz 30))
         (diff (ia--ejecutar "git" '("diff" "--cached" "--patch") raiz 30))
         (buf (get-buffer-create "*IA: commit propuesto*")))
    (when (zerop (car vacio))
      (error "No hay cambios para commitear"))
    (with-current-buffer buf
      (erase-buffer)
      (insert (format "Mensaje: %s\n\n%s\n%s" mensaje (cdr stat) (cdr diff)))
      (goto-char (point-min)))
    (display-buffer buf)
    (if (y-or-n-p "¿Hacer commit con estos cambios? ")
        (ia--resultado (ia--ejecutar "git" (list "commit" "-m" mensaje) raiz 60))
      "Commit cancelado.")))

(defun ia--push (&optional remoto)
  (let* ((raiz (ia--raiz-proyecto))
         (remoto (or remoto "origin"))
         (status (ia--ejecutar "git" '("status" "-sb") raiz 30))
         (upstream (ia--ejecutar "git" '("rev-parse" "--abbrev-ref"
                                         "--symbolic-full-name" "@{u}") raiz 30))
         (pendientes (if (zerop (car upstream))
                         (ia--ejecutar "git" '("log" "--oneline" "@{u}..HEAD") raiz 30)
                       (cons 0 "(sin upstream; se usará -u origin HEAD)")))
         (buf (get-buffer-create "*IA: push propuesto*")))
    (with-current-buffer buf
      (erase-buffer)
      (insert (format "Remoto: %s\n\nEstado:\n%s\nCommits a subir:\n%s"
                      remoto (cdr status) (cdr pendientes)))
      (goto-char (point-min)))
    (display-buffer buf)
    (if (y-or-n-p "¿Hacer push? ")
        (let ((args (if (zerop (car upstream))
                        (list "push" remoto)
                      (list "push" "-u" remoto "HEAD"))))
          (ia--resultado (ia--ejecutar "git" args raiz 120)))
      "Push cancelado.")))

;; --- Herramientas para gptel ---
(defvar ia--tools-proyecto
  (list
   (gptel-make-tool
    :function #'ia--arbol
    :name "proyecto_arbol"
    :description "Lista los archivos del proyecto actual (rutas relativas). Úsala para orientarte antes de leer o buscar."
    :args (list '(:name "ruta" :type string :description "Subcarpeta relativa a la raíz. Por defecto la raíz." :optional t)
                '(:name "max" :type integer :description "Máximo de archivos a listar. Por defecto 300." :optional t)))
   (gptel-make-tool
    :function #'ia--leer
    :name "proyecto_leer"
    :description "Lee un archivo de texto del proyecto. Devuelve su contenido. Ruta relativa a la raíz."
    :args (list '(:name "ruta" :type string :description "Ruta relativa del archivo, por ejemplo calc/operaciones.py.")))
   (gptel-make-tool
    :function #'ia--buscar
    :name "proyecto_buscar"
    :description "Busca un patrón regex con ripgrep dentro del proyecto y devuelve líneas con número. Úsala para localizar símbolos, llamadas o texto."
    :args (list '(:name "patron" :type string :description "Expresión regular a buscar.")
                '(:name "ruta" :type string :description "Subcarpeta donde buscar. Por defecto la raíz." :optional t)))
   (gptel-make-tool
    :function #'ia--escribir
    :name "proyecto_escribir"
    :description "Reescribe un archivo existente con el contenido completo. Muestra un diff y pide confirmación. Úsala solo para reescrituras grandes."
    :args (list '(:name "ruta" :type string :description "Ruta relativa del archivo.")
                '(:name "contenido" :type string :description "Contenido completo nuevo del archivo.")))
   (gptel-make-tool
    :function #'ia--reemplazar
    :name "proyecto_reemplazar"
    :description "Reemplaza un fragmento exacto de un archivo. Falla si el fragmento no existe o aparece más de una vez. Muestra un diff y pide confirmación."
    :args (list '(:name "ruta" :type string :description "Ruta relativa del archivo.")
                '(:name "viejo" :type string :description "Texto exacto que se va a reemplazar.")
                '(:name "nuevo" :type string :description "Texto nuevo.")))
   (gptel-make-tool
    :function #'ia--crear
    :name "proyecto_crear"
    :description "Crea un archivo nuevo con el contenido indicado. Nunca sobrescribe. Pide confirmación."
    :args (list '(:name "ruta" :type string :description "Ruta relativa del archivo nuevo.")
                '(:name "contenido" :type string :description "Contenido inicial.")))
   (gptel-make-tool
    :function #'ia--borrar
    :name "proyecto_borrar"
    :description "Mueve un archivo a la papelera. Pide confirmación. No borra directorios."
    :args (list '(:name "ruta" :type string :description "Ruta relativa del archivo a borrar.")))
   (gptel-make-tool
    :function #'ia--pytest
    :name "proyecto_pytest"
    :description "Ejecuta pytest en la raíz del proyecto (o en una ruta) y devuelve la salida. Úsala después de cada edición."
    :args (list '(:name "ruta" :type string :description "Ruta opcional de test o carpeta." :optional t)))
   (gptel-make-tool
    :function #'ia--git
    :name "proyecto_git"
    :description "Consulta git en modo lectura: status, diff, log, show o branch."
    :args (list '(:name "accion" :type string :enum ["status" "diff" "log" "show" "branch"] :description "Acción de git.")
                '(:name "commit" :type string :description "Hash para show (opcional)." :optional t)))
   (gptel-make-tool
    :function #'ia--commit
    :name "proyecto_commit"
    :description "Prepara todos los cambios, muestra el diff y hace commit con el mensaje indicado, previa confirmación."
    :args (list '(:name "mensaje" :type string :description "Mensaje de commit.")))
   (gptel-make-tool
    :function #'ia--push
    :name "proyecto_push"
    :description "Hace push al remoto indicado (por defecto origin), mostrando los commits pendientes y pidiendo confirmación."
    :args (list '(:name "remoto" :type string :description "Remoto de git. Por defecto origin." :optional t))))
  "Herramientas del agente de proyecto.")

(defun ia-proyecto ()
  "Abre el agente de proyecto con herramientas de lectura, edición y git."
  (interactive)
  (let* ((raiz (ia--raiz-proyecto))
         (buf (get-buffer-create "*IA: proyecto*")))
    (with-current-buffer buf
      (unless (bound-and-true-p gptel-mode)
        (gptel "*IA: proyecto*" nil nil nil))
      (setq-local ia--raiz-fija raiz)
      (setq-local default-directory raiz)
      (setq-local gptel-tools ia--tools-proyecto)
      (setq-local gptel-system-prompt
                  (format "Eres un agente de programación con acceso al proyecto %s.\n\
Reglas:\n\
1. Explora con proyecto_arbol y proyecto_buscar antes de responder.\n\
2. Antes de editar, lee el archivo con proyecto_leer y explica el cambio.\n\
3. Usa proyecto_reemplazar para cambios pequeños; proyecto_escribir solo para reescrituras.\n\
4. Después de editar, ejecuta proyecto_pytest y reporta el resultado.\n\
5. Antes de commit, revisa el diff y pide confirmación.\n\
6. No hagas push sin confirmación explícita.\n\
7. No inventes rutas ni resultados; las rutas son relativas a la raíz." raiz))
      (setq-local header-line-format
                  (format " Proyecto: %s | herramientas: árbol/leer/buscar/escribir/reemplazar/crear/borrar/pytest/git/commit/push " raiz))
      (erase-buffer)
      (insert (gptel-prompt-prefix-string))
      (goto-char (point-max)))
    (pop-to-buffer buf)
    (message "Agente de proyecto: %s" raiz)))

(define-key mi-ia-map (kbd "p") #'ia-proyecto)


(provide 'init)
;;; init.el ends here
