from lark import Lark, Transformer
from pathlib import Path

grammar_path = Path(__file__).parents[1] / "grammar/semiotic_grammar.lark"
parser = Lark(grammar_path.read_text(), parser="lalr")

class SymbolicExpr: pass
class Gradient(SymbolicExpr):
    def __init__(self, arg): self.arg = arg
class Powerset(SymbolicExpr):
    def __init__(self, arg): self.arg = arg
class Nullify(SymbolicExpr):
    def __init__(self, arg): self.arg = arg
class BinaryOp(SymbolicExpr):
    def __init__(self, left, op, right): self.left, self.op, self.right = left, op, right

class EvalTransformer(Transformer):
    def gradient(self, items): return Gradient(items[0])
    def powerset(self, items): return Powerset(items[0])
    def nullify(self, items): return Nullify(items[0])
    def binary_op(self, items): return BinaryOp(items[0], '⊕', items[1])
    def SYMBOL(self, token): return str(token)

def parse_expr(expr: str) -> SymbolicExpr:
    tree = parser.parse(expr)
    return EvalTransformer().transform(tree)

if __name__ == "__main__":
    expr = "∇(X) ⊕ ℘(Y)"
    result = parse_expr(expr)
    print(result)
