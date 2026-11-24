import os, re, copy
TOK = re.compile(r'"(?:\\.|[^"\\])*"|\(|\)|[^\s()]+')


class Q(str):
    pass


def unq(s):
    return re.sub(r'\\(.)', lambda m: {'n': '\n', 't': '\t'}.get(m.group(1), m.group(1)), s)


def parse(t):
    st = [[]]
    for m in TOK.finditer(t):
        k = m.group(0)
        if k == '(':
            st.append([])
        elif k == ')':
            x = st.pop()
            st[-1].append(x)
        elif k[0] == '"':
            st[-1].append(Q(unq(k[1:-1])))
        else:
            st[-1].append(k)
    return st[0]


def dump(x, ind=0):
    if isinstance(x, list):
        s = '('
        nested = False
        for n, i in enumerate(x):
            if isinstance(i, list):
                nested = True
                s += '\n' + '\t' * (ind + 1) + dump(i, ind + 1)
            else:
                s += ('' if n == 0 else ' ') + dump(i, ind)
        return s + ('\n' + '\t' * ind if nested else '') + ')'
    if isinstance(x, Q):
        return '"' + x.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'
    return str(x)


def kids(x, n):
    return [i for i in x if isinstance(i, list) and i and i[0] == n]


def kid(x, n):
    r = kids(x, n)
    return r[0] if r else None


SYMDIR = os.path.expandvars("%LOCALAPPDATA%/Programs/KiCad/10.0/share/kicad/symbols")
_c = {}


def lib(name):
    if name not in _c:
        root = parse(open(SYMDIR + "/" + name + ".kicad_sym", encoding='utf-8').read())[0]
        _c[name] = {s[1]: s for s in kids(root, 'symbol')}
    return _c[name]


def flat(libn, n):
    s = copy.deepcopy(lib(libn)[n])
    e = kid(s, 'extends')
    if not e:
        return s
    b = copy.deepcopy(flat(libn, e[1]))
    bn = b[1]
    b[1] = Q(n)
    for u in kids(b, 'symbol'):
        u[1] = Q(n + u[1][len(bn):])
    for p in kids(s, 'property'):
        for q in kids(b, 'property'):
            if q[1] == p[1]:
                b[b.index(q)] = p
                break
        else:
            b.insert(2, p)
    return b


def pins(s):
    out = []
    for u in kids(s, 'symbol'):
        for p in kids(u, 'pin'):
            a = kid(p, 'at')
            h = kid(p, 'hide')
            out.append((kid(p, 'number')[1], kid(p, 'name')[1], p[1], float(a[1]), float(a[2]), int(float(a[3])), bool(h and h[1] == 'yes')))
    return out
