"""Static member/call audit of PLC source interfaces. Not a vendor compiler."""
from __future__ import annotations
import re
import json
import hashlib
from check_plc_robot import runtime, ROOT
from plc_st_runtime import Parser

def validate():
    r=runtime()
    for path in ['Modules/Cyl2Pos/FB_Cyl2Pos.st','Modules/StopperPair/FB_StopperPair.st','Modules/Conveyor/FB_Conveyor.st',
                 'Modules/TopFlowManager/FB_TopFlowManager.st',
                 'Modules/BottomAccumulator/FB_BottomAccumulator_567.st',
                 'Modules/Elevator/FB_Elevator.st','Modules/ElevatorDriveAdapter/FB_ElevatorDriveAdapter.st','Modules/StationController/FB_StationController.st','Modules/SafetyDoor/FB_SafetyDoor.st',
                 'Modules/PRG_IO_Read.st','Modules/PRG_IO_Write.st','Modules/PRG_Main.st']:
        r.load(path)
    globals={}
    global_declarations=[]
    for file in ['GVL_IO','GVL_HMI','GVL_Robot','GVL_RobotRetain','GVL_Station']:
        text=(ROOT/'GVLs'/f'{file}.st').read_text(encoding='utf-8')
        for match in re.finditer(r'\bTYPE\s+\w+\s*:.*?\bEND_TYPE',text,re.S):r.load_type(match[0])
        rows=[]
        for match in re.finditer(r'\bVAR_GLOBAL(?:\s+PERSISTENT\s+RETAIN|\s+CONSTANT)?\s+(.*?)END_VAR',text,re.S):
            p=Parser(match[1]+' END_VAR')
            rows.extend(p.declarations())
        global_declarations.append((file,rows))
        globals[file]=('fields',{name:typ for name,typ,_ in rows})
    globals['GVL_IO_RAW']='external'
    globals['Altivar_320']='external' # Natywny Axis_Ref, GAP-06; nie jest modelem napedu.
    errors=[]
    # IEC identifiers are case-insensitive; ACTION, PROGRAM and REFERENCE are reserved.
    declarations=[(name,rows) for name,rows in r.types.items()]
    declarations += [(name,definition[0]) for name,definition in r.definitions.items()]
    declarations += global_declarations
    for scope,rows in declarations:
        seen={}
        for member,_,_ in rows:
            key=member.casefold()
            if key in seen:
                errors.append(scope+': duplicate identifier '+member+' conflicts with '+seen[key]+' (case-insensitive)')
            else:
                seen[key]=member
            if key in {'action','program','reference'}:
                errors.append(scope+': reserved identifier '+member.upper()+'; use '+member.lower()+'_')
    def infer(e,env):
        k=e[0]
        if k=='const':return 'scalar'
        if k=='name':
            if e[1] in env:return env[e[1]]
            if e[1] in r.enums:return ('enum',r.enums[e[1]])
            if e[1] in r.definitions:return e[1]
            if re.fullmatch(r'(?:TO_\w+|\w+_TO_\w+|SHL|SHR|MIN|MAX|LIMIT|ABS)',e[1]):return 'builtin'
            raise ValueError('Unknown name '+e[1])
        if k=='member':
            base=infer(e[1],env);name=e[2]
            if base=='external' or (isinstance(base,str) and '.' in base):return 'external'
            if isinstance(base,tuple) and base[0] in ('fields','enum'):fields=base[1]
            elif base in r.types:fields={n:t for n,t,_ in r.types[base]}
            elif base in r.definitions:fields={n:t for n,t,_ in r.definitions[base][0]}
            elif base in ('TON','R_TRIG','F_TRIG','TP'):fields={k:'scalar' for k in ['IN','PT','Q','ET','CLK']}
            else:raise ValueError('Cannot select '+str(base)+'.'+name)
            if name not in fields:raise ValueError('Unknown member '+str(base)+'.'+name)
            return fields[name]
        if k=='index':
            base=infer(e[1],env);infer(e[2],env)
            if not isinstance(base,tuple) or base[0]!='array':raise ValueError('Index of non-array '+str(base))
            return base[3]
        if k=='unary':infer(e[2],env);return 'scalar'
        if k=='binary':infer(e[2],env);infer(e[3],env);return 'scalar'
        if k=='call':
            target=infer(e[1],env)
            for name,arg in e[2]:
                infer(arg,env)
                if target in r.definitions:
                    fields={n:t for n,t,_ in r.definitions[target][0]}
                    argument=name[:-2] if name.endswith('=>') else name
                    if argument not in fields:raise ValueError('Unknown argument '+target+'.'+str(name))
                    if not name.endswith('=>') and argument not in r.definitions[target][2] | r.definitions[target][3]:
                        raise ValueError('Not an input argument '+target+'.'+argument)
            return 'scalar'
        raise ValueError('Unsupported expression '+k)
    def writable(expression,env):
        if expression[0]=='member':
            owner=infer(expression[1],env)
            if isinstance(owner,str) and owner in r.definitions:
                _,_,inputs,inouts=r.definitions[owner]
                if expression[2] not in inputs | inouts:
                    raise ValueError('Write to non-input '+owner+'.'+expression[2])
            writable(expression[1],env)
        elif expression[0]=='index':writable(expression[1],env)
    def body(statements,env):
        for s in statements:
            if s[0]=='set':writable(s[1],env);infer(s[1],env);infer(s[2],env)
            elif s[0]=='call':infer(s[1],env)
            elif s[0]=='if':
                for cond,branch in s[1]:infer(cond,env);body(branch,env)
                body(s[2],env)
            elif s[0]=='case':
                infer(s[1],env)
                for cond,branch in s[2]:infer(cond,env);body(branch,env)
                body(s[3],env)
            elif s[0]=='for':infer(s[2],env);infer(s[3],env);body(s[4],env)
            elif s[0]!='return':raise ValueError(s[0])
    for name,(rows,statements,_,_) in r.definitions.items():
        try:body(statements,{**globals,**{n:t for n,t,_ in rows}})
        except (ValueError,TypeError) as error:errors.append(name+': '+str(error))
    # A local scalar used by the main must have a producer, not remain its default forever.
    main=(ROOT/'Modules/PRG_Main.st').read_text(encoding='utf-8').split('END_VAR',1)[1]
    main=re.sub(r'\(\*.*?\*\)|//[^\n]*','',main,flags=re.S)
    for name,typ,initial in r.definitions['PRG_Main'][0]:
        if typ not in ('BOOL','UINT','INT','TIME') or initial is not None:continue
        if re.search(r'\b'+name+r'\b',main) and not re.search(r'\b'+name+r'\s*:=',main):
            errors.append('PRG_Main: scalar without producer: '+name)
    # Reproducible LF-normalized source identity, independent of checkout line endings.
    manifest=json.loads((ROOT/'docs/station-source-manifest.json').read_text(encoding='utf-8'))
    for row in manifest['files']:
        path=(ROOT/row['path']).resolve()
        if not path.is_relative_to(ROOT.resolve()) or 'irrelevant' in path.parts:
            errors.append('Invalid manifest path: '+row['path']); continue
        if not path.is_file():
            errors.append('Missing manifest source: '+row['path']); continue
        digest=hashlib.sha256(path.read_text(encoding='utf-8').encode('utf-8')).hexdigest()
        if digest != row['sha256']: errors.append('Stale source manifest: '+row['path'])
    return errors

if __name__=='__main__':
    errors=validate()
    for error in errors:print(error)
    if errors:raise SystemExit(1)
    print('PASS static PLC member/call audit; native library interfaces remain uncompiled')

