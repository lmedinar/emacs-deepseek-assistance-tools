# ia-python-practica

Proyecto de práctica de la guía **Programación asistida por IA en Emacs (Python)**.

## Estado inicial

- `calc/operaciones.py`: dos funciones sin implementar y un bug intencional.
- `tests/test_operaciones.py`: ocho tests.
- Al empezar: **4 fallos, 4 aprobados**.

## Uso

```bash
python3 -m pytest -q
```

## Repetir la guía desde cero

```bash
./scripts/reset.sh
```

El script hace `git reset --hard estado-inicial` y `git clean -fdx`, y deja el proyecto exactamente como al principio.
