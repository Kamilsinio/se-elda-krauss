"""Read-only audit of the symbolic FANUC/PLC contract; never configures devices."""
from __future__ import annotations
import csv
import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LEGACY = '../Robot M20iD/old/ROBOT'
ACTIONS = {'REPLACE', 'REPLACE_SEMANTICS', 'SPLIT', 'REMOVE', 'RESERVED',
           'SAFETY_REVIEW', 'PLC_OWNERSHIP', 'VERIFY_POSITION',
           'MISSING_DEPENDENCY', 'EXPORT_REQUIRED', 'EXTENSION_REQUIRED', 'REVIEW_BACKUP'}
NO_TARGET = {'REMOVE', 'RESERVED', 'SAFETY_REVIEW', 'MISSING_DEPENDENCY', 'EXPORT_REQUIRED',
             'EXTENSION_REQUIRED', 'REVIEW_BACKUP'}
EVENTS = ('blisterPicked', 'blisterPlaced', 'blisterFinished', 'spacerPlaced',
          'productsPlaced', 'samplesPlaced', 'layerFinished', 'stackFinished',
          'immPickupCompleted', 'rejectsPlaced')

def expected_sources(root: Path) -> dict[tuple[str, str], str]:
    expected = {}
    for path in sorted((root / LEGACY).glob('*.LS')):
        text = path.read_text(encoding='utf-8').split('/POS')[0]
        source = LEGACY + '/' + path.name
        for bank, number in re.findall(r'\b(DI|DO|RI|RO)\[(\d+)(?=[:\]])', text):
            expected[source, bank + number] = 'io'
        for name in set(re.findall(r'\bCALL\s+(\w+)', text)):
            expected[source, 'CALL:' + name] = 'call'
    gvl = (root / 'GVLs/GVL_Robot.st').read_text(encoding='utf-8')
    for name, body in re.findall(r'TYPE (ST_RobotFromPLC|ST_RobotToPLC)\s*:\s*STRUCT(.*?)END_STRUCT', gvl, re.S):
        # Read declarations, not address comments; changed comments must not hide a field.
        for field in re.findall(r'^\s*(\w+)\s*:\s*BOOL\s*;', body, re.M):
            expected['GVLs/GVL_Robot.st', name + '.' + field] = 'declaration'
    for line in (root / LEGACY / 'IOSTATE.DG').read_text(encoding='utf-8').splitlines():
        match = re.fullmatch(r'(DIN|DOUT|RI|RO)\[\s*(\d+)\][ \t]+(?:ON|OFF)[ \t]*(.*)', line)
        if match and match[3].strip():
            bank = {'DIN': 'DI', 'DOUT': 'DO', 'RI': 'RI', 'RO': 'RO'}[match[1]]
            expected[LEGACY + '/IOSTATE.DG', bank + str(int(match[2]))] = 'snapshot'
    return expected

def validate(root: Path, contract: dict, rows: list[dict]) -> list[str]:
    errors = []
    def check(condition, message):
        if not condition:
            errors.append(message)
    check(contract.get('contract_version') == 2, 'Unsupported contract version')
    check(contract.get('status') == 'SPECIFIED_NOT_DEPLOYED', 'Unexpected deployment status')
    signals = contract.get('signals', [])
    ids = [s.get('id', '') for s in signals]
    check(len(ids) == len(set(ids)), 'Duplicate signal ID')
    by_id = {s.get('id'): s for s in signals}
    required = {'id', 'direction', 'type', 'kind', 'meaning', 'owner', 'validity', 'on_invalid', 'hardware_address'}
    for s in signals:
        name = s.get('id', '<missing>')
        check(required <= s.keys(), f'Missing metadata: {name}')
        check(bool(re.fullmatch(r'(p2r|r2p)\.[A-Za-z0-9_.]+', name)), f'Invalid ID: {name}')
        expected = 'PLC_TO_ROBOT' if name.startswith('p2r.') else 'ROBOT_TO_PLC'
        check(s.get('direction') == expected, f'Wrong direction: {name}')
        check(s.get('type') in {'BOOL', 'UINT'}, f'Unsupported type: {name}')
        check(s.get('kind') in {'level', 'value', 'request', 'ack', 'result'}, f'Unsupported kind: {name}')
        check(s.get('validity') in {'BOOT', 'SESSION'}, f'Missing validity: {name}')
        check(s.get('hardware_address') is None, f'Unverified hardware address: {name}')
        for field in ('meaning', 'owner', 'on_invalid'):
            check(bool(str(s.get(field, '')).strip()), f'Empty {field}: {name}')
    for d in ('p2r', 'r2p'):
        for field in ('version', 'ready', 'heartbeat', 'syncRequest', 'syncAck'):
            check(d + '.link.' + field in by_id, f'Missing link field: {d}.{field}')
    for event in EVENTS:
        for d, suffix, kind in [('r2p', 'req', 'request'), ('p2r', 'ack', 'ack')]:
            key = f'{d}.event.{event}.{suffix}'
            check(key in by_id and by_id[key].get('kind') == kind, f'Missing event channel: {key}')
    for event in ('productsPlaced', 'samplesPlaced', 'rejectsPlaced'):
        for field in ('count', 'cycleId', 'stackId'):
            check(f'r2p.event.{event}.{field}' in by_id, f'Missing independent event payload: {event}.{field}')
    for name in ('p2r.imm.batchCount', 'p2r.production.startToken'):
        check(name in by_id and by_id[name].get('type') == 'UINT' and by_id[name].get('validity') == 'SESSION', 'Missing v2 cycle/start field: ' + name)
    for number in range(1, 6):
        for d, fields in [('r2p', ('cmdValid', 'hold', 'blowReq')), ('p2r', ('valid', 'ok', 'holdApplied', 'accepted', 'busy', 'blowAck', 'blowResult', 'reason'))]:
            for field in fields:
                check(f'{d}.vac.{number}.{field}' in by_id, f'Missing vacuum channel: {number}.{field}')
    for number in range(501, 506):
        for d, fields in [('r2p', ('home', 'work')), ('p2r', ('valid', 'atHome', 'atWork', 'acceptedHome', 'acceptedWork', 'busy', 'reason'))]:
            for field in fields:
                check(f'{d}.cyl.V{number}.{field}' in by_id, f'Missing cylinder channel: V{number}.{field}')
    keys = [(r.get('source'), r.get('signal')) for r in rows]
    check(len(keys) == len(set(keys)), 'Duplicate migration key')
    expected = expected_sources(root)
    for key in sorted(expected.keys() - set(keys)):
        errors.append('Uncovered source: ' + ':'.join(key))
    for key in sorted(set(keys) - expected.keys()):
        errors.append('Stale migration row: ' + ':'.join(key))
    for r in rows:
        key = r.get('source', '') + ':' + r.get('signal', '')
        action = r.get('action', '')
        check(action in ACTIONS, f'Unknown migration action: {key}')
        if r.get('source') == LEGACY + '/IOSTATE.DG':
            check(action != 'RESERVED', f'Described snapshot channel incorrectly reserved: {key}')
        targets = [v for v in r.get('target_ids', '').split(';') if v]
        check(bool(targets) or action in NO_TARGET, f'Empty target: {key}')
        check(len(targets) == len(set(targets)), f'Duplicate targets: {key}')
        for target in targets:
            check(target in by_id, f'Unknown migration target: {key} -> {target}')
        if action in {'SAFETY_REVIEW', 'MISSING_DEPENDENCY', 'EXPORT_REQUIRED', 'EXTENSION_REQUIRED', 'REVIEW_BACKUP', 'VERIFY_POSITION'}:
            check(bool(r.get('gap')), f'Missing blocking GAP: {key}')
    # Different meanings of DO17 must remain distinct even when both main programs change.
    for source, target in [(LEGACY + '/A01_F2679_TACKI.LS', 'r2p.event.blisterFinished.req'), (LEGACY + '/AAAA_MAIN_BOX_PRG.LS', 'r2p.event.layerFinished.req')]:
        check(any(r.get('source') == source and r.get('signal') == 'DO17' and r.get('target_ids') == target for r in rows), 'DO17 semantics lost: ' + source)
    for r in rows:
        if r.get('signal') == 'DO101':
            check(r.get('action') == 'SAFETY_REVIEW' and not r.get('target_ids'), 'Mould-area-free wrongly mapped as ordinary process IO')
    return errors

def load(root: Path = ROOT):
    contract = json.loads((root / 'docs/robot-plc-signals.json').read_text(encoding='utf-8'))
    with (root / 'docs/robot-plc-migration.csv').open(encoding='utf-8-sig', newline='') as stream:
        rows = list(csv.DictReader(stream))
    return contract, rows

def main() -> int:
    contract, rows = load()
    errors = validate(ROOT, contract, rows)
    for error in errors:
        print('ERROR:', error)
    if errors:
        return 1
    print(f"PASS static: {len(contract['signals'])} signal definitions; {len(rows)} migration rows")
    print('Sources:', dict(Counter(row['source'] for row in rows)))
    print('NOT RUN by this audit: PLC compile, FANUC import, protocol simulation, FAT/SAT')
    return 0

if __name__ == '__main__':
    sys.exit(main())
