#cs ----------------------------------------------------------------------------

По горячим клавишам:
- делает плюс инкримент
- очистить счетчик
- указать сколько сейчас на считал

#ce ----------------------------------------------------------------------------

#include <Date.au3>

; делает плюс инкримент
HotKeySet("!w", "Increment")
HotKeySet("!ц", "Increment")


; - указать сколько сейчас на считал
HotKeySet("!q", "Show")
HotKeySet("!й", "Show")

; - очистить счетчик
HotKeySet("!e", "Clear")
HotKeySet("!у", "Clear")

Global $AppName = "Инкрементатор"
Global $Num = 0
Global $StartedAt = _NowCalc()
Global $Log = ""
Global $Tasks[20] ; массив с задачами. Задачи начинаются с 1
	For $i = 1 To UBound($Tasks) - 1
		$Tasks[$i] = ""
	Next

Func Increment()
	Local $msg = "Введите номер задачи или новую задачу [новая задача] или удалить задачу -[номер задачи]. Текущие задачи: "

	; докидываем в сообщение задачи с номерами
	$msg = $msg & @CRLF & TasksToString()

	Local $result = InputBox($AppName,  $msg)
	; если отмена или какая-то ошибка
	if(@error <> 0) Then
		Return
	EndIf

	; если удаляем задачу
	TryDeleteTask($result)

	; если добавляем задачу
	TryAddTask($result)

	; если указали задачу на которую переключились
	TryLogSwitchedTask($result)

	$Num = $Num + 1
EndFunc

; Список задач в строку
Func TasksToString()
	Local $result = ""

	For $i = 1 To UBound($Tasks) - 1
		If (StringLen($Tasks[$i]) > 0) Then

			if($i <> 1) Then
				$result = $result & @CRLF
			EndIf

			$result = $result & $i & " - " & $Tasks[$i]
		EndIf
	Next

	Return $result
EndFunc


; Удалеяем задачу, если это указано в задаче от юзера
Func TryDeleteTask($msgFromUser)
	if(StringLeft($msgFromUser, 2) = "-{") Then
		Local $taskNumStr = SerchText($msgFromUser, "-{", "}")
		Local $taskNum = Int($taskNumStr)

		if($taskNum < 1) Then ; не получилось распрасить номер
			Return
		EndIf

		$Tasks[$taskNum] = ""
	EndIf
EndFunc

Func TryAddTask($msgFromUser)
	if(StringLeft($msgFromUser, 2) = "==") Then
		; получаем задачу
		Local $task = StringRight($msgFromUser, StringLen($msgFromUser) - 2)
		Local $success = False
		; ищем свободное место в массиве с задачами и записываем туда задачу
		For $i = 1 To UBound($Tasks) - 1
			If ($Tasks[$i] = "") Then
				$Tasks[$i] = $task
				$success = True
				TryLogSwitchedTask($i); указываем, что переключились на новую задачу
				ExitLoop
			EndIf
		Next

		; если свободных мест не нашлось
		if($success = False) Then
			MsgBox(48, $AppName, "Нет свободных мест под задачи")
		EndIf
	EndIf
EndFunc


Func TryLogSwitchedTask($msgFromUser)
	if(Int($msgFromUser) > 0 AND Int($msgFromUser) < UBound($Tasks) - 1) Then
		$Log = $Log & @CRLF & _DateTimeFormat( _NowCalc(), 4) & " - " & $Tasks[Int($msgFromUser)]
	EndIf
EndFunc


Func Show()
	Local $timeDiff_minute = _DateDiff('n',$StartedAt,_NowCalc())

	Local $msg = "Текущий счет: " & $Num
	$msg = $msg & @CRLF & "Разница во времени: " & ($timeDiff_minute-Mod($timeDiff_minute, 60))/60 & " ч. " & Mod($timeDiff_minute, 60) & " мин."
	$msg = $msg & @CRLF & "Время старта: " & _DateTimeFormat($StartedAt, 0)

	$msg = $msg & @CRLF & $Log

	MsgBox(0, $AppName, $msg)
EndFunc


Func Clear()
	$answer = MsgBox(1, $AppName, "Вы уверены, что хотите очистить лог?")
	if($answer = 1) Then
		$Num = 0
		$StartedAt = _NowCalc()
		$Log = ""
	EndIf
EndFunc


While 1
	Sleep(30)

WEnd


#Region Из библиотек
Func SerchText($text, $data1, $data2, $symbol = 1) ; Ищет совпадения в тексте и выводит что между ними (массив)
	; $text = текст в котором производится поиск
	;$data1 = Слово откуда начанается искомый текст
	;$data2 = Слово которым заканчивается искомый текст
	;$simbol = Символ с которого начинается поиск
	Local $result
	$result = StringRegExp($text, $data1 & '(.*?)' & $data2, 1, $symbol) ; Поиск слова, последний параметр отвечает с какого знака искать
	If (UBound($result) = 0) Then
		Return ""
	Else
		Return $result[0]
	EndIf
EndFunc   ;==>SerchText
#Region Из библиотек