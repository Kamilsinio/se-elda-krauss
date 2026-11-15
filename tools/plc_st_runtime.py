"""Small fail-closed IEC ST executor for offline PLC behavior tests.

Executes source AST, not a second process implementation. Virtual TON/R_TRIG only;
no native compiler, task scheduler, networking or physical device emulation.
"""
from __future__ import annotations
import copy
import re
from pathlib import Path

TOKEN = re.compile(r"\s+|'(?:''|[^'])*'|T#(?:[0-9.]+(?:ms|s|m|h))+|16#[0-9a-fA-F]+|\d+\.\d+|\d+|[A-Za-z_]\w*|:=|=>|<>|<=|>=|\.\.|[()\[\].,:;+\-*/=<>]", re.I)

def tokens(source):
    source = re.sub(r"\(\*.*?\*\)|//[^\n]*|\{[^}]*\}", "", source, flags=re.S)
    out=[]; at=0
    for m in TOKEN.finditer(source):
        if source[at:m.start()].strip(): raise ValueError("Unsupported ST: "+source[at:m.start()])
        at=m.end()
        if not m[0].isspace(): out.append(m[0])
    if source[at:].strip(): raise ValueError("Unsupported trailing ST: "+source[at:])
    return out+["<EOF>"]

class Parser:
    def __init__(self, source): self.t=tokens(source); self.p=0
    def peek(self): return self.t[self.p].upper()
    def pop(self): v=self.t[self.p]; self.p+=1; return v
    def need(self, v):
        got=self.pop()
        if got.upper()!=v.upper(): raise ValueError(f"Expected {v}, got {got} at {self.p}")
        return got
    def optional(self,v):
        if self.peek()==v.upper(): self.pop(); return True
        return False
    def typ(self):
        if self.optional("ARRAY"):
            self.need("["); lo=int(self.pop()); self.need(".."); hi=int(self.pop()); self.need("]"); self.need("OF")
            return ("array",lo,hi,self.typ())
        name=self.pop()
        while self.optional('.'): name += '.'+self.pop()
        if self.optional("["):
            size=int(self.pop()); self.need("]")
            if name.upper()!="STRING": raise ValueError(name)
        return name
    def declarations(self):
        rows=[]
        while not self.optional("END_VAR"):
            names=[self.pop()]
            while self.optional(","): names.append(self.pop())
            self.need(":"); typ=self.typ(); init=None
            if self.optional(":="): init=self.expr()
            self.need(";")
            rows += [(n,typ,init) for n in names]
        return rows
    def expression_list(self):
        args=[]
        if self.peek()!=")":
            while True:
                if self.t[self.p+1] in (":=", "=>"):
                    name=self.pop(); direction=self.pop()
                    args.append((name+('=>' if direction=='=>' else ''),self.expr()))
                else: args.append((None,self.expr()))
                if not self.optional(","): break
        self.need(")")
        return args
    def expr(self, minimum=0):
        token=self.pop(); upper=token.upper()
        if upper in ("NOT","-","+"): left=("unary",upper,self.expr(70))
        elif token=="(":
            left=self.expr(); self.need(")")
        elif token.startswith("'"): left=("const",token[1:-1].replace("''","'"))
        elif upper.startswith("T#"):
            units={"ms":1,"s":1000,"m":60000,"h":3600000}
            left=("const",int(sum(float(n)*units[u.lower()] for n,u in re.findall(r"([0-9.]+)(ms|s|m|h)",token[2:],re.I))))
        elif upper.startswith("16#"): left=("const",int(token[3:],16))
        elif token.isdigit(): left=("const",int(token))
        elif re.fullmatch(r'\d+\.\d+',token): left=("const",float(token))
        elif upper in ("TRUE","FALSE"): left=("const",upper=="TRUE")
        elif re.fullmatch(r"[A-Za-z_]\w*",token): left=("name",token)
        else: raise ValueError("Unsupported expression token "+token)
        precedence={"OR":10,"XOR":15,"AND":20,"=":30,"<>":30,"<":30,">":30,"<=":30,">=":30,"+":40,"-":40,"*":50,"/":50,"MOD":50}
        while True:
            op=self.peek()
            if op==".":
                self.pop(); left=("member",left,self.pop()); continue
            if op=="[":
                self.pop(); index=self.expr(); self.need("]"); left=("index",left,index); continue
            if op=="(":
                self.pop(); left=("call",left,self.expression_list()); continue
            if op not in precedence or precedence[op]<minimum: break
            self.pop(); left=("binary",op,left,self.expr(precedence[op]+1))
        return left
    def block(self, ends):
        result=[]
        while self.peek() not in ends:
            if self.optional(";"): continue
            if self.optional("IF"):
                branches=[]
                condition=self.expr(); self.need("THEN")
                branches.append((condition,self.block({"ELSIF","ELSE","END_IF"})))
                while self.optional("ELSIF"):
                    condition=self.expr(); self.need("THEN")
                    branches.append((condition,self.block({"ELSIF","ELSE","END_IF"})))
                other=[]
                if self.optional("ELSE"): other=self.block({"END_IF"})
                self.need("END_IF"); self.need(";")
                result.append(("if",branches,other))
            elif self.optional("CASE"):
                expression=self.expr(); self.need("OF"); cases=[]
                while self.peek() not in ("ELSE","END_CASE"):
                    label=self.expr(); self.need(":")
                    body=[]
                    # Detect the next label by the tokens immediately before ':'.
                    while self.peek() not in ("ELSE","END_CASE"):
                        save=self.p
                        try:
                            self.expr()
                            is_label=self.peek()==":"
                        except ValueError: is_label=False
                        self.p=save
                        if is_label: break
                        body.extend(self.one())
                    cases.append((label,body))
                other=[]
                if self.optional("ELSE"): other=self.block({"END_CASE"})
                self.need("END_CASE"); self.need(";")
                result.append(("case",expression,cases,other))
            elif self.optional("FOR"):
                name=self.pop(); self.need(":="); start=self.expr(); self.need("TO"); stop=self.expr(); self.need("DO")
                body=self.block({"END_FOR"}); self.need("END_FOR"); self.need(";")
                result.append(("for",name,start,stop,body))
            elif self.optional("RETURN"):
                self.need(";"); result.append(("return",))
            else:
                lhs=self.expr()
                if self.optional(":="):
                    rhs=self.expr(); self.need(";"); result.append(("set",lhs,rhs))
                else:
                    self.need(";")
                    if lhs[0]!="call": raise ValueError("Expected call")
                    result.append(("call",lhs))
        return result
    def one(self):
        # Parse one statement, preserving the common block parser.
        start=self.p; depth=0
        if self.peek() in ("IF","CASE","FOR"):
            opening=self.peek(); closing={"IF":"END_IF","CASE":"END_CASE","FOR":"END_FOR"}[opening]
            q=self.p
            while q<len(self.t):
                if self.t[q].upper()==opening: depth+=1
                if self.t[q].upper()==closing:
                    depth-=1
                    if depth==0:
                        q+=2; break
                q+=1
        else:
            q=self.p
            while self.t[q]!=";": q+=1
            q+=1
        tail=self.t[q]; self.t[q]="<STOP>"
        try: out=self.block({"<STOP>"})
        finally: self.t[q]=tail
        assert self.p==q and self.p>start
        return out

class Ref:
    def __init__(self, owner, key): self.owner=owner; self.key=key
    def get(self):
        v=self.owner[self.key]
        return v.get() if isinstance(v,Ref) else v
    def set(self,v):
        if isinstance(self.owner.get(self.key),Ref): self.owner[self.key].set(v)
        else: self.owner[self.key]=copy.deepcopy(v)

class Timer:
    def __init__(self, edge=False): self.v={"IN":False,"PT":0,"Q":False,"ET":0,"CLK":False}; self.edge=edge; self.previous=False
    def call(self,args,dt):
        self.v.update(args)
        if self.edge:
            self.v["Q"]=bool(self.v["CLK"] and not self.previous); self.previous=bool(self.v["CLK"])
        else:
            self.v["ET"]=min(self.v["ET"]+dt,self.v["PT"]) if self.v["IN"] else 0
            self.v["Q"]=bool(self.v["IN"] and self.v["ET"]>=self.v["PT"])

class RootRef(Ref):
    def __init__(self,value): super().__init__({'value':value},'value')
    def set(self,value):
        target=self.get()
        if isinstance(target,dict):
            replacement=copy.deepcopy(value); target.clear(); target.update(replacement)
        else: super().set(value)

class Runtime:
    def __init__(self, root):
        self.root=Path(root); self.types={}; self.definitions={}; self.enums={}; self.dt=10; self.steps=0
        for path in sorted((self.root/"Modules").glob("*/DUTs/*.st")):
            self.load_type(path.read_text(encoding="utf-8"))
    def load_type(self,text):
        p=Parser(text)
        while p.peek()!="<EOF>":
            p.need("TYPE"); name=p.pop(); p.need(":")
            if p.optional("STRUCT"):
                rows=[]
                while not p.optional("END_STRUCT"):
                    field=p.pop(); p.need(":"); typ=p.typ(); initial=None
                    if p.optional(":="): initial=p.expr()
                    p.need(";"); rows.append((field,typ,initial))
                self.types[name]=rows
            elif p.optional("("):
                members={}
                while not p.optional(")"):
                    key=p.pop(); p.need(":="); sign=-1 if p.optional("-") else 1
                    members[key]=sign*int(p.pop()); p.optional(",")
                p.optional(";"); self.enums[name]=members
            else: raise ValueError("Unsupported type "+name)
            p.need("END_TYPE"); p.optional(";")
    def load(self,*paths):
        for path in paths:
            path=self.root/path; p=Parser(path.read_text(encoding="utf-8"))
            kind=p.pop()
            if kind.upper() not in ("FUNCTION_BLOCK","PROGRAM"): raise ValueError(str(path))
            name=p.pop(); rows=[]; inputs=set(); inouts=set()
            while p.peek() in ("VAR","VAR_INPUT","VAR_OUTPUT","VAR_IN_OUT"):
                group=p.pop().upper(); declarations=p.declarations(); rows+=declarations
                if group=="VAR_INPUT": inputs.update(x[0] for x in declarations)
                if group=="VAR_IN_OUT": inouts.update(x[0] for x in declarations)
            body=p.block({"<EOF>","END_FUNCTION_BLOCK","END_PROGRAM"})
            self.definitions[name]=(rows,body,inputs,inouts)
    def value(self,typ):
        if isinstance(typ,tuple):
            _,lo,hi,item=typ; return {i:self.value(item) for i in range(lo,hi+1)}
        if typ in self.enums: return next(iter(self.enums[typ].values()))
        if typ in self.types:
            value={n:self.value(t) for n,t,_ in self.types[typ]}
            for n,_,initial in self.types[typ]:
                if initial is not None: value[n]=self.eval(initial,value)
            return value
        if typ in self.definitions: return Instance(self,typ)
        if typ.upper() in ("TON","R_TRIG"): return Timer(typ.upper()=="R_TRIG")
        if typ.upper()=="BOOL": return False
        if typ.upper()=="STRING": return ""
        if typ.upper() in ("UINT","INT","UDINT","DINT","TIME","BYTE","WORD","DWORD","REAL","LREAL"): return 0
        raise ValueError("Unknown ST type "+str(typ))
    def instance(self,name): return Instance(self,name)
    def ref(self,expr,env):
        if expr[0]=="name": return Ref(env,expr[1])
        if expr[0]=="member":
            owner=self.eval(expr[1],env)
            if isinstance(owner,(Instance,Timer)): owner=owner.v
            return Ref(owner,expr[2])
        if expr[0]=="index": return Ref(self.eval(expr[1],env),self.eval(expr[2],env))
        raise ValueError("Not assignable "+str(expr))
    def eval(self,e,env):
        k=e[0]
        if k=="const": return e[1]
        if k=="name":
            if e[1] in self.enums: return self.enums[e[1]]
            return self.ref(e,env).get()
        if k in ("member","index"): return self.ref(e,env).get()
        if k=="unary":
            v=self.eval(e[2],env)
            return not v if e[1]=="NOT" else -v if e[1]=="-" else +v
        if k=="binary":
            a=self.eval(e[2],env); b=self.eval(e[3],env); op=e[1]
            if op=="AND": return a & b
            if op=="OR": return a | b
            if op=="XOR": return a ^ b
            if op=="=": return a==b
            if op=="<>": return a!=b
            if op=="<": return a<b
            if op==">": return a>b
            if op=="<=": return a<=b
            if op==">=": return a>=b
            if op=="+": return a+b
            if op=="-": return a-b
            if op=="*": return a*b
            if op=="/": return a//b
            if op=="MOD": return a%b
            raise ValueError(op)
        if k=="call":
            if e[1][0]=="name":
                name=e[1][1].upper()
                if name in ("TO_UINT","TO_UDINT","TO_INT","TO_BYTE","TO_TIME","SHL","SHR"):
                    args=[self.eval(x,env) for _,x in e[2]]
                    if name=="SHL": return (args[0]<<args[1]) & 0xFFFFFFFF
                    if name=="SHR": return args[0]>>args[1]
                    if name=="TO_UINT": return int(args[0]) & 65535
                    if name=="TO_UDINT": return int(args[0]) & 0xFFFFFFFF
                    if name=="TO_BYTE": return int(args[0]) & 255
                    if name=="TO_INT": return (int(args[0])+32768)%65536-32768
                    return int(args[0])
            target=self.eval(e[1],env)
            if isinstance(target,Timer): target.call({n:self.eval(x,env) for n,x in e[2]},self.dt); return None
            if not isinstance(target,Instance): raise ValueError("Unsupported call")
            for n,x in e[2]:
                if n in target.inouts: target.v[n]=self.ref(x,env)
                elif n in target.inputs: target.v[n]=copy.deepcopy(self.eval(x,env))
                else: raise ValueError("Unknown argument "+str(n))
            target.run(); return None
        raise ValueError(k)
    def execute(self,body,env):
        for s in body:
            self.steps+=1
            if self.steps>2000000: raise ValueError("ST instruction limit")
            k=s[0]
            if k=="set": self.ref(s[1],env).set(self.eval(s[2],env))
            elif k=="call": self.eval(s[1],env)
            elif k=="return": return True
            elif k=="if":
                selected=s[2]
                for condition,branch in s[1]:
                    if self.eval(condition,env): selected=branch; break
                if self.execute(selected,env): return True
            elif k=="case":
                value=self.eval(s[1],env); selected=s[3]
                for label,branch in s[2]:
                    if value==self.eval(label,env): selected=branch; break
                if self.execute(selected,env): return True
            elif k=="for":
                start=self.eval(s[2],env); stop=self.eval(s[3],env)
                if stop-start>10000: raise ValueError("ST FOR limit")
                for index in range(start,stop+1):
                    env[s[1]]=index
                    if self.execute(s[4],env): return True
            else: raise ValueError(k)
        return False

class Instance:
    def __init__(self,runtime,name):
        self.runtime=runtime; self.name=name
        self.rows,self.body,self.inputs,self.inouts=runtime.definitions[name]
        self.v={n:runtime.value(t) for n,t,_ in self.rows}
        for n,_,init in self.rows:
            if init is not None: self.v[n]=runtime.eval(init,self.v)
    def run(self,dt=None,**args):
        if dt is not None: self.runtime.dt=dt
        self.runtime.steps=0
        for n,v in args.items():
            if n in self.inouts: self.v[n]=RootRef(v)
            elif n in self.inputs: self.v[n]=copy.deepcopy(v)
            else: raise ValueError("Unknown input "+n)
        try: self.runtime.execute(self.body,self.v)
        except Exception as error:
            raise ValueError(f"{self.name}: {error}") from error
        return self.v

