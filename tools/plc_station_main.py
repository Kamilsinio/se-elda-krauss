"""Execute PRG_Main offline. GIATV, I/O and safety are explicitly synthetic."""
from __future__ import annotations
import re
from check_station import station_runtime
from plc_st_runtime import Parser, Instance

class MainCell:
    def __init__(self):
        self.r=station_runtime();r=self.r
        r.load('tools/fixtures/NativeAtv.st')
        r.definitions['GIATV.Control_ATV']=r.definitions['NativeAtv']
        r.load('Modules/StationController/FB_StationController.st','Modules/ElevatorDriveAdapter/FB_ElevatorDriveAdapter.st','Modules/Conveyor/FB_Conveyor.st','Modules/Elevator/FB_Elevator.st',
               'Modules/SafetyDoor/FB_SafetyDoor.st','Modules/PRG_IO_Read.st',
               'Modules/PRG_IO_Write.st','Modules/Vijeo/FB_VijeoRead.st',
               'Modules/Vijeo/FB_VijeoPublish.st','Modules/PRG_Main.st')
        self.g={}
        for name in ['GVL_IO_RAW','GVL_IO','GVL_HMI','GVL_Robot','GVL_RobotRetain','GVL_Station','GVL_Festo']:
            text=(r.root/'GVLs'/f'{name}.st').read_text(encoding='utf-8')
            text=re.sub(r'\bAT\s+%[A-Za-z0-9.]+','',text)
            for match in re.finditer(r'\bTYPE\s+\w+\s*:.*?\bEND_TYPE',text,re.S):r.load_type(match[0])
            rows=[]
            for match in re.finditer(r'\bVAR_GLOBAL(?:\s+PERSISTENT\s+RETAIN|\s+CONSTANT)?\s+(.*?)END_VAR',text,re.S):
                rows.extend(Parser(match[1]+' END_VAR').declarations())
            r.types['ST_Test_'+name]=rows;self.g[name]=r.value('ST_Test_'+name)
        self.g['Altivar_320']=False
        self.g['PRG_IO_Read']=r.instance('PRG_IO_Read');self.g['PRG_IO_Write']=r.instance('PRG_IO_Write')
        self.main=r.instance('PRG_Main')
        seen=set()
        def bind(instance):
            if id(instance) in seen:return
            seen.add(id(instance))
            children=[v for v in instance.v.values() if isinstance(v,Instance)]
            instance.v.update(self.g)
            for child in children:bind(child)
        bind(self.main)
        for name in ['PRG_IO_Read','PRG_IO_Write']:bind(self.g[name])
    def scan(self):self.main.run()
