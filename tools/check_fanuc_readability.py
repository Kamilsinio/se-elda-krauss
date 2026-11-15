"""Acceptance checks for readable FANUC delivery, independent of process scenarios."""
from __future__ import annotations
from collections import defaultdict
import json,re,unittest
from pathlib import Path
from unittest.mock import patch
import fanuc_descriptions as descriptions
import build_fanuc_tray
ROOT=Path(__file__).resolve().parents[1]
NUMERIC=re.compile(r'\b((?:PR|R|F|DI|DO|GI|GO|UO|SI|SO)\[\d+(?:,\d+)?)(?::([^\]]+))?\]')
class ReadabilityChecks(unittest.TestCase):
    def packages(self):
        for folder,registry in [('COMM','COMM'),('TEST/COMM','TEST/COMM'),('TRAY','COMMON'),('BOX','COMMON'),('BG','COMMON')]:
            records=json.loads((ROOT/'ROBOT'/registry/'descriptions.json').read_text(encoding='utf-8'))['resources']
            yield ROOT/'ROBOT'/folder,records
    def test_every_operand_is_named_and_explained_before_first_use(self):
        for folder,records in self.packages():
            for path in folder.glob('*.LS'):
                text=path.read_text(encoding='ascii');explained=set()
                self.assertLessEqual(len(re.search(r'COMMENT = "([^"]*)";',text)[1]),16)
                self.assertNotIn('COMMENT = "Krauss produkcja"',text)
                for row in text.splitlines():
                    m=re.fullmatch(r'\s*\d+:\s+(.*?)\s*;',row)
                    if not m:continue
                    stmt=m[1]
                    if stmt.startswith('!'):
                        self.assertLessEqual(len(stmt),32,(path.name,stmt))
                        for ref in re.findall(r'! ((?:PR|R|F|DI|DO|GI|GO|UO|SI|SO)\[\d+(?:,\d+)?\]|\$[A-Za-z_][A-Za-z0-9_.$\[\]]*|LPOS|UTOOL_NUM|UFRAME_NUM|UALM) -',stmt):explained.add(ref)
                        continue
                    for match in NUMERIC.finditer(stmt):
                        ref=match[1]+']';base=re.sub(r',\d+\]',']',ref)
                        self.assertIn(ref,explained,(path.name,ref,'missing nearby meaning'))
                        self.assertIn(base,records)
                        self.assertGreater(len(records[base]['description']),20)
                        if ',' not in ref:self.assertEqual(match[2],records[base]['label'],(path.name,ref))
                    for sys in re.findall(r'\$[A-Za-z_][A-Za-z0-9_.$\[\]]*',stmt):self.assertIn(sys,explained)
                    for builtin in ['LPOS','UTOOL_NUM','UFRAME_NUM','UALM']:
                        if builtin in stmt:self.assertIn(builtin,explained,(path.name,builtin))
    def test_short_labels_do_not_confuse_different_resources(self):
        for folder,records in self.packages():
            unique={}
            for ref,item in records.items():
                key=(ref.split('[')[0],item['label'])
                self.assertNotIn(key,unique,(folder,key,ref,unique.get(key)))
                unique[key]=ref
    def test_all_jumps_resolve_and_main_has_no_technology_calls_or_mailbox(self):
        for folder,_ in self.packages():
            for path in folder.glob('*.LS'):
                text=path.read_text(encoding='ascii')
                code='\n'.join(m[1] for row in text.splitlines() if (m:=re.fullmatch(r'\s*\d+:\s+(.*?)\s*;',row)) and not m[1].startswith('!'))
                labels=re.findall(r'(?<!JMP )\bLBL\[(\d+)\]',code)
                self.assertEqual(len(labels),len(set(labels)),path.name)
                self.assertTrue(set(re.findall(r'JMP LBL\[(\d+)\]',code))<=set(labels),path.name)
                if path.stem.startswith('MAIN_'):
                    self.assertTrue(set(re.findall(r'\bCALL (\w+)',code))<={'BG_BIND','PLC_REC'},path.name)
                    self.assertNotRegex(code,r'\bR\[33[2-9](?=:|\])|\bR\[34\d(?=:|\])')
        self.assertFalse(list((ROOT/'ROBOT/COMMON').glob('*.LS')))
    def test_missing_semantic_definition_prevents_generation(self):
        full=descriptions.catalogue();del full['field','state']
        with patch.object(descriptions,'catalogue',return_value=full):
            with self.assertRaises(KeyError):build_fanuc_tray.build()
if __name__=='__main__':unittest.main(verbosity=2)
