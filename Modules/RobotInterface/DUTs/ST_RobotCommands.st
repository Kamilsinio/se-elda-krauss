(* PLC v2; brak przypisania sprzetowego. *)
TYPE ST_RobotCommands :
STRUCT
openOrder : BOOL;
    endOrder : BOOL;
    program_ : UINT;
    manual : BOOL;
    automatic : BOOL;
    robotEnable : BOOL;
    robotDisable : BOOL;
    reset : BOOL;
    recover : BOOL;
    newEmptyContext : BOOL;
    applyQuantity : BOOL;
    quantity : UINT;
    samples : BOOL;
END_STRUCT
END_TYPE
