Devices := {}
IMMDeviceEnumerator := ComObjCreate("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
; IMMDeviceEnumerator::EnumAudioEndpoints
; eRender = 0, eCapture, eAll
; 0x1 = DEVICE_STATE_ACTIVE
DllCall(NumGet(NumGet(IMMDeviceEnumerator+0)+3*A_PtrSize), "UPtr", IMMDeviceEnumerator, "UInt", 0, "UInt", 0x1, "UPtrP", IMMDeviceCollection, "UInt")
ObjRelease(IMMDeviceEnumerator)

; IMMDeviceCollection::GetCount
DllCall(NumGet(NumGet(IMMDeviceCollection+0)+3*A_PtrSize), "UPtr", IMMDeviceCollection, "UIntP", Count, "UInt")
Loop % (Count)
{
    ; IMMDeviceCollection::Item
    DllCall(NumGet(NumGet(IMMDeviceCollection+0)+4*A_PtrSize), "UPtr", IMMDeviceCollection, "UInt", A_Index-1, "UPtrP", IMMDevice, "UInt")

    ; IMMDevice::GetId
    DllCall(NumGet(NumGet(IMMDevice+0)+5*A_PtrSize), "UPtr", IMMDevice, "UPtrP", pBuffer, "UInt")
    DeviceID := StrGet(pBuffer, "UTF-16"), DllCall("Ole32.dll\CoTaskMemFree", "UPtr", pBuffer)

    ; IMMDevice::OpenPropertyStore
    ; 0x0 = STGM_READ
    DllCall(NumGet(NumGet(IMMDevice+0)+4*A_PtrSize), "UPtr", IMMDevice, "UInt", 0x0, "UPtrP", IPropertyStore, "UInt")
    ObjRelease(IMMDevice)

    ; IPropertyStore::GetValue
    VarSetCapacity(PROPVARIANT, A_PtrSize == 4 ? 16 : 24)
    VarSetCapacity(PROPERTYKEY, 20)
    DllCall("Ole32.dll\CLSIDFromString", "Str", "{A45C254E-DF1C-4EFD-8020-67D146A850E0}", "UPtr", &PROPERTYKEY)
    NumPut(14, &PROPERTYKEY + 16, "UInt")
    DllCall(NumGet(NumGet(IPropertyStore+0)+5*A_PtrSize), "UPtr", IPropertyStore, "UPtr", &PROPERTYKEY, "UPtr", &PROPVARIANT, "UInt")
    DeviceName := StrGet(NumGet(&PROPVARIANT + 8), "UTF-16") ; LPWSTR PROPVARIANT.pwszVal
    DllCall("Ole32.dll\CoTaskMemFree", "UPtr", NumGet(&PROPVARIANT + 8)) ; LPWSTR PROPVARIANT.pwszVal
    ObjRelease(IPropertyStore)

    ObjRawSet(Devices, DeviceName, DeviceID)
}
ObjRelease(IMMDeviceCollection)

devNamesArray := {}
try{
    FileRead, devNames, %A_AppData%/SwitchAudio/devices.txt
}Catch{
    MsgBox, 0, Error, No existing device list, please create one
    EditDeviceList(Devices,"a`nb")
}
if(StrLen(devNames)=0){
    MsgBox 4,Warning, Empty audio device list, do you want to fill it?
    IfMsgBox Yes
    EditDeviceList(Devices,devNames)
}
StringSplit, devNamesArray,devNames,`n
Return

+F1:: SetDefaultEndpoint( GetDeviceID(Devices, devNamesArray1) )
+F2:: SetDefaultEndpoint( GetDeviceID(Devices, devNamesArray2) )
+F3:: SetDefaultEndpoint( GetDeviceID(Devices, devNamesArray3) )
+F4:: SetDefaultEndpoint( GetDeviceID(Devices, devNamesArray4) )
+F5:: SetDefaultEndpoint( GetDeviceID(Devices, devNamesArray5) )
+F6:: SetDefaultEndpoint( GetDeviceID(Devices, devNamesArray6) )
+F7:: SetDefaultEndpoint( GetDeviceID(Devices, devNamesArray7) )
+F8:: SetDefaultEndpoint( GetDeviceID(Devices, devNamesArray8) )
+F9:: SetDefaultEndpoint( GetDeviceID(Devices, devNamesArray9) )

F1 & F2::ShowDeviceList(devNames)
F1 & F3::EditDeviceList(Devices,devNames)

SetDefaultEndpoint(DeviceID)
{
    IPolicyConfig := ComObjCreate("{870af99c-171d-4f9e-af0d-e63df40c2bc9}", "{F8679F50-850A-41CF-9C72-430F290290C8}")
    DllCall(NumGet(NumGet(IPolicyConfig+0)+13*A_PtrSize), "UPtr", IPolicyConfig, "UPtr", &DeviceID, "UInt", 0, "UInt")
    ObjRelease(IPolicyConfig)
}

GetDeviceID(Devices, Name)
{
    if(StrLen(Name) <= 1){
        ToolTip, No device associated to this keybind
        SetTimer, RemoveToolTip, 2000
        return
    } 
    StringTrimRight, Name, Name, 1
    ToolTip, Switching audio output to %Name%...
    SetTimer, RemoveToolTip, 1000
    For DeviceName, DeviceID in Devices{
        If (InStr(DeviceName, Name))
            Return DeviceID
    }
    ToolTip, Cant find device %Name%. Edit file list.
    SetTimer, RemoveToolTip, 2000
    EditDeviceList(Devices,devNames)
}

RemoveToolTip:
    SetTimer, RemoveToolTip, Off
    ToolTip
return

EditDeviceList(Devices,devNames){
    ActualDevices(Devices,devNames)
    FileCreateDir, %A_AppData%/SwitchAudio/
    run notepad.exe %A_AppData%/SwitchAudio/devices.txt
    MsgBox, 0,Reload,Press ok to reload,
    Reload
}

ShowDeviceList(devNames){
    Gui, SelectedDeviceList:New
    Gui, SelectedDeviceList:Add,ListView,r20 w700 ,Keybind|Device
    loop, parse, devNames,`n,
    {
        if(StrLen(A_LoopField) > 1)
            LV_Add("","Shift + F"+A_Index ,A_LoopField)
    }
    Loop % LV_GetCount("Col") ; Auto-size each column to fit its contents.
        LV_ModifyCol(A_Index, "AutoHdr")

    Gui, Show
}

ActualDevices(Devices,devNames){
    Gui, ExistingDeviceList:New
    Gui, ExistingDeviceList:Add,ListView,-ReadOnly r20 w700,Bound|Name

    For DeviceName in Devices{
        Bound :="No"
        loop, parse, devNames,`n,
        { 
            if(StrLen(A_LoopField) > 1){
                StringTrimRight, dn, A_LoopField, 1
                if(InStr(DeviceName,dn))
                    Bound :="Yes"
            }
        }
        LV_Add("", Bound,DeviceName)
    }
    LV_ModifyCol(1,"Center")
    Loop % LV_GetCount("Col") ; Auto-size each column to fit its contents.
        LV_ModifyCol(A_Index, "AutoHdr")

    Gui, Show

}