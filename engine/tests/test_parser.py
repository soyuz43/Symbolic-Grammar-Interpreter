from semiotic_engine.src.interpreter.evaluator import parse_expr, Gradient, Powerset, Nullify, BinaryOp

def test_gradient():
    assert isinstance(parse_expr("∇(X)"), Gradient)

def test_powerset():
    assert isinstance(parse_expr("℘(Y)"), Powerset)

def test_binary_op():
    expr = parse_expr("∇(X) ⊕ ℘(Y)")
    assert isinstance(expr, BinaryOp)
    assert isinstance(expr.left, Gradient)
    assert isinstance(expr.right, Powerset)
