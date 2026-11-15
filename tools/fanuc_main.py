"""Compile technology into exactly two self-contained FANUC main programs.

Small Python templates are build-time definitions, never robot subprograms.
Each inlined block has private labels; no AR, return register or runtime mailbox.
"""
from __future__ import annotations
import json
import csv
import io
import re
from pathlib import Path
from fanuc_common import body, emit, put, yes, no, iff

NAMES={
    **{n:'PLC_'+n[3:] for n in ['RC_AREA','RC_CMD','RC_CYL','RC_IMM','RC_INIT','RC_LINK','RC_LIVE','RC_RX','RC_SMPL','RC_SVC','RC_TX','RC_VAC','RC_TEST']},
    'RC_MON':'BG_PLC','RC_TICK':'PLC_SCAN','RC_EVENTS':'PLC_EVT','RC_RECOV':'PLC_REC','RC_DROP':'PLC_LOST',
    'RB_STATUS':'BG_STATUS','RB_GUARD':'BG_GUARD','RB_BIND':'BG_BIND',
}
def names(text):
    return re.sub(r'\b(?:RC|RB)_[A-Z]+\b',lambda m:NAMES.get(m[0],m[0]),text)

TITLES={
 'BOOT':'Przyjecie lokalnego wyboru main i bazowego tokenu Start',
 'INIT':'Jawna inicjalizacja prywatnych danych przy pustym postoju',
 'SAFE':'Sprawdzenie aktualnych pozwolen przed ruchem',
 'GROUP':'Wybor maski i ilosci kolejnej grupy detali',
 'OFFSET':'Obliczenie przesuniecia odkladania X Y Z',
 'SECT':'Obliczenie pojemnosci aktywnej sekcji pojemnika',
 'ASSIGN':'Przypisanie cyklu IMM i ilosci detali',
 'NEW':'Jawne przygotowanie nowego pustego kontekstu',
 'RECOV':'Uzgodnienie zachowanej partii po przerwaniu',
 'APPLY':'Sprawdzenie i zastosowanie nastaw operatora',
 'EXIT':'Zgloszenie zakonczenia wyboru programu',
 'IMMREQ':'Zadania do wtryskarki przez PLC',
 'FOLD':'Cele silownikow dla bezpiecznego przejazdu',
 'STRAIGHT':'Cele silownikow do pobrania z formy',
 'TARGET':'Cele silownikow dla wybranej grupy',
 'VACON':'Wlaczenie i potwierdzenie podcisnienia',
 'RELEASE':'Jednorazowe zlecenie zwolnienia ladunku',
 'RELEASED':'Potwierdzenie przedmuchu i zwolnienia ladunku',
 'DONE':'Sprawdzenie pelnego zakonczenia REQ ACK',
 'BLPICK':'Zgloszenie pobrania pustej tacki',
 'BLPLACE':'Zgloszenie odlozenia pustej tacki',
 'BLFULL':'Zgloszenie napelnienia pojedynczej tacki',
 'STACK':'Zgloszenie ukonczenia stosu lub pojemnika',
 'IMMPICK':'Zgloszenie wyjazdu z pobrana partia IMM',
 'PROD':'Rozliczenie odlozonych dobrych detali',
 'SAMPLE':'Rozliczenie odlozonych probek',
 'REJECT':'Rozliczenie odlozonych odrzutow',
 'LAYER':'Zgloszenie ukonczenia warstwy pojemnika',
 'SPACER':'Zgloszenie odlozenia przekladki',
 'BADSTATE':'Blad nieznanego kroku technologii',
 'HOME':'Dojazd do potwierdzonego HOME',
 'SRCIN':'Wejscie do zrodla pustej tacki lub przekladki',
 'SRCOUT':'Podniesienie i wyjazd ze zrodla',
 'SEARCH':'Ograniczony krok szukania po Z',
 'TRAYIN':'Odlozenie pustej tacki lub przekladki',
 'TRAYOUT':'Podniesienie i wyjazd po odlozeniu',
 'IMMIN':'Dojazd do wtryskarki',
 'PICK':'Wejscie i pobranie z formy',
 'RETRACT':'Wycofanie z detalami',
 'IMMOUT':'Wyjazd z formy',
 'PLACEIN':'Dojazd nad obszar odkladania produktow',
 'PLACEOUT':'Wyjazd znad produktow',
 'SAMPLEIN':'Wjazd do miejsca probek i odrzutow',
 'SAMPLEOUT':'Wyjazd z miejsca probek i odrzutow',
}
def title(name):
    token=name.split('_',1)[-1]
    if re.fullmatch(r'PROD\d+UP',token):return 'Podniesienie po zwolnieniu grupy '+re.search(r'\d+',token)[0]
    if re.fullmatch(r'PROD\d+',token):return 'Podejscie i odlozenie grupy '+re.search(r'\d+',token)[0]
    if re.fullmatch(r'SAMP\d+',token):return 'Odlozenie do probek lub odrzutow - grupa '+re.search(r'\d+',token)[0]
    return TITLES.get(token,'Obsluga procesu '+token)

def simplify_jumps(seq):
    """Remove only empty fall-through jumps, unreachable jumps and unused labels."""
    while True:
        targets=set(re.findall(r'JMP LBL\[(\d+)\]', '\\n'.join(seq)))
        active=[s for s in seq if not ((m:=re.fullmatch(r'LBL\[(\d+)\]',s)) and m[1] not in targets)]
        out=[]
        for i,s in enumerate(active):
            jump=re.search(r'JMP LBL\[(\d+)\]$',s)
            if jump:
                following=next((v for v in active[i+1:] if not v.startswith('!')),None)
                if following=='LBL['+jump[1]+']':continue
            previous=next((v for v in reversed(out) if not v.startswith('!')),None)
            if s.startswith('JMP ') and previous and previous.startswith('JMP '):continue
            out.append(s)
        if out==seq:return out
        seq=out

def consolidate(art,root):
    manifest={d:json.loads(art[root/f'ROBOT/{d}/resources.json']) for d in ('TRAY','BOX','COMMON')}
    shared=manifest['COMMON'];gb=shared['flags'];owner=shared['owner']
    comm=__import__('build_fanuc_comm').build()
    com=json.loads(comm[root/'ROBOT/COMM/resources.json']);c=com['controls'];app=com['application'];rx=com['rx']
    programs={p.stem:body(text) for p,text in art.items() if p.suffix=='.LS'}
    output={p:text for p,text in art.items() if p.suffix!='.LS'}
    for mode,folder,prefix in [(2,'TRAY','RT'),(1,'BOX','RX')]:
        m=manifest[folder];p=m['runtime'];b=m['flags']
        for key,number in [('applyRequest',47 if mode==2 else 151),('exitRequest',48 if mode==2 else 152)]:
            b[key]=f'F[{number}]';m['allocations'].append(dict(name='control.'+key,bank='F',number=number))
        local_refs={shared['api_registers'][key]:m[group][field] for key in shared['api_registers'] for group,field in [key.split('.')]}
        local_refs.update({ref:b[key] for key,ref in shared['api_flags'].items()})
        serial=1000
        def label():
            nonlocal serial
            serial+=1
            assert serial<=32767,'Too many labels'
            return serial
        def fix(line):
            return re.sub(r'\b(?:R|F)\[\d+\]',lambda z:local_refs.get(z[0],z[0]),line)
        def expand(name,exit_to=None):
            if name in ('RF_READ','RF_WRITE'):
                if name=='RF_READ':return []
                return [iff(b['needsRecovery'],yes(c['guardRequest'])),iff(b['needsRecovery'],put(p['state'],900))]
            lines=[fix(v) for v in programs[name]]
            # No runtime mailbox; arguments and results are private R/F of this main.
            lines=[v for v in lines if shared['flags']['apiValid'] not in v]
            if name==prefix+'_INIT':
                lines=[v for v in lines if not (v.startswith('IF ') or v.startswith('CALL '))]
                preserve={b['selected'],b['booted']}
                lines=[v for v in lines if not any(v.startswith(ref+'=') for ref in preserve)]
                lines=[v for v in lines if v!='LBL[999]']
                lines += [no(b['booted']),no(b['applyRequest']),no(b['exitRequest']),put(p['lastStart'],rx['p2r.production.startToken'])]
            if any('JMP LBL[999]' in v for v in lines) and 'LBL[999]' not in lines:lines.append('LBL[999]')
            labels={int(z[1]):label() for v in lines if (z:=re.fullmatch(r'LBL\[(\d+)\]',v))}
            if exit_to is not None and 999 in labels:labels[999]=exit_to
            result=[] if name in ('RF_SAFE','RF_IMMREQ') else ['! '+title(name)]
            for line in lines:
                if exit_to is not None and line=='LBL[999]':continue
                line=re.sub(r'LBL\[(\d+)\]',lambda z:'LBL['+str(labels[int(z[1])])+']',line)
                call=re.fullmatch(r'(?:(IF \((.*)\)),)?CALL (\w+)',line)
                if call:
                    cond=call[2];callee=call[3]
                    if callee.startswith(('RC_','RB_','PLC_','BG_')):
                        result.append(names(line));continue
                    skip=label() if cond else None
                    if cond:result.append(iff('!('+cond+')',f'JMP LBL[{skip}]'))
                    result += expand(callee)
                    if skip:result.append(f'LBL[{skip}]')
                else:result.append(line)
            return result
        main_name='MAIN_'+folder
        lines=['! Pelna technologia w tym programie',
               '! PLC wykonuje pneumatyke oraz EUROMAP 67',
               '! Start lokalny na robocie; potem nowy Start PLC',
               '! Stop konczy rozpoczete operacje oraz N+1',
               '! Blad wymaga uzgodnienia stanu i nowego Startu',
               '! Inicjalizacja wyboru programu']
        lines += expand(prefix+'_BOOT')
        lines += ['LBL[1]','! Obsluga operatora przy postoju',
                  iff(f'({owner}<>{mode}) AND !{gb["boxRequest" if mode==1 else "trayRequest"]}',no(b['selected'])),
                  iff(f'{owner}<>{mode}','JMP LBL[2]')]
        # The only local INIT entry is in the selected, unarmed main at verified idle.
        skip=label()
        lines += [iff('!'+b['initApproved'],f'JMP LBL[{skip}]'),
                  iff(f'!{gb["ownershipSafe"]} OR {gb["conflict"]}',f'JMP LBL[{skip}]'),
                  iff(f'{b["armed"]} OR !{b["stationIdleConfirmed"]}',f'JMP LBL[{skip}]'),
                  iff(f'{b["batchAssigned"]} OR ({p["remaining"]}<>0)',f'JMP LBL[{skip}]')]
        lines += expand(prefix+'_INIT')+[f'LBL[{skip}]']
        for action,key in [('APPLY','applyRequest'),('EXIT','exitRequest')]:
            skip=label()
            lines += [iff('!'+b[key],f'JMP LBL[{skip}]')]+expand(prefix+'_'+action)+[no(b[key]),f'LBL[{skip}]']
        # Inline the main control and the phase families once. There is no TICK file.
        tick=programs[prefix+'_TICK'];begin=next(i for i,v in enumerate(tick) if v.startswith('SELECT '))
        end=next(i for i,v in enumerate(tick) if v.startswith('ELSE,CALL '))
        pre=tick[:begin];post=tick[end+1:]
        # Main-local labels 997/999 from the old control become private.
        tick_end=label();tick_init=label();post_label=label()
        def control_line(v):
            return v.replace('LBL[999]',f'LBL[{tick_end}]').replace('LBL[997]',f'LBL[{tick_init}]')
        # Control uses no cross-family labels; expand handles its private labels.
        # Directly add control statements, expanding only its calls.
        def control_part(part):
            out=[]
            for v in part:
                v=control_line(v)
                call=re.fullmatch(r'(?:IF \((.*)\),)?CALL (\w+)',v)
                if call and not call[2].startswith(('RC_','RB_','PLC_','BG_')):
                    stop=label() if call[1] else None
                    if stop:out.append(iff('!('+call[1]+')',f'JMP LBL[{stop}]'))
                    out+=expand(call[2])
                    if stop:out.append(f'LBL[{stop}]')
                else:out.append(names(v))
            return out
        lines += control_part(pre)
        groups={}
        for v in tick[begin:end]:
            z=re.fullmatch(r'(?:SELECT R\[\d+\])?=(\d+),CALL (\w+)',v);assert z,v
            dest=groups.setdefault(z[2],label())
            lines.append(iff(f'{p["work"]}={z[1]}',f'JMP LBL[{dest}]'))
        lines += expand(prefix+'_BADSTATE')+[f'JMP LBL[{post_label}]']
        group_titles={'IDLE':'Gotowosc i przypisanie partii','TACK':'Pusta tacka' if mode==2 else 'Przygotowanie pojemnika',
                      'PICK':'Pobranie partii z formy','PLACE':'Odkladanie grup produktow, probek i odrzutow',
                      'FULL':'Warstwy, przekladki i zakonczenie pojemnika' if mode==1 else 'Pelna tacka i stos',
                      'STOP':'Postoj i uzgadnianie stanu po bledzie'}
        for group,dest in groups.items():
            lines += [f'LBL[{dest}]','! ===== '+group_titles[group.split('_')[1]]+' =====']
            lines += expand(group,exit_to=post_label)+[f'JMP LBL[{post_label}]']
        lines += [f'LBL[{post_label}]']+control_part(post[:-1])+[iff(b['needsRecovery'],yes(c['guardRequest'])),iff(b['needsRecovery'],put(p['state'],900))]+control_part(post[-1:])
        lines += ['LBL[2]','! Oddanie czasu PLC i BG - 20 ms','WAIT   .02(sec)',iff(b['selected'],'JMP LBL[1]'),
                  '! Koniec programu po zwolnieniu wyboru w BG']
        output[root/f'ROBOT/{folder}/{main_name}.LS']=emit(main_name,names('\n'.join(simplify_jumps(lines))).splitlines(),motion=True)
        m['entry_program']=main_name;m['operator_commands']={key:b[key] for key in ['initApproved','applyRequest','newApproved','recoveryApproved','contextChecked','exitRequest']}
        output[root/f'ROBOT/{folder}/resources.json']=json.dumps(m,ensure_ascii=False,indent=2)+'\n'
    # BG keeps its single owner. Runtime mailbox references and allocations disappear.
    unused={shared['flags'][n] for n in ('apiBusy','apiValid')}
    unused.update(shared['api_flags'].values());unused.update(shared['api_registers'].values());unused.add('R[332]')
    for old,new in [('RB_BIND','BG_BIND'),('RB_STATUS','BG_STATUS'),('RB_GUARD','BG_GUARD')]:
        seq=programs[old]
        seq=[v for v in seq if not any(v.startswith(ref+'=') for ref in unused)]
        seq=[v.replace(' AND !'+shared['flags']['apiBusy'],'') for v in seq]
        output[root/f'ROBOT/BG/{new}.LS']=emit(new,names('\n'.join(seq)).splitlines())
    shared['flags']={k:v for k,v in shared['flags'].items() if v not in unused}
    shared.pop('api_flags');shared.pop('api_registers')
    shared['allocations']=[v for v in shared['allocations'] if f'{v["bank"]}[{v["number"]}]' not in unused]
    shared['unused_reserved']={'R_ranges':[[332,349]],'F_ranges':[[410,411],[432,443]]}
    shared['program_names']={'tray':'MAIN_TRAY','box':'MAIN_BOX'}
    output[root/'ROBOT/COMMON/resources.json']=json.dumps(shared,ensure_ascii=False,indent=2)+'\n'
    migration=[]
    for old_path in art:
        if old_path.suffix!='.LS':continue
        old=old_path.stem
        if old in NAMES:
            target=NAMES[old];kind='RENAME';note='Ta sama rola techniczna, nowa czytelna nazwa'
        elif old in ('RF_READ','RF_WRITE'):
            target='';kind='REMOVE_MAILBOX';note='Brak runtime kopiowania miedzy bankami'
        else:
            target='MAIN_TRAY' if old_path.parent.name=='TRAY' else 'MAIN_BOX' if old_path.parent.name=='BOX' else 'MAIN_TRAY + MAIN_BOX'
            kind='INLINE';note='Technologia bezposrednio w main: '+title(old)
        migration.append([old_path.relative_to(root).as_posix(),target,kind,note])
    for old,new in NAMES.items():
        if not old.startswith('RC_'):continue
        for folder in ['ROBOT/COMM','ROBOT/TEST/COMM']:
            if old=='RC_TEST' and folder=='ROBOT/COMM':continue
            migration.append([folder+'/'+old+'.LS',new,'RENAME','Komunikacja bez zmiany wire v2'])
    stream=io.StringIO(newline='');writer=csv.writer(stream,lineterminator='\n')
    writer.writerow(['old_path','new_program','change','meaning']);writer.writerows(sorted(migration))
    output[root/'ROBOT/program-migration.csv']=stream.getvalue()
    return output
