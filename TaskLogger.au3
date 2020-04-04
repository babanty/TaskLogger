#cs ----------------------------------------------------------------------------

По горячим клавишам:
- делает плюс инкримент
- очистить счетчик
- указать сколько сейчас на считал

#ce ----------------------------------------------------------------------------

#include <Date.au3>
#include <File.au3>

; делает плюс инкримент
HotKeySet("!w", "Increment")
HotKeySet("!ц", "Increment")


; - указать сколько сейчас на считал
HotKeySet("!q", "Show")
HotKeySet("!й", "Show")

; - очистить счетчик
HotKeySet("!e", "OpenFileLog")
HotKeySet("!у", "OpenFileLog")

Global $AppName = "Инкрементатор"
Global $Num = 0
Global $StartedAt = _NowCalc()

Global $Tasks[20] ; массив с задачами. Задачи начинаются с 1
	For $i = 1 To UBound($Tasks) - 1
		$Tasks[$i] = ""
	Next
TraySetIcon(@ScriptDir & "\ico.ico"); меняем иконку в трее

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
	Local $oldLogs = DownloadLogs()

	if(Int($msgFromUser) > 0 AND Int($msgFromUser) < UBound($Tasks) - 1) Then
		Local $newLogs = $oldLogs & _DateTimeFormat( _NowCalc(), 4) & " - " & $Tasks[Int($msgFromUser)]

		SaveLogsToFile($newLogs)
	EndIf
EndFunc

Global $logsLabel = "-----------------------Логи-----------------------"
Func SaveLogsToFile($logs)
	Local $statistics = GetStatistics()

	Local $text = "--------------------Статистика--------------------"
	$text = $text & @CRLF & $statistics
	$text = $text & @CRLF & @CRLF & @CRLF
	$text = $text & @CRLF & $logsLabel
	$text = $text & @CRLF & $logs

	$filePath = GetActualLogFileName()

	FileDelete ( $filePath )
	$hFile = FileOpen($filePath, 2)
	FileWrite($hFile, $text)
	FileClose($hFile)
EndFunc


; Сформировать текст статистики
Func GetStatistics()
	Local $timeDiff_minute = _DateDiff('n',$StartedAt,_NowCalc())

	Local $text = "Текущий счет: " & $Num
	$text = $text & @CRLF & "Разница во времени: " & ($timeDiff_minute-Mod($timeDiff_minute, 60))/60 & " ч. " & Mod($timeDiff_minute, 60) & " мин."
	$text = $text & @CRLF & "Время старта: " & _DateTimeFormat($StartedAt, 0)

	Return $text
EndFunc


; Загрузить только логи без статистики из файла
Func DownloadLogs()
	if(FileExists (GetActualLogFileName())) Then
		; узнаем с какой строки начинаются логи
		Local $filePath = GetActualLogFileName()
		$logsStartLineNum = 0
		$countLines = _FileCountLines($filePath) ; всего строк в файле
		$hFile = FileOpen($filePath, 0)
		For $i = 1 To $countLines
			if(FileReadLine ( $hFile, $i) = $logsLabel) Then
				$logsStartLineNum = $i + 1
				ExitLoop
			EndIf
		Next

		; считываем логи с нужной строки
		Local $result = ""
		For $i = $logsStartLineNum To $countLines
			$result = $result & FileReadLine ( $hFile, $i) & @CRLF
		Next

		FileClose($hFile)

		Return $result
	Else
		Return ""
	EndIf
EndFunc

Func Show()
	Local $msg = GetStatistics()

	Local $logs = DownloadLogs()
	; последние 10 записей
	Local $logsArray =  StringSplit ( $logs, @CRLF , 2 ) ; строку из множество строк разделили на массив
	Local $lastTenEntriesString = "" ; последние 10 записей слепленные в одну строку
	Local $limitEntries = 10 ; ограничение по количеству отображаемых записей логов
	Local $entriesCounter = 0 ; счетчик числа уже заполненных логов
	for $i = UBound($logsArray) - 1 To 0 Step -1 ; перекидываем из массива с логами в строку с логами в обратном порядке, чтобы последние записи видеть
		if($logsArray[$i] <> "" AND $logsArray[$i] <> " " AND $logsArray[$i] <> 0) Then
			$lastTenEntriesString = $lastTenEntriesString & $logsArray[$i] & @CRLF
			$entriesCounter = $entriesCounter + 1
			If($entriesCounter >= $limitEntries) Then ; если пробито ограничение, по количеству записей для вывода на висуальное окно, то заканчиваем заполнять строку с логами
				ExitLoop
			EndIf
		EndIf
	Next

	$msg = $msg & @CRLF & $lastTenEntriesString

	MsgBox(0, $AppName, $msg)
EndFunc


Func OpenFileLog()
	$answer = MsgBox(1, $AppName, "Вы уверены, что хотите открыть файл логов?")
	if($answer = True) Then
		$filePath = GetActualLogFileName()
		if(FileExists($filePath)) Then
			$resultOpen = ShellExecute($filePath, "", "", "edit")
		Else
			MsgBox(0, $AppName, "Файл с логами на сегодняшний день не найден.")
		EndIf
	EndIf
EndFunc


Func GetActualLogFileName()
	Return @ScriptDir & "\Logs\" & @YEAR & "." & @MON & "." & @MDAY & "_log.txt"
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