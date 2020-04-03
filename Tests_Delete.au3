#include <Date.au3>
;MsgBox(0, "", _DateTimeFormat( _NowCalc(), 6))

MsgBox(0, "", @ScriptDir & "Logs\" & @YEAR & "." & @MON & "." & @MDAY & "_log.txt")