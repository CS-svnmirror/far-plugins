{$I Defines.inc}

unit MacroLibMain;

{******************************************************************************}
{* (c) 2011 Max Rusov                                                         *}
{*                                                                            *}
{* FAR Macro Library                                                          *}
{******************************************************************************}

{
Ready
  +����������

ToDo:
  -������ ����������� Realses ����� Hold (���� shift ��������� ������)

  - ������������ �� ���������� ��������
  - ��������������� #AKeyName

  +��������� ����-�����
    - ����� ������ ��������
  -������� � ���� ��������
}

interface

  uses
    Windows,
    MixTypes,
    MixUtils,
    MixStrings,
    MixClasses,
    MixWinUtils,

   {$ifdef Far3}
    Plugin3,
   {$else}
    PluginW,
   {$endif Far3}
    FarCtrl,
    FarMenu,

    MacroLibConst,
    MacroLibClasses,
    MacroParser,
    MacroListDlg;


 {$ifdef Far3}
  procedure GetGlobalInfoW(var AInfo :TGlobalInfo); stdcall;
  procedure ExitFARW(const AInfo :TExitInfo); stdcall;
  procedure SetStartupInfoW(var AInfo :TPluginStartupInfo); stdcall;
  procedure GetPluginInfoW(var AInfo :TPluginInfo); stdcall;
  function OpenW(var AInfo :TOpenInfo): THandle; stdcall;
  function ConfigureW(const AInfo :TConfigureInfo) :Integer; stdcall;
  function ProcessSynchroEventW(const AInfo :TProcessSynchroEventInfo) :Integer; stdcall;
  function ProcessDialogEventW(const AInfo :TProcessDialogEventInfo) :Integer; stdcall;
  function ProcessEditorEventW(const AInfo :TProcessEditorEventInfo) :Integer; stdcall;
  function ProcessViewerEventW(const AInfo :TProcessViewerEventInfo) :Integer; stdcall;
 {$ifdef bUseProcessConsoleInput}
  function ProcessConsoleInputW(const AInfo :TProcessConsoleInputInfo) :Integer; stdcall;
 {$endif bUseProcessConsoleInput}
 {$else}
  function GetMinFarVersionW :Integer; stdcall;
  procedure ExitFARW; stdcall;
  procedure SetStartupInfoW(var AInfo :TPluginStartupInfo); stdcall;
  procedure GetPluginInfoW(var AInfo :TPluginInfo); stdcall;
  function OpenPluginW(OpenFrom: integer; Item: INT_PTR): THandle; stdcall;
  function ConfigureW(Item: integer) :Integer; stdcall;
  function ProcessSynchroEventW(Event :integer; Param :Pointer) :Integer; stdcall;
  function ProcessDialogEventW(AEvent :Integer; AParam :PFarDialogEvent) :Integer; stdcall;
  function ProcessEditorEventW(AEvent :Integer; AParam :Pointer) :Integer; stdcall;
  function ProcessViewerEventW(AEvent :Integer; AParam :Pointer) :Integer; stdcall;
 {$endif Far3}


{******************************************************************************}
{******************************} implementation {******************************}
{******************************************************************************}

  uses
    MixDebug;


 {-----------------------------------------------------------------------------}
 { Injecting Support                                                           }
 {-----------------------------------------------------------------------------}

 {$ifdef bUseInject}

  const
    ImagehlpLib = 'IMAGEHLP.DLL';

  function ImageDirectoryEntryToData(Base :Pointer; MappedAsImage :ByteBool;
    DirectoryEntry :Word; var Size: ULONG): Pointer; stdcall; external ImagehlpLib name 'ImageDirectoryEntryToData';


  function FindImport(AHandle :THandle; ADllName :PAnsiChar) :PIMAGE_IMPORT_DESCRIPTOR;
  var
    vImport :PIMAGE_IMPORT_DESCRIPTOR;
    vName :PAnsiChar;
    vSize :ULONG;
  begin
    Result := nil;
    vImport := ImageDirectoryEntryToData(Pointer(AHandle), True, IMAGE_DIRECTORY_ENTRY_IMPORT, vSize);
    if vImport <> nil then begin
      while vImport.OriginalFirstThunk <> 0 do begin
        vName := PAnsiChar(AHandle + vImport.Name);
        if lstrcmpiA(vName, ADllName) = 0 then begin
          Result := vImport;
          Exit;
        end;
        Inc(vImport);
      end;
    end;
  end;


  function InjectFunc(AFuncPtr :PPointer; ANewFunc :Pointer) :Pointer;
  var
    vMem :MEMORY_BASIC_INFORMATION;
    vTmp :DWORD;
  begin
    VirtualQuery(AFuncPtr, vMem, SizeOf(MEMORY_BASIC_INFORMATION));
    VirtualProtect(vMem.BaseAddress, vMem.RegionSize, PAGE_READWRITE, @vTmp);
    Result := AFuncPtr^;
    AFuncPtr^ := ANewFunc;
    VirtualProtect(vMem.BaseAddress, vMem.RegionSize, vTmp, @vTmp);
  end;


  function InjectHandler(AHandle :THandle; AImport :PIMAGE_IMPORT_DESCRIPTOR; AFuncName :PAnsiChar; var AFuncPtr :PPointer; var AOldFunc :Pointer; ANewFunc :Pointer) :Boolean;
  var
    vThunk, vThunk2 :PIMAGE_THUNK_DATA;
    vName :PAnsiChar;
  begin
    Result := False;

    vThunk := Pointer(AHandle + AImport.FirstThunk);
    vThunk2 := Pointer(AHandle + AImport.OriginalFirstThunk);

    while vThunk._Function <> 0 do begin
      vName := Pointer(AHandle + vThunk2.AddressOfData + 2);
      if lstrcmpiA(vName, AFuncName) = 0 then
        Break;
      Inc(vThunk);
      Inc(vThunk2);
    end;

    if vThunk._Function <> 0 then begin
//    TraceF('Injected: %s', [AFuncName]);
      AFuncPtr := @Pointer(vThunk._Function);
      AOldFunc := InjectFunc(AFuncPtr, ANewFunc);
      Result := True;
    end;
  end;


  procedure RemoveHandler(var AFuncPtr :PPointer; AOldFunc :Pointer; ANewFunc :Pointer);
  begin
    if (AFuncPtr <> nil) {and (AFuncPtr^ = ANewFunc)} then begin
//    TraceF('RemoveHandlers... Old=%p', [AOldFunc]);
      InjectFunc(AFuncPtr, AOldFunc);
      AFuncPtr := nil;
    end;
  end;


 {-----------------------------------------------------------------------------}

  var
//  OldPeekConsoleInputW :function(hConsoleInput :THandle; var lpBuffer: TInputRecord;
//    nLength :DWORD; var lpNumberOfEventsRead :DWORD): BOOL; stdcall;
    OldReadConsoleInputW :function(hConsoleInput :THandle; var lpBuffer: TInputRecord;
      nLength :DWORD; var lpNumberOfEventsRead :DWORD): BOOL; stdcall;
//  PeekConsoleInputPtr :PPointer;
    ReadConsoleInputPtr :PPointer;


  procedure ClearKeyEvent(var ARec :TKeyEventRecord);
  begin
    { ������� �� ����� ���������� FAR'�� }
    ARec.wVirtualKeyCode := 0 {VK_NONAME};
    ARec.wVirtualScanCode := 0;
    ARec.dwControlKeyState := 0;
    ARec.UnicodeChar := #0;
    ARec.wRepeatCount := 0;
  end;

  procedure ClearMouseEvent(var ARec :TMouseEventRecord);
  begin
    { ������� �� ����� ���������� FAR'�� }
    ARec.dwEventFlags := 0;
    ARec.dwButtonState := 0;
    ARec.dwControlKeyState := 0;
    ARec.dwMousePosition.X := 0;
    ARec.dwMousePosition.Y := 0;
  end;

(*
  function MyPeekConsoleInputW(hConsoleInput :THandle; var lpBuffer: TInputRecord;
    nLength :DWORD; var lpNumberOfEventsRead :DWORD): BOOL; stdcall;
  var
    I :Integer;
    P :PInputRecord;
  begin
    Result := OldPeekConsoleInputW(hConsoleInput, lpBuffer, nLength, lpNumberOfEventsRead);
    if Result and (lpNumberOfEventsRead > 0) and opt_ProcessHotkey then begin
//    TraceF('MyPeekConsoleInputW (Events=%d)', [lpNumberOfEventsRead]);
      P := @lpBuffer;
      for I := 0 to lpNumberOfEventsRead - 1 do begin
        if P.EventType = KEY_EVENT then begin
          if MacroLibrary.CheckHotkey(P.Event.KeyEvent, False) then
            ClearKeyEvent(P.Event.KeyEvent);
        end;
        Inc(Pointer1(P), SizeOf(TInputRecord));
      end;
    end;
  end;
*)

  function MyReadConsoleInputW(hConsoleInput :THandle; var lpBuffer: TInputRecord;
    nLength :DWORD; var lpNumberOfEventsRead :DWORD): BOOL; stdcall;
  var
    I :Integer;
    P :PInputRecord;
  begin
    Result := OldReadConsoleInputW(hConsoleInput, lpBuffer, nLength, lpNumberOfEventsRead);
    if Result and (lpNumberOfEventsRead > 0) then begin
//    TraceF('MyReadConsoleInputW (Events=%d)', [lpNumberOfEventsRead]);

      P := @lpBuffer;
      for I := 0 to lpNumberOfEventsRead - 1 do begin
        if (P.EventType = KEY_EVENT) and optProcessHotkey and (FarGetMacroState = MACROSTATE_NOMACRO) then begin
          if MacroLibrary.CheckHotkey(P.Event.KeyEvent) then
            ClearKeyEvent(P.Event.KeyEvent);
        end else
        if (P.EventType = _MOUSE_EVENT) and optProcessMouse and (FarGetMacroState = MACROSTATE_NOMACRO) then begin
          if MacroLibrary.CheckMouse(P.Event.MouseEvent) then
            ClearMouseEvent(P.Event.MouseEvent);
        end;
        Inc(Pointer1(P), SizeOf(TInputRecord));
      end;
    end;
  end;


  procedure InjectHandlers;
  var
    vHandle :THandle;
    vImport :PIMAGE_IMPORT_DESCRIPTOR;
  begin
    vHandle := GetModuleHandle(nil);
    vImport := FindImport(vHandle, kernel32);
    if vImport <> nil then begin
      InjectHandler(vHandle, vImport, 'ReadConsoleInputW', ReadConsoleInputPtr, @OldReadConsoleInputW, @MyReadConsoleInputW);
//    InjectHandler(vHandle, vImport, 'PeekConsoleInputW', PeekConsoleInputPtr, @OldPeekConsoleInputW, @MyPeekConsoleInputW);
    end;
  end;


  procedure RemoveHandlers;
  begin
    RemoveHandler(ReadConsoleInputPtr, @OldReadConsoleInputW, @MyReadConsoleInputW);
//  RemoveHandler(PeekConsoleInputPtr, @OldPeekConsoleInputW, @MyPeekConsoleInputW);
  end;
 {$endif bUseInject}


 {-----------------------------------------------------------------------------}
 {                                                                             }
 {-----------------------------------------------------------------------------}

  procedure OptionsMenu;
  var
    vMenu :TFarMenu;
  begin
    vMenu := TFarMenu.CreateEx(
      GetMsg(strTitle),
    [
      GetMsg(strMProcessHotkeys),
      GetMsg(strMProcessMouse),
      GetMsg(strMMacroPaths)
    ]);
    try
      vMenu.Help := 'Options';
      
      while True do begin
        vMenu.Checked[0] := optProcessHotkey;
        vMenu.Checked[1] := optProcessMouse;

        vMenu.SetSelected(vMenu.ResIdx);

        if not vMenu.Run then
          Exit;

        case vMenu.ResIdx of
          0 : ToggleOption(optProcessHotkey);
          1 : ToggleOption(optProcessMouse);
          2 :
            if FarInputBox(GetMsg(strMacroPathsTitle), GetMsg(strMacroPathsPrompt), optMacroPaths, FIB_BUTTONS or FIB_NOUSELASTHISTORY or FIB_ENABLEEMPTY, cMacroPathName) then begin
              PluginConfig(True);
              MacroLibrary.RescanMacroses(True);
            end;
        end;
      end;

    finally
      FreeObj(vMenu);
    end;
  end;


  procedure MainMenu;
  var
    vMenu :TFarMenu;
  begin
    vMenu := TFarMenu.CreateEx(
      GetMsg(strTitle),
    [
      GetMsg(strMMacroCommands),
      '',
      GetMsg(strMListOfAllMacroses),
      GetMsg(strMUpdateMacroses),
      '',
      GetMsg(strMOptions)
    ]);
    try
      vMenu.Help := 'MainMenu';

      if MacroLock > 0 then
        vMenu.Items[3].Flags := vMenu.Items[3].Flags or MIF_DISABLE;

      if not vMenu.Run then
        Exit;

      case vMenu.ResIdx of
        0 : FarAdvControl(ACTL_SYNCHRO, nil); //MacroLibrary.ShowAvailable;

        2 : MacroLibrary.ShowAll;
        3 : MacroLibrary.RescanMacroses(False);

        5 : OptionsMenu;
      end;

    finally
      FreeObj(vMenu);
    end;
  end;


 {-----------------------------------------------------------------------------}

  const
    kwCall  = 1;
    kwKey   = 2;

  var
    CmdWords :TKeywordsList;

  procedure InitKeywords;
  begin
    if CmdWords <> nil then
      Exit;

    CmdWords := TKeywordsList.Create;
    with CmdWords do begin
      Add('Call', kwCall);
      Add('Key', kwKey);
    end;
  end;


  procedure CmdCall(const AName :TString);
  var
    vMacro :TMacro;
  begin
//  TraceF('Run: %s', [AName]);
    if AName = '' then
      AppErrorId(strMacroNotSpec);

    vMacro := MacroLibrary.FindMacroByName(AName);
    if vMacro = nil then
      AppErrorIdFmt(strMacroNotFound, [AName]);

    vMacro.Execute(0);
  end;


  procedure CmdKey(const AName :TString);
  var
    vList :TExList;
    vKey :Integer;
    vMod :TKeyModifier;
    vArea :TMacroArea;
    vPress :TKeyPress;
    vEat :Boolean;
  begin
//  TraceF('Run: %s', [AName]);
    if AName = '' then
      AppErrorId(strKeyNotSpec);

    if not KeyNameParse(PTChar(AName), vKey, vMod) then
      AppErrorIdFmt(strUnknownKeyName, [AName]);

    vList := TExList.Create;
    try
      vArea := TMacroArea(FarGetMacroArea);

      vPress := kpAll;
      case vMod of
        kmSingle  : vPress := kpDown;
        kmDouble  : vPress := kpDouble;
        kmHold    : vPress := kpHold;
        kmRelease : vPress := kpUp;
      end;

      MacroLibrary.FindMacroses(vList, vArea, vKey, vPress, vEat);

      if vList.Count > 0 then begin
        if vList.Count = 1 then
          TMacro(vList[0]).Execute(vKey)
        else
          MacroLibrary.ShowList(vList);
      end;
      
    finally
      FreeObj(vList);
    end;
  end;


  procedure OpenCmdLine(AChr :PTChar);
  var
    vStr :TString;
    vKey :Integer;
  begin
    if (AChr = nil) or (AChr^ = #0) then
      MacroLibrary.ShowAll
    else begin
      InitKeywords;
      while AChr^ <> #0 do begin
        vStr := ExtractParamStr(AChr);
        vKey := CmdWords.GetKeywordStr(vStr);
        case vKey of
          kwCall: CmdCall(ExtractParamStr(AChr));
          kwKey:  CmdKey(ExtractParamStr(AChr));
        else
          AppErrorFmt('Unknown command: %s', [vStr]);
        end;
      end;
    end;
  end;


  procedure Open(AFrom :Integer; AStr :PTChar);
  begin
    if AFrom and OPEN_FROMMACRO <> 0 then begin

      if AFrom and OPEN_FROMMACROSTRING <> 0 then
        OpenCmdLine(AStr)
      else
        FarAdvControl(ACTL_SYNCHRO, nil);

    end else
    if AFrom = OPEN_COMMANDLINE then
      OpenCmdLine(AStr)
    else
      MainMenu;
  end;


  procedure Process(AObj :TObject);
  var
    I :Integer;
  begin
    if MacroLibrary = nil then
      Exit;

    if AObj = nil then
      MacroLibrary.ShowAvailable
    else
    if AObj is TMacro then
      TMacro(AObj).Execute(0)
    else
    if (AObj is TRunList) and ((TRunList(AObj).Count = 1) or TRunList(AObj).RunAll) then begin
      with TRunList(AObj) do
        for I := 0 to Count - 1 do
          TMacro(Items[I]).Execute(KeyCode);
      FreeObj(AObj);
    end else
    if AObj is TExList then begin
      MacroLibrary.ShowList(TExList(AObj));
      FreeObj(AObj);
    end else
    if AObj is TRunEvent then begin
      with TRunEvent(AObj) do begin

        if Area = maShell then
          { ���������� ������� ������������� �������� �� ������ ����. }
          { ���� �������� MCTL_ADDMACRO �� �������� ������������� - Far ������ }
          MacroLibrary.RescanMacroses(True);

        if FarGetMacroState = MACROSTATE_NOMACRO then
          MacroLibrary.CheckEvent(Area, Event);
      end;
      FreeObj(AObj);
    end;
  end;


 {-----------------------------------------------------------------------------}
 { �������������� ���������                                                    }
 {-----------------------------------------------------------------------------}

 {$ifdef Far3}
  procedure GetGlobalInfoW;
  begin
    AInfo.StructSize := SizeOf(AInfo);
    AInfo.MinFarVersion := MakeFarVersion(FARMANAGERVERSION_MAJOR, FARMANAGERVERSION_MINOR, FARMANAGERVERSION_REVISION, FARMANAGERVERSION_BUILD, VS_RELEASE);
  //AInfo.Info := PLUGIN_VERSION;
    AInfo.GUID := cPluginID;
    AInfo.Title := cPluginName;
    AInfo.Description := cPluginDescr;
    AInfo.Author := cPluginAuthor;
  end;
 {$else}
  function GetMinFarVersionW :Integer; stdcall;
  begin
//  Result := MakeFarVersion(2, 0, 1765);   { MCMD_GETAREA };
    Result := MakeFarVersion(2, 0, 1800);   { OPEN_FROMMACROSTRING, MCMD_POSTMACROSTRING };
  end;
 {$endif Far3}


  procedure SetStartupInfoW;
  begin
    FARAPI := AInfo;
    FARSTD := AInfo.fsf^;

   {$ifdef Far3}
    PluginID := cPluginID;
   {$else}
    hModule := AInfo.ModuleNumber;
   {$endif Far3}

    FFarExePath := AddBackSlash(ExtractFilePath(GetExeModuleFileName));

    RestoreDefColor;
    PluginConfig(False);

    MacroLibrary := TMacroLibrary.Create;

   {$ifdef bUseInject}
    InjectHandlers;
   {$endif bUseInject}

//  MacroLibrary.RescanMacroses(True);
//  MacroLibrary.CheckEvent(maShell, meOpen);
  end;


  var
    PluginMenuStr  :TString;
   {$ifdef Far3}
    PluginMenuGUID :TGUID;
   {$endif Far3}

  procedure GetPluginInfoW;
  begin
//  TraceF('GetPluginInfo: %s', ['']);

    AInfo.StructSize:= SizeOf(AInfo);
    AInfo.Flags:= PF_PRELOAD or PF_EDITOR or PF_VIEWER or PF_DIALOG;

    PluginMenuStr := GetMsg(strTitle);
   {$ifdef Far3}
    PluginMenuGUID := cMenuID;
    AInfo.PluginMenu.Count := 1;
    AInfo.PluginMenu.Strings := Pointer(@PluginMenuStr);
    AInfo.PluginMenu.Guids := Pointer(@PluginMenuGUID);

    AInfo.PluginConfig.Count := 1;
    AInfo.PluginConfig.Strings := Pointer(@PluginMenuStr);
    AInfo.PluginConfig.Guids := Pointer(@PluginMenuGUID);
   {$else}
    AInfo.PluginMenuStringsNumber := 1;
    AInfo.PluginMenuStrings := Pointer(@PluginMenuStr);

    AInfo.PluginConfigStringsNumber := 1;
    AInfo.PluginConfigStrings := Pointer(@PluginMenuStr);

    AInfo.Reserved := cPluginGUID;
   {$endif Far3}

    if optCmdPrefix <> '' then
      AInfo.CommandPrefix := PTChar(optCmdPrefix);

    FarAdvControl(ACTL_SYNCHRO, TRunEvent.CreateEx(meOpen, maShell));
  end;


  procedure ExitFARW;
  begin
//  Trace('ExitFAR');
   {$ifdef bUseInject}
    RemoveHandlers;
   {$endif bUseInject}
    FreeObj(MacroLibrary);
  end;

 {$ifdef Far3}
  function OpenW;
 {$else}
  function OpenPluginW;
 {$endif Far3}
  begin
    Result:= INVALID_HANDLE_VALUE;
    try
     {$ifdef Far3}
      Open(AInfo.OpenFrom, PTChar(AInfo.Data));
     {$else}
      Open(OpenFrom, PTChar(Item));
     {$endif Far3}
    except
      on E :Exception do
        HandleError(E);
    end;
  end;


  function ConfigureW;
  begin
    Result := 1;
    try
      OptionsMenu;
    except
      on E :Exception do
        HandleError(E);
    end;
  end;


  function ProcessSynchroEventW;
  begin
    Result := 0;
   {$ifdef Far3}
    if AInfo.Event = SE_COMMONSYNCHRO then
      Process(AInfo.Param);
   {$else}
    if Event = SE_COMMONSYNCHRO then
      Process(Param);
   {$endif Far3}
  end;


  function ProcessEditorEventW;
  begin
   {$ifdef Far3}
    if AInfo.Event = EE_READ then
   {$else}
    if AEvent = EE_READ then
   {$endif Far3}
//    MacroLibrary.CheckEvent(maEditor, meOpen);
      FarAdvControl(ACTL_SYNCHRO, TRunEvent.CreateEx(meOpen, maEditor));
//  EE_GOTFOCUS...
    Result := 0;
  end;


  function ProcessViewerEventW;
  begin
   {$ifdef Far3}
     if AInfo.Event = VE_READ then
   {$else}
    if AEvent = VE_READ then
   {$endif Far3}
//    MacroLibrary.CheckEvent(maViewer, meOpen);
      FarAdvControl(ACTL_SYNCHRO, TRunEvent.CreateEx(meOpen, maViewer));
    Result := 0;
  end;


  function ProcessDialogEventW;
  begin
   {$ifdef Far3}
    if (AInfo.Event = DE_DLGPROCEND) and (AInfo.Param.Msg = DN_INITDIALOG) then
   {$else}
    if (AEvent = DE_DLGPROCEND) and (AParam.Msg = DN_INITDIALOG) then
   {$endif Far3}
      FarAdvControl(ACTL_SYNCHRO, TRunEvent.CreateEx(meOpen, maDialog));

   {$ifdef Far3}
   {$else}
    { ���� ���� �������� ����� � Far2, ����� �������� Handle �������, }
    { ������� ������������ ��� ��������� GUID }
    if AEvent = DE_DLGPROCEND then
      if AParam.Msg = DN_INITDIALOG then begin
//      TraceF('InitDialog: %d', [AParam.hDlg]);
        PushDlg(AParam.hDlg);
      end else
      if (AParam.Msg = DN_CLOSE) and (AParam.Result <> 0) then begin
//      TraceF('CloseDialog: %d', [AParam.hDlg]);
        PopDlg(AParam.hDlg);
      end;
   {$endif Far3}

    Result := 0;
  end;


 {$ifdef bUseProcessConsoleInput}

  function ProcessConsoleInputW;
  begin
//  TraceF('ProcessConsoleInputW: Flags=%d', [AInfo.Flags]);
    Result := 0;
//  if AInfo.Flags and PCIF_FROMMAIN <> 0 then begin
      if (AInfo.Rec.EventType = KEY_EVENT) and optProcessHotkey and (FarGetMacroState = MACROSTATE_NOMACRO) then begin
        if MacroLibrary.CheckHotkey(AInfo.Rec.Event.KeyEvent) then
          Result := 1;
      end else
      if (AInfo.Rec.EventType = _MOUSE_EVENT) and optProcessMouse and (FarGetMacroState = MACROSTATE_NOMACRO) then begin
        if MacroLibrary.CheckMouse(AInfo.Rec.Event.MouseEvent) then  
          Result := 1;
      end;
//  end;
  end;

 {$endif bUseProcessConsoleInput}


initialization
finalization
  FreeObj(CmdWords);
end.

