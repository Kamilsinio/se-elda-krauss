"""Generate PLC v2 wire types/codecs from the canonical FANUC mapping. No devices."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LAYOUT = '58e7661e84feb471e528d2102f5ca6862b377241f160bf8f3f650dbcdaccb87e'

def field(identifier):
    return identifier.split('.', 1)[1].replace('.', '_')

def artifacts():
    contract = json.loads((ROOT/'docs/robot-plc-signals.json').read_text(encoding='utf-8'))
    mapping = json.loads((ROOT/'ROBOT/COMM/mapping.json').read_text(encoding='utf-8'))
    rows = mapping['signals']
    digest = hashlib.sha256(json.dumps(rows, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
    assert digest == mapping['layout_sha256'] == LAYOUT
    assert contract['contract_version'] == mapping['contract_version'] == 2
    by_id = {s['id']: s for s in contract['signals']}
    assert len(rows) == len(by_id) == 227 and set(by_id) == {s['id'] for s in rows}
    out = {}
    for prefix, name in [('r2p', 'ST_RobotRxV2'), ('p2r', 'ST_RobotTxV2')]:
        selected = [s for s in rows if s['id'].startswith(prefix+'.')]
        lines = ['(* GENEROWANE: tools/build_plc_robot.py; kontrakt v2. *)', 'TYPE '+name+' :', 'STRUCT']
        for s in selected:
            assert s['type'] == by_id[s['id']]['type']
            meaning = by_id[s['id']]['meaning'].replace('*)', '')
            lines += [f"    (* {s['id']}: {meaning} *)", f"    {field(s['id'])} : {s['type']};"]
        lines += ['END_STRUCT', 'END_TYPE', '']
        out[f'Modules/RobotInterface/DUTs/{name}.st'] = '\n'.join(lines)
    lines = ['(* GENEROWANE: jawny little endian, LSB0; bez aliasowania BOOL. *)',
             'FUNCTION_BLOCK FB_RobotCodec', 'VAR_INPUT',
             '    RawIn : ARRAY[0..79] OF BYTE;', '    Tx : ST_RobotTxV2;', 'END_VAR',
             'VAR_OUTPUT', '    Rx : ST_RobotRxV2;', '    RawOut : ARRAY[0..79] OF BYTE;', 'END_VAR',
             'VAR', '    rxWords : ARRAY[0..39] OF UINT;', '    txWords : ARRAY[0..39] OF UINT;', 'END_VAR']
    for i in range(40):
        lines += [f'rxWords[{i}] := TO_UINT(RawIn[{2*i}]) OR SHL(TO_UINT(RawIn[{2*i+1}]), 8);', f'txWords[{i}] := 0;']
    for s in rows:
        f = field(s['id']); w=s['word']; mask=f"16#{1 << s['bit']:04X}"
        if s['id'].startswith('r2p.'):
            value = f'rxWords[{w}]' if s['type']=='UINT' else f'(rxWords[{w}] AND {mask}) <> 0'
            lines.append(f'Rx.{f} := {value};')
        elif s['type']=='UINT':
            lines.append(f'txWords[{w}] := Tx.{f};')
        else:
            lines.append(f'IF Tx.{f} THEN txWords[{w}] := txWords[{w}] OR {mask}; END_IF;')
    for i in range(40):
        lines += [f'RawOut[{2*i}] := TO_BYTE(txWords[{i}] AND 16#00FF);', f'RawOut[{2*i+1}] := TO_BYTE(SHR(txWords[{i}], 8));']
    out['Modules/RobotCodec/FB_RobotCodec.st'] = '\n'.join(lines)+'\n'
    out['docs/plc-robot-wire.json'] = json.dumps({'contract_version':2, 'layout_sha256':LAYOUT,
        'bytes_per_direction':80, 'fields':{s['id']:field(s['id']) for s in rows}}, indent=2)+'\n'
    return out

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args=parser.parse_args()
    for name, source in artifacts().items():
        path=ROOT/name
        if args.check:
            assert path.exists() and path.read_text(encoding='utf-8')==source, 'Regenerate '+name
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(source, encoding='utf-8')
    print(('Checked' if args.check else 'Generated')+' 4 PLC wire artifacts; 227 fields; no devices')

if __name__=='__main__': main()
