## This is description of a function block from Schneider Electric library

FUNCTION_BLOCK **Control_ATV**

The Control_ATV Function Block controls the Altivar drive using the Control Word, the Target Speed, the Status Word, the motor speed, the motor current and the control inputs.  

**How to use the Function Block:**  

- Remove the Free Wheel Command : i_xFreeWhl set at TRUE
- Remove the Quick Stop Command : i_xQckStop set at TRUE
- Enable the Function Block : i_xEn set at TRUE;
- Select, if the drive will stay in Operational Enabled if there is no command : i_xKeepOpEn set at TRUE;
- Set a target speed : i_wSpdRef not null;
- Then, start a Forward or Reverse command : i_xFwd or i_xRev set at TRUE

**Recommendations:**  

- If you want to use BRH4 function during the Altivar is controlled via the fieldbus please set the input i_xKeepOpEn to TRUE;
- After a Quick Stop Command, the mode Quick Stop (see the Altivar 71 Drive profile chart) is automatically left as soon as the motor Speed and Current have reached 0. To restart the motor, the Quick Stop input must be removed (negative logic, i_xQckStop must be TRUE);
- The Quick Stop command has a higher priority than a regular stop (Forward & Reverse set to FALSE);
- The Free Wheel Stop command has a higher priority than the Quick Stop command;
- After a download of an application to the controller, if the Drive displays a blinking 'COF' on the 7 segments display, set a rising edge, then a falling edge on the Fault Reset pin (i_xFltRst) to restart a proper communication with the drive;
- Please have a look to the Application Note for more information (in the folder 'Application Note')

|                   |          |                |         |         |                                                                  |
| ----------------- | -------- | -------------- | ------- | ------- | ---------------------------------------------------------------- |
| Name              | Type     | Inherited from | Address | Initial | Comment                                                          |
| **Axis**          | Axis_Ref |                |         |         | Axis reference                                                   |
| **i_xEn**         | BOOL     |                |         |         | Enables or disables the function block                           |
| **i_xKeepOpEn**   | BOOL     |                |         |         | Selector: keep drive in Operation Enabled if there is no command |
| **i_xFwd**        | BOOL     |                |         |         | Command to move forward                                          |
| **i_xRev**        | BOOL     |                |         |         | Commande to move reverse                                         |
| **i_xQckStop**    | BOOL     |                |         |         | Quick Stop command to the drive                                  |
| **i_xFreeWhl**    | BOOL     |                |         |         | Free Wheel Stop command to the drive                             |
| **i_xFltRst**     | BOOL     |                |         |         | Reset of errors on rising edge                                   |
| **i_wSpdRef**     | WORD     |                |         |         | Target Speed for the drive                                       |
| **q_xEn**         | BOOL     |                |         |         | Enable output                                                    |
| **q_xAlrm**       | BOOL     |                |         |         | Alarm output                                                     |
| **q_wStatusword** | WORD     |                |         |         | Copy of Status word                                              |     