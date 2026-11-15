"""Render named operands and Polish comments from one semantic catalogue."""
from __future__ import annotations
import csv,io,json,re,textwrap,unicodedata,os
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
REF=re.compile(r'\b(?:PR|R|F|DI|DO|GI|GO|UO|SI|SO)\[\d+(?:,\d+)?\]|\$[A-Za-z_][A-Za-z0-9_.$\[\]]*')
def plain(s):return unicodedata.normalize('NFKD',s.replace('ł','l').replace('Ł','L')).encode('ascii','ignore').decode()
def catalogue():
    result={}
    for row in csv.DictReader((ROOT/'tools/fanuc_meanings.csv').read_text(encoding='utf-8').splitlines(),delimiter='|'):
        key=(row['group'],row['key']);assert key not in result,key
        result[key]=(row['label'],row['description'])
    return result
WORDS=dict(pair.split(':',1) for pair in (
'area:Obsz source:Zrod elevator:Wind storage:Mag valid:Waz ready:Got granted:Zez clear:Poza accessReq:WejReq '
'cyl:Cyl home:Home work:Work atHome:WHome atWork:WWork acceptedHome:AkHome acceptedWork:AkWork '
'vac:Vac cmdValid:WazCmd hold:Trzymaj accepted:Akc holdApplied:TrzymAkt ok:OK blowReq:DmReq blowAck:DmACK blowResult:DmWyn '
'event:Zdarz req:Req ack:ACK count:Szt cycleId:Cykl stackId:Lad index:Idx link:Lacz version:Wers heartbeat:HB '
'syncRequest:SyncReq syncAck:SyncACK production:Prod expectedProgram:Program withRobot:ZRobot orderActive:ZlecON '
'newOperationPermit:NoweZez finishPermit:DokonczZez stopRequest:Stop endOrderRequest:KoniecZlec criticalBlock:KrytBlok '
'recoveryRequired:Recovery startToken:Start samples:Probki result:Wynik imm:IMM mouldClose:ZamForme mouldFullOpen:OtwForme '
'mouldOpen:FormaOtw mouldClosed:FormaZam ejectorBack:WyrzTyl ejectorForward:WyrzPrz pickupPending:DoPobr '
'cycleKnown:CyklZnany newCyclePermit:NowyCykl unsettledCount:NieRozlicz settled:Rozlicz batchCount:SztPart reject:Odrzut '
'program:Program running:Praca faultCode:KodBledu waitCode:CzekaKod loadKnown:LadZnany loadMask:MaskLad '
'operationsSettled:OperRozl waitingResume:CzekaStart stopping:Zatrzym step:Krok phase:Faza').split())
WORDS.update(applied='Zastos',blockCode='KodBlok',busy='Trwa',mouldIntermediate='FormaPozSr',reason='Przyczyna')
POINTS={
'HOME':'Wspolny HOME, zgodny z odebrana Reference Position.',
'SOURCE_ENTRY':'Bezpieczny wjazd do zrodla pustych nosnikow.','SOURCE_APPROACH':'Podejscie do stosu pustych nosnikow.',
'SOURCE_SEARCH_START':'Poczatek szukania nosnika po Z.','SOURCE_SEARCH_LIMIT':'Dolna granica Z szukania.',
'SOURCE_LIFT':'Podniesienie pobranego nosnika.','SOURCE_EXIT':'Wyjazd poza zrodlo nosnikow.',
'SPACER_SEARCH_START':'Poczatek szukania przekladki po Z.','SPACER_SEARCH_LIMIT':'Dolna granica szukania przekladki.',
'SPACER_LIFT':'Pomocnicza baza podniesienia przekladki; aktualna droga BOX jest obliczana od bazy odlozenia.',
'ELEVATOR_ENTRY':'Wjazd do windy ponad maksymalnym zatwierdzonym ladunkiem.',
'TRAY_APPROACH':'Podejscie nad miejsce pustej tacki.','TRAY_PLACE':'Odlozenie pustej tacki.',
'ELEVATOR_EXIT':'Wyjazd poza winde.','IMM_ENTRY':'Wjazd w rejon wtryskarki.',
'IMM_WAIT':'Oczekiwanie przed wejsciem w forme.','IMM_APPROACH':'Podejscie do pobrania detali.',
'IMM_PICK':'Pobranie partii z formy.','IMM_RETRACT':'Wycofanie z detalami poza gniazda formy.',
'IMM_EXIT':'Wyjazd poza forme i przestrzen IMM.','PRODUCT_APPROACH':'Podejscie nad produkty ponad calym zatwierdzonym ladunkiem.',
'OFFSET_WORK':'Obliczany wektor X/Y/Z; nie punkt do nauki.','SEARCH_WORK':'Obliczana pozycja szukania; nie punkt do nauki.',
'POSE_WORK':'Obliczana pozycja podejscia/odlozenia/podniesienia; nie punkt do nauki.',
'SAMPLE_ENTRY':'Wjazd do probek/odrzutow.','SAMPLE_EXIT':'Wyjazd z probek/odrzutow.',
'HOME_ENTRY':'Odebrana droga dojscia do HOME.','TRAY_LIFT':'Podniesienie po odlozeniu tacki.',
'SPACER_APPROACH_FIRST_LAYER':'Pomocnicza baza podejscia przekladki na pierwszej warstwie.',
'SPACER_PLACE_FIRST_LAYER':'Baza przekladki na gorze pierwszej warstwy BOX; kolejne dodaja Z.',
'RESERVE':'Rezerwa, nieuzywana w ruchu.'}
PROGRAMS={
'MAIN_TRAY':'Produkcja tacek i stosow','MAIN_BOX':'Produkcja kuwet i pojemnikow',
'PLC_INIT':'Init pamieci lacza EIP','PLC_RX':'Odbior snapshotu PLC','PLC_TX':'Zapis wyjsc do PLC',
'PLC_SCAN':'Jeden cykl komunikacji','PLC_SVC':'Petla serwisu lacza','PLC_LINK':'Synchronizacja i sesja',
'PLC_LOST':'Uniewaznienie sesji','PLC_REC':'Jawne recovery lacza','PLC_LIVE':'Lokalny start serwisu',
'PLC_EVT':'Kanaly zdarzen i ACK','PLC_CMD':'Walidacja komend PLC','PLC_CYL':'Zadania silownikow',
'PLC_VAC':'Zadania podcisnienia','PLC_IMM':'Zadania EUROMAP do PLC','PLC_AREA':'Rezerwacje obszarow',
'PLC_SMPL':'Zadanie i ACK probek','PLC_TEST':'Izolowany test lacza','BG_PLC':'Watchdog i heartbeat PLC',
'BG_STATUS':'Native i wybor main','BG_GUARD':'Blokady i alarm procesu','BG_BIND':'Komplet zrodel native'}
ATTRIBUTES={
'MAIN_TRAY':'Produkcja TRAY','MAIN_BOX':'Produkcja BOX','PLC_INIT':'Init lacza','PLC_RX':'Odbior PLC',
'PLC_TX':'Wysylanie PLC','PLC_SCAN':'Cykl komunikacji','PLC_SVC':'Serwis PLC','PLC_LINK':'Sesja i SYNC',
'PLC_LOST':'Utrata lacza','PLC_REC':'Recovery lacza','PLC_LIVE':'Start serwisu','PLC_EVT':'Zdarzenia i ACK',
'PLC_CMD':'Walidacja komend','PLC_CYL':'Cele silownikow','PLC_VAC':'Podcisnienie','PLC_IMM':'Zadania IMM',
'PLC_AREA':'Dostep obszarow','PLC_SMPL':'Obsluga probek','PLC_TEST':'Test izolowany',
'BG_PLC':'Watchdog PLC','BG_STATUS':'Status i wybor','BG_GUARD':'Blokady procesu','BG_BIND':'Zrodla native'}

def point_meaning(name):
    if name in POINTS:return POINTS[name]
    m=re.fullmatch(r'(?:P([23])_)?PRODUCT_GROUP_(\d)',name)
    if m:return 'Baza grupy '+m[2]+' w sekcji P'+(m[1] or '1')+' na pierwszej warstwie.'
    m=re.fullmatch(r'SAMPLE_GROUP_(\d)',name)
    if m:return 'Baza grupy '+m[1]+' dla probek i odrzutow, z osobnym rozliczeniem.'
    raise AssertionError('Missing point meaning: '+name)
def dictionary(manifests,com,mapping):
    data=catalogue();words=dict(WORDS)
    for (group,key),(alias,_) in data.items():
        if group in ('native','event'):words.setdefault(key,alias)
    contract=json.loads((ROOT/'docs/robot-plc-signals.json').read_text(encoding='utf-8'))
    signals={s['id']:s for s in contract['signals']};records={}
    def add(ref,alias,desc):
        assert alias and desc,(ref,alias)
        # Keep the last field (count/cycle/stack, HOME/WORK) visible in short labels.
        alias=plain(alias)
        if len(alias)>14:alias=alias[:8]+'_'+alias[-5:]
        records[ref]=dict(address=ref,label=alias,description=plain(desc))
    def signal(id):
        s=signals[id];parts=id.split('.')[1:]
        assert all(p in words or p.isdigit() or re.fullmatch(r'V\d+',p) for p in parts),id
        if parts[0]=='event':alias=data['event',parts[1]][0][:6]+words[parts[-1]]
        elif parts[0]=='cyl':alias=parts[1]+words[parts[-1]]
        elif parts[0]=='vac':alias='Vac'+parts[1]+words[parts[-1]]
        elif parts[0]=='area':alias=words[parts[1]]+words[parts[-1]]
        elif parts[0]=='imm':alias='IMM'+({'applied':'P','req':'Z'}.get(parts[1],''))+words[parts[-1]]
        else:alias=''.join(words.get(p,p) for p in parts)
        desc=s['meaning']+' Kierunek: '+('PLC do robota.' if s['direction']=='PLC_TO_ROBOT' else 'Robot do PLC.')
        if id=='r2p.production.faultCode':desc+=' Kody: 1001 nastawy; 1100 blokada; 1101/2101 punkt lub granica; 1102 nieznany krok; 1201 przedmuch; 1301..1303 przypisanie; 1401..1408 recovery; 1501 szukanie; 1502 zastana proznia; 1601 brak miejsca; 1700+krok timeout; 1800 BG; 1900 sekwencja.'
        if id=='r2p.production.waitCode':desc+=' 0 brak; 20 partia; 30 forma; 40 chwytak; 50 proznia/przedmuch; 60 obszar/nosnik; 70 ACK; 80 operator lub Start.'
        if id=='r2p.production.phase':desc+=' 10 gotowosc; 20 IMM; 30 odkladanie; 40 pusty nosnik/przekladki/koniec; 50 probki/odrzuty; 60 powrot HOME; 70 postoj; 900 recovery.'
        return alias,desc
    for item in com['allocations']:
        name=item['name'];ref=f'{item["bank"]}[{item["number"]}]';parts=name.split('.')
        if parts[0] in ('rx','app','tx','frozen','mock'):
            alias,desc=signal('.'.join(parts[1:]))
            role={'rx':('Rx','Snapshot odebrany przez PLC_RX. '),'app':('Cmd','Lokalne zadanie lub status aplikacji. '),
                  'tx':('Tx','Bufor wyjscia po walidacji. '),'frozen':('ACK','Payload zamrozony od REQ do ACK=0. '),
                  'mock':('M','Syntetyczne wejscie tylko izolowanego TEST. ')}[parts[0]]
            add(ref,role[0]+alias,role[1]+desc)
        elif parts[0]=='control':
            alias,desc=data['control',parts[1]]
            if item['bank']=='F':desc+=' ON opisany warunek/zadanie; OFF brak.'
            add(ref,alias,desc)
        elif parts[0]=='channel':
            event,field=parts[1:]
            alias,desc=('Dm'+event[4:],'przedmuch obwodu '+event[4:]) if event.startswith('blow') else data['event',event]
            meaning=('Stan wymiany: 0 bezczynna; 10 REQ=1 czeka ACK=1; 20 REQ=0 czeka ACK=0.' if field=='state' else
                'Wynik: 0 brak; 10 trwa; 20 sukces (wymaga stanu 0); 30 odrzucono; 40 blad wykonania; 900 utrata sesji; 901 brak pozwolenia; 903 zastane ACK=1; 904 bledny payload.')
            add(ref,alias+('Stan' if field=='state' else 'Wynik'),'Kanal: '+desc+'. '+meaning)
        else:raise AssertionError('Missing resource meaning: '+name)
    for s in mapping['signals']:
        alias,desc=signal(s['id']);add(f'{s["io"]}[{s["number"]}]',alias,desc+' Transport EIP; fizyczne przypisanie do odbioru.')
    for mode,m in manifests.items():
        prefix={'TRAY':'T','BOX':'B','COMMON':'W'}[mode]
        for item in m['allocations']:
            ref=f'{item["bank"]}[{item["number"]}]';name=item['name'];parts=name.split('.')
            if parts[0] in ('staging','active','runtime'):
                key=parts[1]
                if re.fullmatch(r'(mask|qty|cylGroup)\d',key):
                    n=key[-1];kind=key[:-1]
                    alias,desc={'mask':('MaskG'+n,'Maska grupy '+n+': bit 0..4 = obwod prozni 1..5.'),
                        'qty':('SztG'+n,'Liczba detali grupy '+n+' [szt.], niezalezna od ssawek i obwodow.'),
                        'cylGroup':('CylG'+n,'Cele grupy '+n+': bity HOME 0..4, WORK 5..9; para 00 pomija, 11 blad.')}[kind]
                elif re.fullmatch(r'p[23](X|Y|pitchX|pitchY)',key):
                    section=key[1];field={'X':'gridX','Y':'gridY','pitchX':'pitchX','pitchY':'pitchY'}[key[2:]]
                    alias,desc=data['field',field];alias='P'+section+alias;desc='Sekcja P'+section+'. '+desc
                else:alias,desc=data['field',key]
                rp,rd={'staging':('S','Nastawa edytowana; wymaga APPLY przy zamknietym zleceniu i pustej stacji. '),
                    'active':('A','Aktywna kopia po APPLY; nie edytowac podczas produkcji. '),'runtime':('','Kontekst '+mode+'. ')}[parts[0]]
                add(ref,prefix+rp+alias,rd+desc)
            elif parts[0]=='control':
                alias,desc=data['flag',parts[1]];add(ref,prefix+alias,desc+' ON: opisany warunek/zadanie; OFF: brak.')
            elif parts[0]=='taught':
                n=int(parts[1][2:]);n=n+39 if mode=='BOX' and 2<=n<=40 else n
                add(ref,prefix+'NauczPR'+str(n),f'Potwierdzono nauke/odbior PR{n} dla {mode}. ON zatwierdzony; OFF ruch zablokowany.')
            elif parts[0]=='native':
                if parts[1] in ('box','tray'):
                    task=parts[1].upper();field=parts[2]
                    add(ref,task+('Praca' if field=='running' else 'Pauza'),f'Natywny MAIN_{task}: '+('wykonywany' if field=='running' else 'PAUSE')+'. ON tak, OFF nie; nie status PLC_SVC.')
                else:
                    alias,desc=data['native',parts[1]];add(ref,alias,desc+' ON tak; OFF nie. Wymaga odbioru V9.40.')
            elif name=='owner':add(ref,'WybranyMain','Jedyny pisarz BG_STATUS: 0 brak; 1 MAIN_BOX; 2 MAIN_TRAY. Nie wpisywac recznie.')
            elif ('flag',name) in data:
                alias,desc=data['flag',name]
                if name=='initApproved':desc='Jawna zgoda na wspolna inicjalizacje wyboru przy obu zakonczonych main, HOME i pustej rozliczonej stacji.'
                add(ref,alias,desc+' ON tak/zadanie; OFF nie.')
            else:raise AssertionError('Missing resource meaning: '+name)
        for key,point in m.get('points',{}).items():
            n=int(key);short='HOME' if n==1 else prefix+'P'+str(n)
            desc=point_meaning(point)
            if point not in ('OFFSET_WORK','SEARCH_WORK','POSE_WORK','RESERVE'):desc+=' Wspolrzedne do nauki/odbioru; zgodne UF/UT i konfiguracja osi.'
            add(f'PR[{n}]',short,desc)
    add('$FAST_CLOCK','ZegarSys','Odczyt zegara systemowego FANUC [surowe ticki]; czestotliwosc i zawijanie do odbioru V9.40.')
    return records
def describe_artifacts(art,manifests,com,mapping,export_folder):
    records=dictionary(manifests,com,mapping);used=set();result={}
    from fanuc_main import names
    for path,text in art.items():
        if path.suffix!='.LS':
            if path.name=='resources.json':
                obj=json.loads(text)
                for entry in obj['allocations']:
                    item=records[f'{entry["bank"]}[{entry["number"]}]']
                    entry.update(label=item['label'],comment=item['description'])
                obj['descriptions_file']=os.path.relpath(export_folder/'descriptions.csv',path.parent).replace('\\','/')
                text=json.dumps(obj,ensure_ascii=False,indent=2)+'\n'
            result[path]=text;continue
        text=names(text);name=re.search(r'/PROG (\w+)',text)[1];assert name in PROGRAMS,name
        seq=[z[1] for row in text.splitlines() if (z:=re.fullmatch(r'\s*\d+:\s*(.*?)\s*;',row))]
        out=['! '+PROGRAMS[name],'! Robot zada - PLC wykonuje Festo i EUROMAP'];seen=set()
        if name.startswith('MAIN_'):out+=['! Komendy operatora: INIT APPLY NEW RECOVERY EXIT',
            '! Nastawy S edytowane; A aktywne po APPLY','! Caly proces, ruchy i rozliczenia sa ponizej']
        elif name=='PLC_INIT':out+=['! Tylko pusty postoj; zatrzymac SVC i BG']
        for stmt in seq:
            if stmt.startswith('!'):out.append(stmt);continue
            for ref in dict.fromkeys(REF.findall(stmt)):
                base=re.sub(r',\d+\]',']',ref);assert base in records,(path.name,ref)
                used.add(base)
                if ref not in seen:
                    desc=records[base]['description']
                    if ',' in ref:desc='Skladowa '+{'1':'X','2':'Y','3':'Z','4':'W','5':'P','6':'R'}[re.search(r',(\d+)',ref)[1]]+' punktu. '+desc
                    out+=['! '+part for part in textwrap.wrap(ref+' - '+desc,width=76,break_long_words=False,break_on_hyphens=False)]
                    seen.add(ref)
            for key,desc in [('LPOS','Aktualna pozycja; LPOS-LPOS daje zerowy offset.'),
                ('UTOOL_NUM','Aktywny numer zatwierdzonego narzedzia.'),
                ('UFRAME_NUM','Aktywny numer zatwierdzonego ukladu wspolrzednych.'),
                ('UALM','Alarm procesu UALM[1]; reakcja zatrzymania wymaga odbioru.')]:
                if key in stmt and key not in seen:out.append('! '+key+' - '+desc);seen.add(key)
            def annotate(z,size=14):
                ref=z[0]
                if ref.startswith('$') or ',' in ref:return ref
                return ref[:-1]+':'+records[ref]['label'][:size]+']'
            rendered=REF.sub(annotate,stmt)
            assert len(rendered)<=254,(name,stmt)
            out.append(rendered)
        attrs=text.split('/MN')[0]
        attrs=re.sub(r'COMMENT = "[^"]*";','COMMENT = "'+ATTRIBUTES[name]+'";',attrs)
        # HandlingTool 8.30, section 8.19.6: standard remarks are 1..32 chars.
        # Keep ! plus a blank within the same conservative 32-character budget.
        short=[]
        for line in out:
            if line.startswith('!'):
                short.extend('! '+part for part in textwrap.wrap(line[1:].strip().replace(';',','),width=30,break_long_words=True,break_on_hyphens=False))
            else:short.append(line)
        out=short
        assert len(ATTRIBUTES[name])<=16,name
        assert all(len(v)<=32 for v in out if v.startswith('!')),name
        result[path.with_name(name+'.LS')]=attrs+'/MN\n'+'\n'.join(f'{i:4}:  {v} ;' for i,v in enumerate([v.replace(';',',') if v.startswith('!') else v for v in out],1))+'\n/POS\n/END\n'
    registry={r:records[r] for r in sorted(used)}
    result[export_folder/'descriptions.json']=json.dumps(dict(language='pl-ASCII-LS',resources=registry,programs=PROGRAMS),ensure_ascii=False,indent=2)+'\n'
    stream=io.StringIO(newline='');w=csv.DictWriter(stream,fieldnames=['address','label','description'],lineterminator='\n');w.writeheader()
    for ref,item in registry.items():w.writerow(item)
    result[export_folder/'descriptions.csv']=stream.getvalue()
    return result
