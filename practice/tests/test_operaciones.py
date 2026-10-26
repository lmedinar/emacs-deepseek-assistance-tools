"""Tests de la calculadora. Deben fallar al principio (rojo)."""

import pytest

from calc.operaciones import (
    dividir,
    multiplicar,
    potencia,
    promedio,
    restar,
    sumar,
)


def test_sumar():
    assert sumar(2, 3) == 5


def test_restar():
    assert restar(5, 2) == 3


def test_multiplicar():
    assert multiplicar(3, 4) == 12


def test_dividir():
    assert dividir(10, 2) == 5


def test_dividir_por_cero():
    with pytest.raises(ZeroDivisionError):
        dividir(1, 0)


def test_promedio():
    assert promedio([2, 4, 6]) == 4


def test_promedio_vacio():
    with pytest.raises(ValueError):
        promedio([])


def test_potencia():
    assert potencia(2, 3) == 8
