"""Run all read-only PLC/FANUC source checks. Never connects to a device."""
from __future__ import annotations
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import re
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
CHECKS=[
    ('build_plc_robot.py','--check'),
    ('check_plc_structure.py',),
    ('build_fanuc_comm.py','--check'),
    ('build_fanuc_tray.py','--check'),
    ('check_robot_contract.py',),
    ('check_plc_robot.py',),
    ('check_station.py',),
    ('check_station_integration.py',),
    ('check_plc_review.py',),
    ('check_fanuc_comm.py',),
    ('check_fanuc_tray.py',),
    ('check_fanuc_box.py',),
    ('check_fanuc_readability.py',),
]

def run(check):
    result=subprocess.run([sys.executable,'-B',str(ROOT/'tools'/check[0]),*check[1:]],
                          cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
    return check[0],result

def main():
    failed=[];tests=0
    with ThreadPoolExecutor(max_workers=4) as pool:
        for future in as_completed([pool.submit(run,check) for check in CHECKS]):
            name,result=future.result()
            combined=result.stdout+result.stderr
            match=re.search(r'Ran (\d+) tests?',combined)
            if match:tests+=int(match[1])
            print(('PASS' if result.returncode==0 else 'FAIL')+' '+name+
                  (f' ({match[1]} tests)' if match else ''),flush=True)
            if result.returncode:
                failed.append(name);print(combined,flush=True)
    print(f'{len(CHECKS)-len(failed)}/{len(CHECKS)} checks; {tests} behavior/readability tests',flush=True)
    print('NOT RUN: Machine Expert compile, native FANUC import, physical EIP/Festo/IMM and FAT/SAT')
    return bool(failed)

if __name__=='__main__':raise SystemExit(main())

