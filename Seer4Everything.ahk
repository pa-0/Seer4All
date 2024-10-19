#Requires AutoHotkey v2.0

DetectHiddenText true
DetectHiddenWindows True
if(SubStr(A_AhkVersion, 1, 1) == "2")
    A_IsUnicode := 1

WM_COPYDATA := 0x004A
WM_LBUTTONDOWN := 0x0201

SEER_CLASS_NAME := "SeerWindowClass"
SEER_REQUEST_PATH := 4000
SEER_RESPONSE_PATH := 4001
SEER_IS_VISIBLE := 5004
SEER_INVOKE_W32 := 5000
SEER_INVOKE_W32_SEP := 5001

EVERYTHING_WIN_A := "EVERYTHING_(1.5a)"
EVERYTHING_WIN := "EVERYTHING"
EVERYTHING_LIST := "EVERYTHING_RESULT_LIST_FOCUS1"

ih := InputHook("L0 V")
ih.KeyOpt("{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Space}{LButton}", "N")
ih.OnKeyUp := onKey
ih.Start()

#HotIf WinActive("ahk_class " . EVERYTHING_WIN_A) || WinActive("ahk_class " . EVERYTHING_WIN)
~LButton:: {
    onKey(ih, 0, 0, 1)
}
#HotIf WinActive("ahk_class " . EVERYTHING_WIN_A) || WinActive("ahk_class " . EVERYTHING_WIN)
~RButton:: {
    onKey(ih, 0, 0, 2)
}

onKey(ih, vk, sc, m:=0) {
    key := ""
    etWin := WinActive("ahk_class " . EVERYTHING_WIN_A) || WinActive("ahk_class " . EVERYTHING_WIN)
    if (!etWin)
        goto ret
    OutputDebug("etWin: " . etWin . " ")
    key := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
    if(!key && m)
        key := m > 1 ? "RButton" : "LButton"
    OutputDebug("Key: " . key " ")
    etList := ControlGetHwnd(EVERYTHING_LIST, "ahk_id " . etWin)
    if (!etList)
        goto ret
    OutputDebug("etList: " . etList . " ")
    etPath := ControlGetText(etList)
    if (!etPath)
        goto ret
    OutputDebug("`netPath: " . etPath . "`n")
    seerWin := WinExist("ahk_class " . SEER_CLASS_NAME)
    OutputDebug("seerWin: " . seerWin . " ")
    seerVisible := getSeerState(seerWin)
    OutputDebug("seerVisible: " . seerVisible . " ")
    if(key == "Space" || (key && seerVisible)) {
        OutputDebug("Posting message to Seer ")
        seerCmd := copyDataStruct(SEER_INVOKE_W32, &etPath)
        seerRepl := SendMessage(WM_COPYDATA, seerWin, seerCmd.Ptr, , seerWin)
    }
ret:
    if(key)
        OutputDebug("`n")
}

getSeerState(seerWin) {
    strEmpty := ""
    seerCmd := copyDataStruct(SEER_IS_VISIBLE, &strEmpty)
    seerRepl := SendMessage(WM_COPYDATA, seerWin, seerCmd, , seerWin)
    return seerRepl
}

copyDataStruct(dwData, &lpData) {
    structCopyData := Buffer(3*A_PtrSize, 0)
    cbData := (StrLen(lpData) + 1) * (A_IsUnicode ? 2 : 1)
    NumPut("UInt", dwData, structCopyData,          A_PtrSize * 0) ; ULONG_PTR dwData;
    NumPut("UInt", cbData, structCopyData,          A_PtrSize * 1) ; DWORD     cbData;
    NumPut("UPtr", StrPtr(lpData), structCopyData,  A_PtrSize * 2) ; PVOID     lpData;
    return structCopyData
}