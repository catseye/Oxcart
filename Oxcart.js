/* --- */

function debug(nm, xs, k) {
  console.log(nm, xs, k);
}

/* --- */

function Push(x, xs) {
  var xs2 = xs.slice();
  xs2.push(x);
  return xs2;
}

function Top(xs) {
  return xs[xs.length - 1];
}

function Pop(xs) {
  var xs2 = xs.slice();
  xs2.pop();
  return xs2;
}

/* --- */

function nop(xs, k) {
  debug("nop", xs, k);
  return k(xs);
}

function push0(xs, k) {
  debug("push0", xs, k);
  return k(Push(0, xs));
}

function incr(xs, k) {
  debug("incr", xs, k);
  var v = Top(xs);
  return k(Push(v + 1, Pop(xs)));
}

function dbl(xs, k) {
  debug("dbl", xs, k);
  var v = Top(xs);
  return k(Push(v * 2, Pop(xs)));
}

function save(xs, k) {
  debug("save", xs, k);
  return k(Push(k, xs));
}

function rsr(xs, k) {
  debug("rsr", xs, k);
  var j = Top(xs);
  return j(Pop(xs));
}

function cont(xs, k) {
  debug("cont", xs, k);
  var j = Top(xs);
  return j(xs);
}

function swpk(xs, k) {
  debug("swpk", xs, k);
  var j = Top(xs);
  return j(Push(k, Pop(xs)));
}

/* --- */

function composeCPS(f, g) {
  return function(x, k) {
    return f(x, function(s) {
      return g(s, k);
    });
  }
}

function compile(s) {
  var f = nop;
  for (var i = 0; i < s.length; i++) {
    var c = s.charAt(i);
    switch(c) {
      case '0':
        f = composeCPS(f, push0);
        break;
      case '+':
        f = composeCPS(f, incr);
        break;
      case 'X':
        f = composeCPS(f, dbl);
        break;
      case '*':
        f = composeCPS(f, save);
        break;
      case '$':
        f = composeCPS(f, rsr);
        break;
      case '~':
        f = composeCPS(f, cont);
        break;
      case '_':
        f = composeCPS(f, swpk);
        break;
    }
  }
  return f;
}

function out(x) {
  console.log(x);
}

function run(s) {
  compile(s)([], out);
}
