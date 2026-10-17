.pragma library

// Recursive-descent evaluator for + - * / % ^ and parens. Returns "" when the query isn't arithmetic.
function evaluate(input) {
  var s = (input || "").replace(/\s+/g, "").replace(/×/g, "*").replace(/÷/g, "/");
  if (!/^[\d.+\-*/%^()]+$/.test(s) || !/\d[+\-*/%^(]|\)[+\-*/%^]/.test(s))
    return "";
  var pos = 0;

  function peek() { return s[pos]; }

  function expr() {
    var v = term();
    while (peek() === "+" || peek() === "-")
      v = s[pos++] === "+" ? v + term() : v - term();
    return v;
  }

  function term() {
    var v = unary();
    while (peek() === "*" || peek() === "/" || peek() === "%") {
      var op = s[pos++];
      var r = unary();
      v = op === "*" ? v * r : op === "/" ? v / r : v % r;
    }
    return v;
  }

  function unary() {
    if (peek() === "-") { pos++; return -unary(); }
    if (peek() === "+") { pos++; return unary(); }
    return power();
  }

  // Right-associative, binds tighter than unary minus on its left: -2^2 = -4.
  function power() {
    var base = atom();
    if (peek() === "^") { pos++; return Math.pow(base, unary()); }
    return base;
  }

  function atom() {
    if (peek() === "(") {
      pos++;
      var v = expr();
      if (s[pos++] !== ")")
        throw "paren";
      return v;
    }
    var m = /^\d*\.?\d+/.exec(s.slice(pos));
    if (!m)
      throw "number";
    pos += m[0].length;
    return parseFloat(m[0]);
  }

  try {
    var result = expr();
    if (pos !== s.length || !isFinite(result))
      return "";
    return format(result);
  } catch (e) {
    return "";
  }
}

function format(n) {
  if (Number.isInteger(n) && Math.abs(n) < 1e15)
    return String(n);
  if (Math.abs(n) >= 1e15 || Math.abs(n) < 1e-6)
    return n.toExponential(6).replace(/\.?0+e/, "e");
  return String(parseFloat(n.toFixed(10)));
}
