{******************************************************************************}
{* (c) 2009 Max Rusov                                                         *}
{*                                                                            *}
{* PanelTabs Far plugin                                                       *}
{******************************************************************************}

{$I Defines.inc}

unit PanelTabsClasses;

interface

  uses
    Windows,
    ShellAPI,
    MixTypes,
    MixUtils,

    MixStrings,
    MixClasses,
    MixWinUtils,

   {$ifdef bUnicodeFar}
    PluginW,
    FarKeysW,
   {$else}
    Plugin,
    FarKeys,
   {$endif bUnicodeFar}
    FarColor,

    FarCtrl,
    FarMenu,
    FarConMan,
    FarColorDlg,

    PanelTabsCtrl;

  const
    cMinTabWidth = 3;

   {$ifdef bUnicodeFar}
    cSide1 = #$2590;
    cSide2 = #$258C;
   {$else}
    cSide1 = #$DE;
    cSide2 = #$DD;
   {$endif bUnicodeFar}



  type
    THotSpot = (
      hsNone,
      hsTab,
      hsButtom,
      hsPanel
    );

    TTabKind = (
      tkLeft,
      tkRight,
      tkCommon
    );

    TClickType = (
      mcNone,
      mcLeft,
      mcDblLeft,
      mcRight,
      mcDblRight,
      mcMiddle,
      mcDblMiddle
    );

    TKeyShift = (
      ksShift,
      ksControl,
      ksAlt
    );
    TKeyShifts = set of TKeyShift;

    TTabAction = (
      taNone,

      taSelect,
      taPSelect,
      taEdit,
      taDelete,
      taFixUnfix,

      taAdd,
      taAddFixed,
      taPAdd,
      taPAddFixed,

      taList,
      taMainMenu
    );

    TClickAction = class(TBasis)
    public
      constructor CreateEx(AHotSpot :THotSpot; AClickType :TClickType; AShifts :TKeyShifts; AAction :TTabAction);

      function ShiftAndClickAsStr :TString;

    public
      function CompareObj(Another :TBasis; Context :TIntPtr) :Integer; override;

    private
      FHotSpot   :THotSpot;
      FClickType :TClickType;
      FShifts    :TKeyShifts;
      FAction    :TTabAction;

    public
      property HotSpot :THotSpot read FHotSpot write FHotSpot;
      property ClickType :TClickType read FClickType write FClickType;
      property Shifts :TKeyShifts read FShifts write FShifts;
      property Action :TTabAction read FAction write FAction;
    end;


    TClickActions = class(TObjList)
    public
      procedure StoreReg;
      procedure RestoreReg;
    end;


    TPanelTab = class(TBasis)
    public
      constructor CreateEx(const ACaption, AFolder :TString);
      destructor Destroy; override;

      function GetTabCaption :TString;
      function IsFixed :Boolean;
      procedure Fix(AValue :Boolean);

    private
      FCaption  :TString;
      FFolder   :TString;
      FDelta    :Integer;
      FWidth    :Integer;
      FHotkey   :TChar;
      FHotPos   :Integer;

      FCurrent  :TString;     { ������� Item �� ������ Tab'� }
      FSelected :TStringList; { ������ ���������� ��������� }

    public
      property Caption :TString read FCaption write FCaption;
      property Folder :TString read FFolder write FFolder;
    end;


    TPanelTabs = class(TObjList)
    public
      constructor CreateEx(const AName :TString);

      function FindTab(const AName :TString; AFixedOnly, AByFolder :Boolean) :Integer;
      function FindTabByKey(AKey :TChar) :Integer;
      procedure UpdateHotkeys;
      procedure RealignTabs(ANewWidth :Integer);
      procedure StoreReg(const APath :TString);
      procedure RestoreReg(const APath :TString);
      procedure StoreFile(const AFileName :TString);
      procedure RestoreFile(const AFileName :TString);

    private
      FName     :TString;    { ��� ������ = ��� ����� �������}
      FCurrent  :Integer;    { ������� Tab (��� ��������������� �����) }
      FAllWidth :Integer;    { ������ ������ ����� ��� ��������� ������ RealignTabs }
    end;


    TTabsManager = class(TBasis)
    public
      constructor Create; override;
      destructor Destroy; override;

      function HitTest(X, Y :Integer; var APanelKind :TTabKind; var AIndex :Integer) :THotSpot;
      function FindActions(AHotSpot :THotSpot; AClickType :TClickType; AShifts :TKeyShifts) :TClickAction;

      function NeedCheck(var X, Y :Integer) :Boolean;
      function CanPaintTabs(ACheckCursor :Boolean = False) :Boolean;
      procedure PaintTabs(ACheckCursor :Boolean = False);
//    procedure RefreshTabs;

      procedure MouseClick;
      procedure ClickAction(Action :TTabAction; AKind :TTabKind; AIndex :Integer);
      procedure AddTab(Active :Boolean);
      procedure DeleteTab(Active :Boolean);
      procedure ListTab(Active :Boolean);
      procedure FixUnfixTab(Active :Boolean);
      procedure SelectTab(Active :Boolean; AIndex :Integer);
      procedure SelectTabByKey(Active, AOnPassive :Boolean; AChar :TChar);

      procedure ToggleOption(var AOption :Boolean);
      procedure RunCommand(const ACmd :TString);

      procedure StoreTabs;
      procedure RestoreTabs;

    private
      FRects :array[TTabKind] of TRect;
      FTabs  :array[TTabKind] of TPanelTabs;

      FPressedKind  :TTabKind;
      FPressedIndex :Integer;

      FLastClickTime :DWORD;        { ��� ������������ DblClick }
      FLastClickPos :TPoint;
      FLastClickType :TClickType;

      FActions :TClickActions;

     {$ifdef bUseInjecting}
      FDrawLock     :Integer;
     {$endif bUseInjecting}

      function KindOfTab(Active :Boolean) :TTabKind;
      function GetTabs(Active :Boolean) :TPanelTabs;
      procedure RememberTabState(Active :Boolean; AKind :TTabKind);
      procedure RestoreTabState(Active :Boolean; ATab :TPanelTab);
      procedure DoSelectTab(Active :Boolean; AKind :TTabKind; AOnPassive :Boolean; AIndex :Integer);

      procedure AddTabEx(Active :Boolean; AKind :TTabKind; AFixed :Boolean; AFromPassive :Boolean = False);
      procedure DeleteTabEx(Active :Boolean; AKind :TTabKind; AIndex :Integer);
      procedure FixUnfixTabEx(Active :Boolean; AKind :TTabKind; AIndex :Integer);
      procedure ListTabEx(Active :Boolean; AKind :TTabKind);

      procedure SetPressed(AKind :TTabKind; AIndex :Integer);

    public
     {$ifdef bUseInjecting}
      property DrawLock :Integer read FDrawLock;
     {$endif bUseInjecting}
    end;

  function HotSpot2Str(AHotSpot :THotSpot) :TString;
  function ClickType2Str(AHotSpot :TClickType) :TString;
  function Shifths2Str(AShifts :TKeyShifts) :TString;
  function TabAction2Str(Action :TTabAction) :TString;

  var
    TabsManager :TTabsManager;

  procedure MainMenu;
  procedure OptionsMenu;
  procedure ProcessSelectMode;

{******************************************************************************}
{******************************} implementation {******************************}
{******************************************************************************}

  uses
    EditTabDlg,
    TabListDlg,
    TabActionsList,
    MixDebug;


 {-----------------------------------------------------------------------------}

  function ShellOpen(const AName, AParam :TString) :Boolean;
  var
    vInfo :TShellExecuteInfo;
  begin
   {$ifdef bTrace}
    TraceF('%s %s', [AName, AParam]);
   {$endif bTrace}
    FillChar(vInfo, SizeOf(vInfo), 0);
    vInfo.cbSize        := SizeOf(vInfo);
    vInfo.fMask         := 0;
    vInfo.Wnd           := 0;
    vInfo.lpFile        := PTChar(AName);
    vInfo.lpParameters  := PTChar(AParam);
    vInfo.lpDirectory   := nil; {!!!}
    vInfo.nShow         := SW_Show;
    Result := ShellExecuteEx(@vInfo);
  end;


  procedure ExecuteCommand(const ACommand :TString);
  var
    vFile :TString;
    vParam :PTChar;
  begin
    vParam := PTChar(ACommand);
    vFile := ExtractParamStr(vParam);
    ShellOpen(vFile, vParam);
  end;


  function ParseExecLine(const ACmdStr :TString) :TString;
  var
    vDstBuf :PTChar;
    vDstSize :Integer;
    vDstLen :Integer;

    procedure LocGrow;
    begin
      ReallocMem(vDstBuf, (vDstSize + 256) * SizeOf(TChar));
      Inc(vDstSize, 256);
    end;

    procedure AddChr(AChr :TChar);
    begin
      if vDstLen + 1 > vDstSize then
        LocGrow;
      PTChar(vDstBuf + vDstLen)^ := AChr;
      Inc(vDstLen);
    end;

    procedure AddStr(const AStr :TString);
    begin
      while vDstLen + length(AStr) > vDstSize do
        LocGrow;
      StrMove(vDstBuf + vDstLen, PTChar(AStr), length(AStr));
      Inc(vDstLen, length(AStr));
    end;

    function GetPanelFolder(Active :Boolean) :TString;
    begin
      Result := FarPanelGetCurrentDirectory(HandleIf(Active, PANEL_ACTIVE, PANEL_PASSIVE));
    end;

  var
    vPtr :PTChar;
    vActive :Boolean;
  begin
    Result := '';

    vDstSize := 0;
    vDstBuf := nil;
    try
      LocGrow;
      vDstLen := 0;
      vActive := True;

      vPtr := PTChar(ACmdStr);
      while vPtr^ <> #0 do begin
        { �������� ���������� � ������������� ����������� ���������� FAR }
        if vPtr^ = '!' then begin
          Inc(vPtr);
          if vPtr^ = '!' then begin
            AddChr('!');
            Inc(vPtr);
          end else
          if vPtr^ = ':' then begin
            AddStr(ExtractFileDrive(GetPanelFolder(vActive)));
            Inc(vPtr);
          end else
          if vPtr^ = '\' then begin
            AddStr(AddBackSlash(GetPanelFolder(vActive)));
            Inc(vPtr);
          end else
          if (vPtr^ = '.') and ((vPtr + 1)^ = '!') then begin
            AddStr(FarPanelGetCurrentItem(vActive));
            Inc(vPtr, 2);
          end else
          if (vPtr^ = '#') or (vPtr^ = '^') then begin
            vActive := vPtr^ = '^';
            Inc(vPtr);
          end else
            AddStr(ExtractFileTitle(FarPanelGetCurrentItem(vActive)));
        end else
        begin
          AddChr(vPtr^);
          Inc(vPtr);
        end;
      end;

      SetString(Result, vDstBuf, vDstLen);

    finally
      MemFree(vDstBuf);
    end;
  end;


 {-----------------------------------------------------------------------------}

  function SafeMaskStr(const AStr :TString) :TSTring;
  begin
    if LastDelimiter(',"', AStr) <> 0 then
      Result := AnsiQuotedStr(AStr, '"')
    else
      Result := AStr;
  end;


  function ExtractNextLine(var AStr :PTChar) :TString;
  var
    vBeg :PTChar;
  begin
    while (AStr^ <> #0) and ((AStr^ = #13) or (AStr^ = #10)) do
      Inc(AStr);
    vBeg := AStr;
    while (AStr^ <> #0) and (AStr^ <> #13) and (AStr^ <> #10) do
      Inc(AStr);
    SetString(Result, vBeg, AStr - vBeg);
  end;


  function ExtractNextItem(var AStr :PTChar) :TString;
  begin
    if AStr^ = '"' then begin
      Result := AnsiExtractQuotedStr(AStr, '"');
      if AStr^ = ',' then
        Inc(AStr)
      else
        Result := Result + ExtractNextValue(AStr, [',']);
    end else
      Result := ExtractNextValue(AStr, [',']);
  end;


  procedure DrawTextChr(AChr :TChar; X, Y :Integer; AColor :Integer);
  var
    vBuf :array[0..1] of TChar;
  begin
    vBuf[0] := AChr;
    vBuf[1] := #0;
    FARAPI.Text(X, Y, AColor, @vBuf[0]);
  end;


  procedure DrawTextEx(const AStr :TString; X, Y :Integer; AMaxLen, ASelPos, ASelLen :Integer; AColor1, AColor2 :Integer);

    procedure LocDrawPart(var AChr :PTChar; ALen :Integer; var ARest :Integer; AColor :Integer);
    var
      vBuf :Array[0..255] of TChar;
    begin
      if (ARest > 0) and (ALen > 0) then begin
        if ALen > ARest then
          ALen := ARest;
        if ALen > High(vBuf) then
          ALen := High(vBuf);
        StrLCopy(@vBuf[0], AChr, ALen);
        FARAPI.Text(X, Y, AColor, @vBuf[0]);
        Dec(ARest, ALen);
        Inc(AChr, ALen);
        Inc(X, ALen);
      end;
    end;

  var
    vChr :PTChar;
  begin
    vChr := PTChar(AStr);
    if (ASelPos = 0) or (ASelLen = 0) then
      LocDrawPart(vChr, Length(AStr), AMaxLen, AColor1)
    else begin
      LocDrawPart(vChr, ASelPos - 1, AMaxLen, AColor1);
      LocDrawPart(vChr, ASelLen, AMaxLen, AColor2);
      LocDrawPart(vChr, Length(AStr) - ASelPos - ASelLen + 1, AMaxLen, AColor1);
    end;
  end;


 {-----------------------------------------------------------------------------}
 {                                                                             }
 {-----------------------------------------------------------------------------}

  function HotSpot2Str(AHotSpot :THotSpot) :TString;
  begin
    case AHotSpot of
      hsNone:   Result := 'None';
      hsTab:    Result := 'Tab';
      hsPanel:  Result := 'Panel';
      hsButtom: Result := 'Button';
    end;
  end;

  function ClickType2Str(AHotSpot :TClickType) :TString;
  begin
    case AHotSpot of
      mcNone:      Result := 'None';
      mcLeft:      Result := 'Left';
      mcRight:     Result := 'Right';
      mcMiddle:    Result := 'Middle';
      mcDblLeft:   Result := 'DblLeft';
      mcDblRight:  Result := 'DblRight';
      mcDblMiddle: Result := 'DblMiddle';
    end;
  end;

  function Shifths2Str(AShifts :TKeyShifts) :TString;
  begin
    Result := '';
    if ksShift in AShifts then
      Result := 'Shift';
    if ksControl in AShifts then
      Result := AppendStrCh(Result, 'Ctrl', '+');
    if ksAlt in AShifts then
      Result := AppendStrCh(Result, 'Alt', '+');
  end;


  function TabAction2Str(Action :TTabAction) :TString;
  begin
    Result := GetMsgStr(TMessages(byte(strMouseActionBase) + byte(Action)));
  end;


  function TabAction2Word(Action :TTabAction) :TString;
  begin
    case Action of
      taNone:       Result := 'None';
      taSelect:     Result := 'Select';
      taPSelect:    Result := 'PSelect';
      taEdit:       Result := 'Edit';
      taDelete:     Result := 'Delete';
      taFixUnfix:   Result := 'Fix';
      taAdd:        Result := 'Add';
      taAddFixed:   Result := 'AddFix';
      taPAdd:       Result := 'PAdd';
      taPAddFixed:  Result := 'PAddFix';
      taList:       Result := 'List';
      taMainMenu:   Result := 'Menu';
    end;
  end;


  function Word2TabAction(const AStr :TString) :TTabAction;
  var
    I :TTabAction;
  begin
    for I := Low(TTabAction) to High(TTabAction) do
      if StrEqual(TabAction2Word(I), AStr) then begin
        Result := I;
        Exit;
      end;
    Result := taNone;
  end;


 {-----------------------------------------------------------------------------}
 {                                                                             }
 {-----------------------------------------------------------------------------}

  procedure ColorsMenu;
  var
    vMenu :TFarMenu;
  begin
    vMenu := TFarMenu.CreateEx(
      GetMsg(strColorsTitle),
    [
      GetMsg(strColBackground),
      GetMsg(strColInactiveTab),
      GetMsg(strColActiveTab),
      GetMsg(strColAddButton),
      GetMsg(strColShortcut),
      '',
      GetMsg(strRestoreDefaults)
    ]);
    try
      while True do begin
        vMenu.SetSelected(vMenu.ResIdx);

        if not vMenu.Run then
          Exit;

        case vMenu.ResIdx of
          0: ColorDlg('', optBkColor);
          1: ColorDlg('', optPassiveTabColor);
          2: ColorDlg('', optActiveTabColor);
          3: ColorDlg('', optButtonColor);
          4: ColorDlg('', optNumberColor);
//        5:
          6: RestoreDefColor;
        end;

        WriteSetup;
        TabsManager.PaintTabs;
      end;

    finally
      FreeObj(vMenu);
    end;
  end;


  procedure OptionsMenu;
  var
    vMenu :TFarMenu;
  begin
    vMenu := TFarMenu.CreateEx(
      GetMsg(strOptions),
    [
      GetMsg(strMShowTabs),
      GetMsg(strMShowNumbers),
//    GetMsg(strMShowButton),
      GetMsg(strMSeparateTabs),
      '',
      GetMsg(strMMouseActions),
      '',
      GetMsg(strColors)
    ]);
    try
      while True do begin
        vMenu.Checked[0] := optShowTabs;
        vMenu.Checked[1] := optShowNumbers;
//      vMenu.Checked[2] := optShowButton;
        vMenu.Checked[2] := optSeparateTabs;

        vMenu.SetSelected(vMenu.ResIdx);

        if not vMenu.Run then
          Exit;

        case vMenu.ResIdx of
          0: TabsManager.ToggleOption(optShowTabs);
          1: TabsManager.ToggleOption(optShowNumbers);
//        2: TabsManager.ToggleOption(optShowButton);
          2: TabsManager.ToggleOption(optSeparateTabs);
//        3:
          4: ActionsList(TabsManager.FActions);
//        5:
          6: ColorsMenu;
        end;
      end;

    finally
      FreeObj(vMenu);
    end;
  end;


  procedure ProcessSelectMode;
  var
    vKey :Integer;
    vChr :TChar;
    vReady, vActive, vOnPassive :Boolean;
  begin
    vActive := True;
    vOnPassive := False;
    repeat
      vKey := FARAPI.AdvControl(hModule, ACTL_WAITKEY, nil);

      vReady := True;
      case vKey of
        KEY_ESC:
          {};
        KEY_INS:
          TabsManager.AddTab(vActive);
        KEY_DEL:
          TabsManager.DeleteTab(vActive);
        KEY_SPACE:
          TabsManager.ListTab(vActive);
        KEY_MULTIPLY:
          TabsManager.FixUnfixTab(vActive);
        KEY_DIVIDE:
          begin
            vOnPassive := not vOnPassive;
            vReady := False;
          end;
        KEY_TAB:
          begin
            vActive := not vActive;
            vReady := False;
          end;
      else
//      TabsManager.SelectTab(True, VKeyToIndex(vKey));
       {$ifdef bUnicodeFar}
        if (vKey > 32) and (vKey < $FFFF) then begin
       {$else}
        if (vKey > 32) and (vKey <= $FF) then begin
       {$endif bUnicodeFar}
          vChr := TChar(vKey);
         {$ifndef bUnicodeFar}
          ChrOemToAnsi(vChr, 1);
         {$endif bUnicodeFar}
          TabsManager.SelectTabByKey(vActive, vOnPassive, vChr);
        end;
      end;
    until vReady;
  end;


  procedure MainMenu;
  var
    vMenu :TFarMenu;
  begin
    TabsManager.PaintTabs;

    vMenu := TFarMenu.CreateEx(
      GetMsg(strTitle),
    [
      GetMsg(strMAddTab),
      GetMsg(strMEditTabs),
      GetMsg(strMSelectTab),
      '',
      GetMsg(strMOptions)
    ]);
    try
      vMenu.Help := 'Contents';

      if not vMenu.Run then
        Exit;

      case vMenu.ResIdx of
        0: TabsManager.AddTab(True);
        1: TabsManager.ListTab(True);
        2: ProcessSelectMode;
        4: OptionsMenu;
      end;

    finally
      FreeObj(vMenu);
    end;
  end;


 {-----------------------------------------------------------------------------}
 { TClickAction                                                               }
 {-----------------------------------------------------------------------------}

  constructor TClickAction.CreateEx(AHotSpot :THotSpot; AClickType :TClickType; AShifts :TKeyShifts; AAction :TTabAction);
  begin
    Create;
    FHotSpot := AHotSpot;
    FClickType := AClickType;
    FShifts := AShifts;
    FAction := AAction;
  end;


  function TClickAction.CompareObj(Another :TBasis; Context :TIntPtr) :Integer; {override;}
  var
    vAnother :TClickAction;
  begin
    vAnother := Another as TClickAction;
    Result := IntCompare(Byte(FHotSpot), Byte(vAnother.HotSpot));
    if Result = 0 then
      Result := IntCompare(Byte(FClickType), Byte(vAnother.ClickType));
    if Result = 0 then
      Result := IntCompare(Byte(FShifts), Byte(vAnother.Shifts));
    if Result = 0 then
      Result := IntCompare(Byte(FAction), Byte(vAnother.Action));
  end;


  function TClickAction.ShiftAndClickAsStr :TString;
  begin
    Result := AppendStrCh( ClickType2Str(FClickType), Shifths2Str(FShifts), '+');
  end;


 {-----------------------------------------------------------------------------}
 { TClickActions                                                               }
 {-----------------------------------------------------------------------------}

  procedure TClickActions.StoreReg;

    procedure LocWriteAction(AKey :HKey; AIndex :Integer; Action :TClickAction);
    var
      vKey :HKEY;
    begin
      RegOpenWrite(AKey, cActionRegFolder + Int2Str(AIndex), vKey);
      try
        RegWriteInt(vKey, cAreaRegKey, Byte(Action.Hotspot));
        RegWriteInt(vKey, cClickRegKey, Byte(Action.ClickType));
        RegWriteInt(vKey, cShiftsRegKey, Byte(Action.Shifts));
        RegWriteStr(vKey, cActionRegKey, TabAction2Word(Action.Action));
      finally
        RegCloseKey(vKey);
      end;
    end;


    function LocDelete(AKey :HKey; AIndex :Integer) :Boolean;
    var
      vKey :HKEY;
      vStr :TString;
    begin
      Result := False;
      vStr := cActionRegFolder + Int2Str(AIndex);
      if not RegOpenRead(AKey, vStr, vKey) then
        Exit;

      ApiCheckCode(RegDeleteKey(AKey, PTChar(vStr)));

      RegCloseKey(vKey);
    end;

  var
    I :Integer;
    vKey :HKEY;
    vPath :TString;
  begin
    vPath := FRegRoot + '\' + cPlugRegFolder + '\' + cActionsRegFolder;

    RegOpenWrite(HKCU, vPath, vKey);
    try
      for I := 0 to Count - 1 do
        LocWriteAction(vKey, I, Items[I]);

      {������� ������ �����}
      I := Count;
      while True do begin
        if not LocDelete(vKey, I) then
          Break;
        Inc(I);
      end;

    finally
      RegCloseKey(vKey);
    end;
  end;


  procedure TClickActions.RestoreReg;

    function LocReadAction(AKey :HKey; AIndex :Integer) :Boolean;
    var
      vKey :HKEY;
      vActionStr :TString;
      vArea, vClick, vShifts :Integer;
    begin
      Result := False;
      if not RegOpenRead(AKey, cActionRegFolder + Int2Str(AIndex), vKey) then
        Exit;
      try
        vArea := RegQueryInt(vKey, cAreaRegKey, -1);
        vClick := RegQueryInt(vKey, cClickRegKey, -1);
        vShifts := RegQueryInt(vKey, cShiftsRegKey, -1);
        vActionStr := RegQueryStr(vKey, cActionRegKey, '');
        if (vArea >= 1) and (vClick >= 1) and (vShifts >= 0) and (vActionStr <> '') then
          AddSorted( TClickAction.CreateEx(THotSpot(vArea), TClickType(vClick), TKeyShifts(Byte(vShifts)), Word2TabAction(vActionStr)), 0, dupAccept);
        Result := True;
      finally
        RegCloseKey(vKey);
      end;
    end;

  var
    I :Integer;
    vKey :HKEY;
    vPath :TString;
  begin
    vPath := FRegRoot + '\' + cPlugRegFolder + '\' + cActionsRegFolder;

    if not RegOpenRead(HKCU, vPath, vKey) then
      Exit;
    try
      I := 0;
      while True do begin
        if not LocReadAction(vKey, I) then
          Break;
        Inc(I);
      end;
    finally
      RegCloseKey(vKey);
    end;
  end;


 {-----------------------------------------------------------------------------}
 { TPanelTab                                                                   }
 {-----------------------------------------------------------------------------}

  constructor TPanelTab.CreateEx(const ACaption, AFolder :TString);
  begin
    inherited Create;
    FCaption := ACaption;
    FFolder := AFolder;
    FSelected := TStringList.Create;
    FSelected.Sorted := True; { ��� ��������� FarPanelSetSelectedItems }
  end;


  destructor TPanelTab.Destroy; {override;}
  begin
    FreeObj(FSelected);
    inherited Destroy;
  end;


  function TPanelTab.IsFixed :Boolean;
  begin
    Result := (FCaption <> '') and (FCaption <> '*');
  end;


  function TPanelTab.GetTabCaption :TString;
  begin
    if IsFixed then
      Result := optFixedMark + FCaption
    else begin
      Result := PathToCaption(FFolder);
      if optNotFixedMark <> '' then
        Result := optNotFixedMark + Result;
    end;
  end;


  procedure TPanelTab.Fix(AValue :Boolean);
  begin
    if AValue then
      FCaption := PathToCaption(FFolder)
    else
      FCaption := '*';
  end;


 {-----------------------------------------------------------------------------}
 { TPanelTabs                                                                  }
 {-----------------------------------------------------------------------------}

  constructor TPanelTabs.CreateEx(const AName :TString);
  begin
    Create;
    FName := AName;
    FCurrent := -1;
  end;


  function TPanelTabs.FindTab(const AName :TString; AFixedOnly, AByFolder :Boolean) :Integer;
  var
    I :Integer;
    vTab :TPanelTab;
    vStr :TString;
  begin
    for I := 0 to FCount - 1 do begin
      vTab := Items[I];
      if AFixedOnly and not vTab.IsFixed then
        Continue;
      if not AByFolder then
        vStr := vTab.FCaption
      else
        vStr := RemoveBackSlash(vTab.FFolder);
      if StrEqual(AName, vStr) then begin
        Result := I;
        Exit;
      end;
    end;
    Result := -1;
  end;


  function TPanelTabs.FindTabByKey(AKey :TChar) :Integer;
  var
    I :Integer;
    vKey :TChar;
    vTab :TPanelTab;
  begin
    vKey := CharUpcase(AKey);
    for I := 0 to FCount - 1 do begin
      vTab := Items[I];
      if vTab.FHotkey = vKey then begin
        Result := I;
        Exit;
      end;
    end;
    Result := -1;
  end;


  procedure TPanelTabs.UpdateHotkeys;
  var
    I, J :Integer;
    vTab :TPanelTab;
    vStr :TString;
    vChr :TChar;
  begin
    for I := 0 to FCount - 1 do begin
      vTab := Items[I];
      vStr := vTab.GetTabCaption;
      vTab.FHotPos := ChrPos('&', vStr);
      if (vTab.FHotPos > 0) and (vTab.FHotPos < length(vStr)) then
        vTab.FHotkey := CharUpcase(vStr[vTab.FHotPos + 1])
      else
        vTab.FHotkey := #0;
    end;

    J := 0;
    for I := 0 to FCount - 1 do begin
      vTab := Items[I];
      if vTab.FHotkey = #0 then begin
        repeat
          vChr := IndexToChar(J);
          Inc(J);
        until FindTabByKey(vChr) = -1;
        vTab.FHotkey := vChr;
      end;
    end;
  end;


  procedure TPanelTabs.RealignTabs(ANewWidth :Integer);

    function LocReduceTab :Boolean;
    var
      I, J, L :Integer;
    begin
      Result := False;
      J := -1; L := 0;
      for I := 0 to FCount - 1 do
        with TPanelTab(Items[I]) do
          if FWidth > L then begin
            L := FWidth;
            J := I;
          end;
      with TPanelTab(Items[J]) do begin
        if FWidth <= cMinTabWidth then
          Exit;
        Dec(FWidth);
      end;
      for I := J + 1 to FCount - 1 do
        with TPanelTab(Items[I]) do
          Dec(FDelta);
      Result := True;
    end;

  var
    I, X, L :Integer;
    vTab :TPanelTab;
  begin
    FAllWidth := ANewWidth;
    X := 1;
    for I := 0 to FCount - 1 do begin
      vTab := Items[I];

      L := Length(vTab.GetTabCaption) + 1;
      if vTab.FHotPos > 0 then
        Dec(L)
      else
      if optShowNumbers then
        Inc(L);

      vTab.FDelta := X;
      vTab.FWidth := L;
      Inc(X, L);
    end;

    if optShowButton then
      { �������� ������ �������� }
      Dec(ANewWidth, 3);

    if X > ANewWidth then begin
      { �������� ���������, �� ���� - ������� }
      for I := 0 to X - ANewWidth - 1 do
        if not LocReduceTab then
          Break;
    end;
  end;


  procedure TPanelTabs.StoreReg(const APath :TString);

    procedure LocWriteTab(AKey :HKey; AIndex :Integer; ATab :TPanelTab);
    var
      vKey :HKEY;
    begin
      RegOpenWrite(AKey, cTabRegFolder + Int2Str(AIndex), vKey);
      try
        RegWriteStr(vKey, cCaptionRegKey, ATab.FCaption);
        RegWriteStr(vKey, cFolderRegKey, ATab.FFolder);
      finally
        RegCloseKey(vKey);
      end;
    end;

    function LocDelete(AKey :HKey; AIndex :Integer) :Boolean;
    var
      vKey :HKEY;
      vStr :TString;
    begin
      Result := False;
      vStr := cTabRegFolder + Int2Str(AIndex);
      if not RegOpenRead(AKey, vStr, vKey) then
        Exit;

      ApiCheckCode(RegDeleteKey(AKey, PTChar(vStr)));

      RegCloseKey(vKey);
    end;

  var
    I :Integer;
    vKey :HKEY;
    vPath :TString;
  begin
    vPath := APath;
    if vPath = '' then
      vPath := FRegRoot + '\' + cPlugRegFolder + '\' + cTabsRegFolder + '\' + FName;

    RegOpenWrite(HKCU, vPath, vKey);
    try
      for I := 0 to Count - 1 do
        LocWriteTab(vKey, I, Items[I]);

      {������� ������ �����}
      I := Count;
      while True do begin
        if not LocDelete(vKey, I) then
          Break;
        Inc(I);
      end;

      RegWriteInt(vKey, cCurrentRegKey, FCurrent);

    finally
      RegCloseKey(vKey);
    end;
  end;


  procedure TPanelTabs.RestoreReg(const APath :TString);

    function LocReadTab(AKey :HKey; AIndex :Integer) :Boolean;
    var
      vKey :HKEY;
      vCaption, vFolder :TString;
    begin
      Result := False;
      if not RegOpenRead(AKey, cTabRegFolder + Int2Str(AIndex), vKey) then
        Exit;
      try
        vCaption := RegQueryStr(vKey, cCaptionRegKey, '');
        if vCaption <> '' then begin
          vFolder := RegQueryStr(vKey, cFolderRegKey, '');
          Add(TPanelTab.CreateEx(vCaption, vFolder));
        end;
        Result := True;
      finally
        RegCloseKey(vKey);
      end;
    end;

  var
    I :Integer;
    vKey :HKEY;
    vPath :TString;
  begin
    vPath := APath;
    if vPath = '' then
      vPath := FRegRoot + '\' + cPlugRegFolder + '\' + cTabsRegFolder + '\' + FName;

    if not RegOpenRead(HKCU, vPath, vKey) then
      Exit;
    try
      I := 0;
      while True do begin
        if not LocReadTab(vKey, I) then
          Break;
        Inc(I);
      end;

      FCurrent := RegQueryInt(vKey, cCurrentRegKey, FCurrent);

      UpdateHotkeys;
    finally
      RegCloseKey(vKey);
    end;
  end;


  procedure TPanelTabs.StoreFile(const AFileName :TString);
  var
    I :Integer;
    vTab :TPanelTab;
    vFileName, vStr :TString;
  begin
    vFileName := SafeChangeFileExtension(FarExpandFileName(StrExpandEnvironment(AFileName)), cTabFileExt);
//  TraceF('TPanelTabs.StoreFile: %s', [vFileName]);

    vStr := '';
    for I := 0 to Count - 1 do begin
      vTab := Items[I];
      vStr := vStr + SafeMaskStr(vTab.Caption) + ',' + SafeMaskStr(vTab.FFolder) + CRLF;
    end;

    StrToFile(vFileName, vStr);
  end;


  procedure TPanelTabs.RestoreFile(const AFileName :TString);
  var
    vFileName, vStr, vStr1, vCaption, vFolder :TString;
    vPtr, vPtr1 :PTChar;
  begin
    vFileName := SafeChangeFileExtension(FarExpandFileName(StrExpandEnvironment(AFileName)), cTabFileExt);
//  TraceF('TPanelTabs.RestoreFile: %s', [vFileName]);

    vStr := StrFromFile(vFileName);

    Clear;
    FAllWidth := -1;

    vPtr := PTChar(vStr);
    while vPtr^ <> #0 Do begin
      vStr1 := ExtractNextLine(vPtr);
      if vStr1 <> '' then begin
        vPtr1 := PTChar(vStr1);
        vCaption := ExtractNextItem(vPtr1);
        vFolder := ExtractNextItem(vPtr1);
        Add(TPanelTab.CreateEx(vCaption, vFolder));
      end;
    end;
    UpdateHotkeys;
  end;


 {-----------------------------------------------------------------------------}
 { TTabsManager                                                                }
 {-----------------------------------------------------------------------------}

  constructor TTabsManager.Create; {override;}
  begin
    inherited Create;

    FTabs[tkLeft] := TPanelTabs.CreateEx(cLeftRegFolder);
    FTabs[tkRight] := TPanelTabs.CreateEx(cRightRegFolder);
    FTabs[tkCommon] := TPanelTabs.CreateEx(cCommonRegFolder);
    FActions := TClickActions.Create;

    FPressedIndex := -1;

    RestoreTabs;
    FActions.RestoreReg;
  end;


  destructor TTabsManager.Destroy; {override;}
  begin
    FreeObj(FActions);
    FreeObj(FTabs[tkLeft]);
    FreeObj(FTabs[tkRight]);
    FreeObj(FTabs[tkCommon]);
    inherited Destroy;
  end;


  procedure TTabsManager.StoreTabs;
  begin
    FTabs[tkLeft].StoreReg('');
    FTabs[tkRight].StoreReg('');
    FTabs[tkCommon].StoreReg('');
  end;


  procedure TTabsManager.RestoreTabs;
  begin
    FTabs[tkLeft].RestoreReg('');
    FTabs[tkRight].RestoreReg('');
    FTabs[tkCommon].RestoreReg('');
  end;


  procedure TTabsManager.ToggleOption(var AOption :Boolean);
  begin
    AOption := not AOption;
    WriteSetup;
    FTabs[tkLeft].FAllWidth := -1;
    FTabs[tkRight].FAllWidth := -1;
    FTabs[tkCommon].FAllWidth := -1;
    PaintTabs;
  end;


  function TTabsManager.FindActions(AHotSpot :THotSpot; AClickType :TClickType; AShifts :TKeyShifts) :TClickAction;
  var
    I :Integer;
    vAction :TClickAction;
  begin
    for I := 0 to FActions.Count - 1 do begin
      vAction := FActions[I];
      if (vAction.FHotSpot = AHotSpot) and (vAction.FClickType = AClickType) and (AShifts = vAction.FShifts) then begin
        Result := vAction;
        Exit;
      end;
    end;
    Result := nil;
  end;


 {-----------------------------------------------------------------------------}

  function TTabsManager.HitTest(X, Y :Integer; var APanelKind :TTabKind; var AIndex :Integer) :THotSpot;

    function LocCheck(AKind :TTabKind) :THotSpot;
    var
      I :Integer;
      vTabs :TPanelTabs;
      vTab :TPanelTab;
      vRect, vRect1 :TRect;
    begin
      Result := hsNone;
      vRect := FRects[AKind];
      if RectContainsXY(vRect, X, Y) then begin
        APanelKind := AKind;

        vTabs := FTabs[AKind];
        for I := 0 to vTabs.Count - 1 do begin
          vTab := vTabs[I];
          vRect1 := Bounds(vRect.Left + vTab.FDelta, vRect.Top, vTab.FWidth, 1);
          if RectContainsXY(vRect1, X, Y) then begin
            Result := hsTab;
            AIndex := I;
            Exit;
          end;
        end;

        if optShowButton then begin
          vRect1 := Bounds(vRect.Right - 2, vRect.Top, 3, 1);
          if RectContainsXY(vRect1, X, Y) then begin
            Result := hsButtom;
            Exit;
          end;
        end;

        Result := hsPanel;
      end;
    end;

  begin
//  TraceF('HitTest: %d, %d', [X, Y]);
    Result := hsNone;
    AIndex := -1;
    APanelKind := tkCommon;
    if not CanPaintTabs then
      Exit;

    if optSeparateTabs then begin
      Result := LocCheck(tkRight);
      if Result = hsNone then
        Result := LocCheck(tkLeft);
    end else
      Result := LocCheck(tkCommon);
  end;


  function TTabsManager.NeedCheck(var X, Y :Integer) :Boolean;

    function LocNeedCheck(AKind :TTabKind) :Boolean;
    begin
      Result := False;
      with FRects[AKind] do
        if Right > Left then begin
          Y := Top;
          X := Right - 2;
          Result := True;
        end;
    end;

  begin
    if optSeparateTabs then begin
      Result := LocNeedCheck(tkRight);
      if not Result then
        Result := LocNeedCheck(tkLeft);
    end else
      Result := LocNeedCheck(tkCommon);
  end;


  function TTabsManager.CanPaintTabs(ACheckCursor :Boolean = False) :Boolean;
    { ���������� �� ��������������� ������. �� ������ ������������ ��-threadsafe �������}
  var
    vWinInfo :TWindowInfo;
    vCursorInfo :TConsoleCursorInfo;
  begin
    Result := False;
    if not optShowTabs then
      Exit;

// {$ifdef bUnicodeFar}
//  if FARAPI.Control(hModule, FCTL_CHECKPANELSEXIST, 0, nil) = 0 then
// {$else}
//  if FARAPI.Control(hModule, FCTL_CHECKPANELSEXIST, nil) = 0 then
// {$endif bUnicodeFar}
//    { ��� �������... }
//    Exit;

    FillChar(vWinInfo, SizeOf(vWinInfo), 0);
    vWinInfo.Pos := -1;
    FARAPI.AdvControl(hModule, ACTL_GETSHORTWINDOWINFO, @vWinInfo);
//  TraceF('WindowType=%d', [vWinInfo.WindowType]);
    if vWinInfo.WindowType = WTYPE_PANELS then begin

      if ACheckCursor then begin
        GetConsoleCursorInfo(hStdOut, vCursorInfo);
//      TraceF('Cursor=%d', [Byte(vCursorInfo.bVisible)]);
        if not vCursorInfo.bVisible then
          { ��� ������� - ������ ������� �� ������. ���� ��������� �������� ��������, }
          { ����� ������� ���� � �.�., ��� �� ������������ � ������� ACTL_GETWINDOWINFO }
          Exit;
      end;

//    vStr := GetConsoleTitleStr;
//    TraceF('Title=%s', [vStr]);
//    if (vStr = '') or (vStr[1] <> '{') then
//      { ���� ��������� �������� ��������, ����� �� ��� Far'� �������� ���������� ��������� }
//      Exit;

      Result := True;
    end;
  end;


  function SwapFgBgColors(AColor :Byte) :Byte;
  begin
    Result := ((AColor and $0F) shl 4) + ((AColor and $F0) shr 4);
  end;


  procedure TTabsManager.PaintTabs(ACheckCursor :Boolean = False);
  var
    vColorSide1, vColorSide2 :Integer;
    vWinWidth :Integer;
    vCmdLineY :Integer;
    vFolders :array[TTabKind] of TString;


    procedure DetectPanelSettings;
    var
      vRes :Integer;
      vSize :TSize;
    begin
//    vRes := FARAPI.AdvControl(hModule, ACTL_GETPANELSETTINGS, nil);
      vRes := FARAPI.AdvControl(hModule, ACTL_GETINTERFACESETTINGS, nil);

      vSize := FarGetWindowSize;
      vCmdLineY := vSize.CY - 1 - IntIf(FIS_SHOWKEYBAR and vRes <> 0, 1, 0);
      vWinWidth := vSize.CX;
    end;


    procedure DetectPanelsLayout;
    var
      vMaximized :Boolean;

      procedure LocDetect(Active :Boolean);
      var
        vInfo  :TPanelInfo;
        vKind  :TTabKind;
      begin
        FillChar(vInfo, SizeOf(vInfo), 0);
       {$ifdef bUnicodeFar}
        FARAPI.Control(HandleIf(Active, PANEL_ACTIVE, PANEL_PASSIVE), FCTL_GetPanelInfo, 0, @vInfo);
       {$else}
        FARAPI.Control(INVALID_HANDLE_VALUE, IntIf(Active, FCTL_GetPanelShortInfo, FCTL_GetAnotherPanelShortInfo), @vInfo);
       {$endif bUnicodeFar}
        if PFLAGS_PANELLEFT and vInfo.Flags <> 0 then
          vKind := tkLeft
        else
          vKind := tkRight;

        if vInfo.Plugin = 0 then
          vFolders[vKind] := GetPanelDir(Active)
        else
          vFolders[vKind] := '';
        if not optSeparateTabs and Active then
          vFolders[tkCommon] := vFolders[vKind];

        if (vInfo.Visible = 0) {or not vInfo.Focus} then
          Exit;
        if vInfo.PanelRect.Bottom + 1 >= vCmdLineY then
          { ��� ����� ��� ����� }
          Exit;

        if not vMaximized then
          with vInfo.PanelRect do begin
            FRects[vKind] := Rect(Left, Bottom + 1, Right + 1, Bottom + 2);
//          FRects[vKind] := Rect(Left, Bottom + 2, Right + 1, Bottom + 3);
            { Check fullscreen }
            vMaximized := (Right - Left + 1) = vWinWidth;
          end;
      end;

    begin
      vMaximized := False;
      FillChar(FRects, SizeOf(FRects), 0);
      LocDetect(True);
      LocDetect(False);

      if not optSeparateTabs then begin
        if not RectEmpty(FRects[tkLeft]) and not RectEmpty(FRects[tkRight]) then begin
          FRects[tkCommon] := FRects[tkLeft];
          FRects[tkCommon].Right := FRects[tkRight].Right;
          FRects[tkCommon].Top := IntMax(FRects[tkLeft].Top, FRects[tkRight].Top);
          FRects[tkCommon].Bottom := FRects[tkCommon].Top + 1;
        end else
        if not RectEmpty(FRects[tkLeft]) then
          FRects[tkCommon] := FRects[tkLeft]
        else
        if not RectEmpty(FRects[tkRight]) then
          FRects[tkCommon] := FRects[tkRight]
      end;
    end;


    procedure PaintTabsForPanel(AKind :TTabKind);

      function IsTabSelected(const ATabStr :TString) :Boolean;
      var
        vPos :Integer;
        vPath1, vPath2 :TString;
      begin
        vPos := ChrPos(';', ATabStr);
        if vPos = 0 then
          Result := StrEqual(ATabStr, vFolders[AKind])
        else begin
          vPath1 := Copy(ATabStr, 1, vPos - 1);
          vPath2 := Copy(ATabStr, vPos + 1, MaxInt);
          Result :=
            (StrEqual(vPath1, vFolders[tkLeft]) and StrEqual(vPath2, vFolders[tkRight])) or
            (StrEqual(vPath1, vFolders[tkRight]) and StrEqual(vPath2, vFolders[tkLeft]));
        end;
      end;

    var
      I, X, vWidth :Integer;
      vRect :TRect;
      vTabs :TPanelTabs;
      vTab :TPanelTab;
      vStr, vStr1 :TString;
      vHotColor :Integer;
      vCurrentIndex :Integer;
    begin
      vTabs := FTabs[AKind];
      vRect := FRects[AKind];
      if RectEmpty(vRect) then
        Exit;

      vCurrentIndex := -1;
      if (FPressedIndex <> -1) and (FPressedKind = AKind) then begin
        vCurrentIndex := FPressedIndex;
      end else
      if vTabs.FCurrent <> -1 then begin
        if vTabs.FCurrent < vTabs.Count then begin
          vTab := vTabs[vTabs.FCurrent];
          if not vTab.IsFixed then begin
            { ���, �������� �� ������ �������... }
            vCurrentIndex := vTabs.FCurrent;
            if not StrEqual(vTab.FFolder, vFolders[AKind]) then begin
              if vFolders[AKind] <> '' then begin
                vTab.FFolder := vFolders[AKind];
                vTabs.FAllWidth := -1;
              end else
                { ������. ���� �� ��������������. }
                vCurrentIndex := -1;
            end;
          end;
        end else
          vTabs.FCurrent := -1;
      end;

      vWidth := vRect.Right - vRect.Left + 1;
      if vTabs.FAllWidth <> vWidth then
        vTabs.RealignTabs(vWidth);

//    TraceF('PaintTabs: Y=%d', [vRect.Top]);

      vStr := StringOfChar(' ', vRect.Right - vRect.Left);
      FARAPI.Text(vRect.Left, vRect.Top, optBkColor, PTChar(vStr));

      for I := 0 to vTabs.Count - 1 do begin
        vTab := vTabs[I];
       {$ifdef bUnicodefar}
        vStr := vTab.GetTabCaption;
       {$else}
        vStr := StrAnsiToOem(vTab.GetTabCaption);
       {$endif bUnicodefar}
        X := vRect.Left + vTab.FDelta;

        vStr1 := '';
        vWidth := vTab.FWidth - 1;
        if vTab.FHotPos > 0 then begin
          Delete(vStr, vTab.FHotPos, 1);
        end else
        if optShowNumbers then
          vStr1 := vTab.FHotkey;

        if (vCurrentIndex = -1) and vTab.IsFixed and IsTabSelected(vTab.FFolder) then
          vCurrentIndex := I;

        if vCurrentIndex = I then begin
//        DrawTextChr(cSide2, X-1, vRect.Top, vColorSide1);
          DrawTextChr(cSide1, X-1, vRect.Top, SwapFgBgColors(vColorSide1));

          vHotColor := (optNumberColor and $0F) or (optActiveTabColor and $F0);
          if vStr1 <> '' then begin
            FARAPI.Text(X, vRect.Top, vHotColor, PTChar(vStr1));
            Dec(vWidth);
            Inc(X);
          end;
          DrawTextEx(vStr, X, vRect.Top, vWidth, vTab.FHotPos, 1, optActiveTabColor, vHotColor);
          Inc(X, vWidth);

          DrawTextChr(cSide1, X, vRect.Top, vColorSide1);
        end else
        begin
          vHotColor := (optNumberColor and $0F) or (optPassiveTabColor and $F0);
          if vStr1 <> '' then begin
            FARAPI.Text(X, vRect.Top, vHotColor, PTChar(vStr1));
            Dec(vWidth);
            Inc(X);
          end;
          DrawTextEx(vStr, X, vRect.Top, vWidth, vTab.FHotPos, 1, optPassiveTabColor, vHotColor);
        end;
      end;

      if optShowButton then begin
//      DrawTextChr(cSide2, vRect.Right - 3, vRect.Top, vColorSide2);
        DrawTextChr(cSide1, vRect.Right - 3, vRect.Top, SwapFgBgColors(vColorSide2));
        DrawTextChr('+', vRect.Right - 2, vRect.Top, optButtonColor);
        DrawTextChr(cSide1, vRect.Right - 1, vRect.Top, vColorSide2);
      end else
      begin
//      vTmp[0] := cSide1;
//      FARAPI.Text(vRect.Right - 1, vRect.Top, vColorSide2, @vTmp[0]);
      end
    end;

  begin
    if not CanPaintTabs(ACheckCursor) then
      Exit;

    vColorSide1 := (optActiveTabColor and $F0) or ((optBkColor and $F0) shr 4);
    vColorSide2 := (optButtonColor and $F0) or ((optBkColor and $F0) shr 4);

    DetectPanelSettings;
    DetectPanelsLayout;
//  DetectPanelsFolders;

   {$ifdef bUseInjecting}
    Inc(FDrawLock);
    try
   {$endif bUseInjecting}

      if optSeparateTabs then begin
        PaintTabsForPanel(tkLeft);
        PaintTabsForPanel(tkRight);
      end else
        PaintTabsForPanel(tkCommon);

   {$ifdef bUseInjecting}
    finally
      FARAPI.Text(0, 0, 0, nil);
      Dec(FDrawLock);
    end;
   {$endif bUseInjecting}
  end;


(*
  procedure TTabsManager.RefreshTabs;
  var
    X, Y :Integer;
    vCh :TChar;
  begin
    if NeedCheck(X, Y) then begin
      vCh := ReadScreenChar(X, Y);
      if vCh <> '+' then begin
//      Trace('RefreshTabs: Need repaint...');
        PaintTabs(True);
      end;
    end;
  end;
*)


  function TTabsManager.KindOfTab(Active :Boolean) :TTabKind;
  begin
    if optSeparateTabs then begin
      if Active = (FarPanelGetSide = 0) then
        Result := tkLeft
      else
        Result := tkRight;
    end else
      Result := tkCommon;
  end;


  function TTabsManager.GetTabs(Active :Boolean) :TPanelTabs;
  begin
    Result := FTabs[KindOfTab(Active)];
  end;


 {-----------------------------------------------------------------------------}

  procedure TTabsManager.RememberTabState(Active :Boolean; AKind :TTabKind);
  var
    vTabs :TPanelTabs;
    vTab :TPanelTab;
  begin
    vTabs := FTabs[AKind];
    if (vTabs.FCurrent >= 0) and (vTabs.FCurrent < vTabs.FCount) then begin
      vTab := vTabs[vTabs.FCurrent];
      vTab.FCurrent := FarPanelGetCurrentItem(Active);
      if optStoreSelection then begin
        vTab.FSelected.Clear;
        FarPanelGetSelectedItems(Active, vTab.FSelected);
      end;
    end;
  end;


  procedure TTabsManager.RestoreTabState(Active :Boolean; ATab :TPanelTab);
  begin
    if (ATab.FCurrent <> '') and (ATab.FCurrent <> '..') then
      FarPanelSetCurrentItem(Active, ATab.FCurrent);
    if optStoreSelection and (ATab.FSelected.Count > 0) then
      FarPanelSetSelectedItems(Active, ATab.FSelected, True);
  end;


  procedure TTabsManager.DoSelectTab(Active :Boolean; AKind :TTabKind; AOnPassive :Boolean; AIndex :Integer);

    procedure LocSetPath(Active :Boolean; const APath :TString);
    var
      vPos :Integer;
    begin
      vPos := ChrPos(';', APath);
      if vPos = 0 then
        FarPanelJumpToPath(Active, APath)
      else begin
        FarPanelJumpToPath(Active, Copy(APath, 1, vPos - 1));
        FarPanelJumpToPath(not Active, Copy(APath, vPos + 1, MaxInt));
      end;
    end;

  var
    vTabs :TPanelTabs;
    vTab :TPanelTab;
    vStr :TString;
  begin
    vTabs := FTabs[AKind];
    if (AIndex >= 0) and (AIndex < vTabs.Count)then begin
      vTab := vTabs[AIndex];

      if UpCompareSubStr(cMacroPrefix, vTab.FFolder) = 0 then begin
        vStr := Copy(vTab.FFolder, length(cMacroPrefix) + 1, MaxInt);
        FarPostMacro(vStr);
        Exit;
      end;

      if UpCompareSubStr(cExecPrefix, vTab.FFolder) = 0 then begin
        vStr := ParseExecLine(StrExpandEnvironment(Copy(vTab.FFolder, length(cExecPrefix) + 1, MaxInt)));
        ExecuteCommand(vStr);
        Exit;
      end;

      if not AOnPassive then begin
        RememberTabState(Active, AKind);
        LocSetPath(Active, vTab.FFolder);
        RestoreTabState(Active, vTab);
        vTabs.FCurrent := AIndex;
      end else
        LocSetPath(not Active, vTab.FFolder);
      PaintTabs;
    end else
      Beep;
  end;


 {-----------------------------------------------------------------------------}

  procedure TTabsManager.AddTab(Active :Boolean);
  begin
    AddTabEx(Active, KindOfTab(Active), {Fixed:}False);
  end;


  procedure TTabsManager.AddTabEx(Active :Boolean; AKind :TTabKind; AFixed :Boolean; AFromPassive :Boolean = False);
  var
    vPath, vCaption :TString;
    vTabs :TPanelTabs;
  begin
    vPath := GetPanelDir(not (Active xor not AFromPassive));
    vTabs := FTabs[AKind];
    if not AFixed or (vTabs.FindTab(vPath, True, True) = -1) then begin
      if AFixed then
        vCaption := PathToCaption(vPath)
      else
        vCaption := '*';
      vTabs.Add(TPanelTab.CreateEx(vCaption, vPath));
      if not AFromPassive then
        vTabs.FCurrent := vTabs.Count - 1;
      vTabs.StoreReg('');
      vTabs.FAllWidth := -1;
      vTabs.UpdateHotkeys;
      PaintTabs;
    end else
      Beep;
  end;


  procedure TTabsManager.DeleteTab(Active :Boolean);
  begin
    DeleteTabEx(Active, KindOfTab(Active), -1);
  end;

  procedure TTabsManager.DeleteTabEx(Active :Boolean; AKind :TTabKind; AIndex :Integer);
  var
    vTabs :TPanelTabs;
  begin
    vTabs := FTabs[AKind];
    if AIndex = -1 then
      AIndex := vTabs.FCurrent;
    if AIndex <> -1 then begin
      vTabs.Delete(AIndex);
      vTabs.FCurrent := -1; {!!!-???}
      vTabs.StoreReg('');
      vTabs.FAllWidth := -1;
      vTabs.UpdateHotkeys;
      PaintTabs;
    end else
      Beep;
  end;


  procedure TTabsManager.FixUnfixTab(Active :Boolean);
  begin
    FixUnfixTabEx(Active, KindOfTab(Active), -1);
  end;

  procedure TTabsManager.FixUnfixTabEx(Active :Boolean; AKind :TTabKind; AIndex :Integer);
  var
    vTabs :TPanelTabs;
    vTab :TPanelTab;
  begin
    vTabs := FTabs[AKind];
    if AIndex = -1 then
      AIndex := vTabs.FCurrent;
    if AIndex <> -1 then begin
      vTab := vTabs[AIndex];
      vTab.Fix(not vTab.IsFixed);
      vTabs.StoreReg('');
      vTabs.FAllWidth := -1;
      vTabs.UpdateHotkeys;
      PaintTabs;
    end else
      Beep;
  end;


  procedure TTabsManager.ListTab(Active :Boolean);
  begin
    ListTabEx(Active, KindOfTab(Active));
  end;

  procedure TTabsManager.ListTabEx(Active :Boolean; AKind :TTabKind);
  var
    vIndex :Integer;
    vTabs :TPanelTabs;
  begin
    vTabs := FTabs[AKind];
    vIndex := vTabs.FCurrent;
    if ListTabDlg(vTabs, vIndex) then
      DoSelectTab( Active, AKind, False, vIndex );
    vTabs.FAllWidth := -1;
    vTabs.UpdateHotkeys;
    PaintTabs;
  end;


  procedure TTabsManager.SelectTab(Active :Boolean; AIndex :Integer);
  begin
    DoSelectTab( Active, KindOfTab(Active), False, AIndex );
  end;


  procedure TTabsManager.SelectTabByKey(Active, AOnPassive :Boolean; AChar :TChar);
  var
    vKind :TTabKind;
    vTabs :TPanelTabs;
    vIndex :Integer;
  begin
    vKind := KindOfTab(Active);

    vTabs := FTabs[vKind];
    vIndex := vTabs.FindTabByKey(AChar);
    if vIndex = -1 then begin
      AChar := FarXLat(AChar);
      vIndex := vTabs.FindTabByKey(AChar);
    end;

    DoSelectTab( Active, vKind, AOnPassive, vIndex );
  end;


  procedure TTabsManager.SetPressed(AKind :TTabKind; AIndex :Integer);
  begin
    if (AIndex <> FPressedIndex) or (AKind <> FPressedKind) then begin
      FPressedIndex := AIndex;
      FPressedKind := AKind;
      PaintTabs;
     {$ifdef bUseInjecting}
     {$else}
      FARAPI.Text(0, 0, 0, nil);
     {$endif bUseInjecting}
    end;
  end;


  procedure TTabsManager.ClickAction(Action :TTabAction; AKind :TTabKind; AIndex :Integer);
  var
    vActive :Boolean;

    procedure LocEditTab;
    var
      vTabs :TPanelTabs;
    begin
      vTabs := FTabs[AKind];
      if EditTab(vTabs, AIndex) then begin
        vTabs.StoreReg('');
        vTabs.FAllWidth := -1;
        vTabs.UpdateHotkeys;
        PaintTabs;
      end;
    end;

  begin
    vActive := True;
    if optSeparateTabs then
      vActive := (AKind = tkRight) = (FarPanelGetSide = 1);

    case Action of
      taSelect:
        DoSelectTab( vActive, AKind, False, AIndex );
      taPSelect:
        DoSelectTab( vActive, AKind, True, AIndex );
      taEdit:
        LocEditTab;
      taDelete:
        DeleteTabEx(vActive, AKind, AIndex);
      taFixUnfix:
        FixUnfixTabEx(vActive, AKind, AIndex);

      taAdd:
        AddTabEx(vActive, AKind, {Fixed:}False);
      taAddFixed:
        AddTabEx(vActive, AKind, {Fixed:}True);

      taPAdd:
        AddTabEx(vActive, AKind, {Fixed:}False, {FromPassive:}True);
      taPAddFixed:
        AddTabEx(vActive, AKind, {Fixed:}True, {FromPassive:}True);

      taList:
        ListTabEx(vActive, AKind);
      taMainMenu:
        MainMenu;
    end;
  end;


  procedure TTabsManager.MouseClick;
  var
    vPoint, vPoint1 :TPoint;
    vIndex, vIndex1 :Integer;
    vKind, vKind1 :TTabKind;
    vHotSpot, vHotSpot1 :THotSpot;
    vClickType :TClickType;
    vShifts :TKeyShifts;
    vAction :TClickAction;
    vPressed :Boolean;
    vTime :DWORD;
  begin
    vPoint := GetConsoleMousePos;

    if GetKeyState(VK_RBUTTON) < 0 then
      vClickType := mcRight
    else
      vClickType := mcLeft;

    vTime := GetTickCount;
    if (FLastClickTime <> 0) and (TickCountDiff(vTime, FLastClickTime) < optDblClickDelay) and (vClickType = FLastClickType) and
      (FLastClickPos.X = vPoint.X) and (FLastClickPos.Y = vPoint.Y)
    then begin
      FLastClickTime := 0;
      if vClickType = mcLeft then
        vClickType := mcDblLeft
      else
        vClickType := mcDblRight;
    end else
    begin
      FLastClickTime := vTime;
      FLastClickPos  := vPoint;
      FLastClickType := vClickType;
    end;

    vShifts := [];
    if GetKeyState(VK_SHIFT) < 0 then
      Include(vShifts, ksShift);
    if GetKeyState(VK_CONTROL) < 0 then
      Include(vShifts, ksControl);
    if GetKeyState(VK_MENU) < 0 then
      Include(vShifts, ksAlt);

    vHotSpot := HitTest(vPoint.X, vPoint.Y, vKind, vIndex);
    if {not vRButton and} (vHotSpot = hsTab) then
      SetPressed(vKind, vIndex);
    vPressed := True;
    try

      while (GetKeyState(VK_LBUTTON) < 0) or (GetKeyState(VK_RBUTTON) < 0) do begin
        Sleep(10);
        vPoint1 := GetConsoleMousePos;
        if (vPoint1.X <> vPoint.X) or (vPoint1.Y <> vPoint.Y) then begin
          vPoint := vPoint1;
          vHotSpot1 := HitTest(vPoint1.X, vPoint1.Y, vKind1, vIndex1);
          vPressed := (vHotSpot = vHotSpot1) and (vKind = vKind1) and (vIndex = vIndex1);
          if vPressed then begin
            if {not vRButton and} (vHotSpot = hsTab) then
              SetPressed(vKind, vIndex);
          end else
            SetPressed(tkCommon, -1);
        end;
      end;

      { ����� ������� ������� ���������� ���� (?)... }
//    if vRButton then
        CheckForEsc;

      if vPressed then begin

        vAction := FindActions(vHotSpot, vClickType, vShifts);

        if vAction <> nil then
          ClickAction(vAction.FAction, vKind, vIndex)
        else begin
          case vHotSpot of
            hsTab:
              if vClickType in [mcLeft, mcDblLeft] then begin
                if GetKeyState(VK_Shift) < 0 then
                  ClickAction(taPSelect, vKind, vIndex)
                else
                  ClickAction(taSelect, vKind, vIndex)
              end else
              if vClickType = mcRight then
                ClickAction(taEdit, vKind, vIndex);
            hsButtom:
              if vClickType = mcLeft then begin
                if GetKeyState(VK_Shift) < 0 then
                  ClickAction(taPAdd, vKind, -1)
                else
                  ClickAction(taAdd, vKind, -1)
              end else
              if vClickType = mcRight then
                ClickAction(taList, vKind, -1);
            hsPanel:
              if vClickType = mcRight then
                ClickAction(taMainMenu, vKind, -1);
          end;
        end;
      end;

    finally
      SetPressed(tkCommon, -1);
    end;
  end;


  procedure TTabsManager.RunCommand(const ACmd :TString);
  var
    vPos :Integer;
    vCmd, vParam :TString;
  begin
    vCmd := ACmd;
    vPos := ChrPos('=', ACmd);
    if vPos <> 0 then begin
      vCmd := Copy(ACmd, 1, vPos - 1);
      vParam := Copy(ACmd, vPos + 1, MaxInt);
    end;

    if StrEqual(vCmd, cAddCmd) then
      AddTab(True)
    else
    if StrEqual(vCmd, cEditCmd) then
      ListTab(True)
    else
    if StrEqual(vCmd, cSaveCmd) then
      GetTabs(True).StoreFile(vParam)
    else
    if StrEqual(vCmd, cLoadCmd) then begin
      with GetTabs(True) do begin
        RestoreFile(vParam);
        StoreReg('');
        PaintTabs;
      end;
    end else
      AppErrorIdFmt(strUnknownCommand, [ACmd]);
  end;


initialization
finalization
  FreeObj(TabsManager);
end.


