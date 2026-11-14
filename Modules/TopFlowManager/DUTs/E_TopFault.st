{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_TopFault :
(
    NONE := 0,
    STOPPER_TIMEOUT := 10,
    MOVE_TIMEOUT := 20,
    ILLEGAL_COMMAND := 30,
    TRANSFER_HANDSHAKE_TIMEOUT := 40
);
END_TYPE
