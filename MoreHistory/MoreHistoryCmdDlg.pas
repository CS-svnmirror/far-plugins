{$I Defines.inc}

unit MoreHistoryCmdDlg;

{******************************************************************************}
{* (c) 2009-2011, Max Rusov                                                   *}
{*                                                                            *}
{* MoreHistory plugin                                                         *}
{******************************************************************************}

interface

  uses
    Windows,

    MixTypes,
    MixUtils,
    MixFormat,
    MixStrings,
    MixClasses,
    MixWinUtils,

    Far_API,
    FarCtrl,
    FarMatch,
    FarDlg,
    FarMenu,
    FarGrid,
    FarListDlg,

    MoreHistoryCtrl,
    MoreHistoryClasses,
    MoreHistoryListBase,
    MoreHistoryHints;


  type
    TCmdMenuDlg = class(TMenuBaseDlg)
    public
      constructor Create; override;
      destructor Destroy; override;

    protected
      function ItemVisible(AItem :THistoryEntry) :Boolean; override;
      procedure AcceptItem(AItem :THistoryEntry; AGroup :TMyFilter); override;
      procedure ReinitColumns; override;
      procedure ReinitGrid; override;

      function ItemMarkHidden(AItem :THistoryEntry) :Boolean; override;
      function GetEntryStr(AItem :THistoryEntry; AColTag :Integer) :TString; override;

      function KeyDown(AID :Integer; AKey :Integer) :Boolean; override;

    private
      FMaxHits :Integer;

      procedure ClearSelectedHits;

      procedure CommandsMenu;
      procedure ProfileMenu;
      procedure SortByMenu;
    end;


  var
    FCmdLastFilter :TString;


  procedure OpenCmdHistoryDlg(const ACaption, AModeName :TString; const AFilter :TString);


{******************************************************************************}
{******************************} implementation {******************************}
{******************************************************************************}

  uses
    MixDebug;


 {-----------------------------------------------------------------------------}
 { TCmdMenuDlg                                                                 }
 {-----------------------------------------------------------------------------}

  constructor TCmdMenuDlg.Create; {override;}
  begin
    inherited Create;
    RegisterHints(Self);
    FGUID := cCommandsDlgID;
    FHelpTopic := 'CmdHistoryList';
  end;


  destructor TCmdMenuDlg.Destroy; {override;}
  begin
    UnregisterHints;  
    inherited Destroy;
  end;


  function TCmdMenuDlg.ItemVisible(AItem :THistoryEntry) :Boolean; {override;}
  begin
    Result := True;
  end;


  procedure TCmdMenuDlg.AcceptItem(AItem :THistoryEntry; AGroup :TMyFilter); {override;}
  begin
    inherited AcceptItem(AItem, AGroup);
    FMaxHits := IntMax(FMaxHits, (AItem as TCmdHistoryEntry).Hits);
  end;


  procedure TCmdMenuDlg.ReinitColumns; {override;}
  var
    vOpt :TColOptions;
    vDateLen, vHitsLen :Integer;
  begin
    vDateLen := Date2StrLen(optDateFormat);
    vHitsLen := Int2StrLen(FMaxHits);

    vOpt := [coColMargin];
    if not optShowGrid then
      vOpt := vOpt + [coNoVertLine];

    FGrid.Columns.Clear;
    FGrid.Columns.Add( TColumnFormat.CreateEx('', '', 0, taLeftJustify, vOpt + [coOwnerDraw], 1) );
    if optShowDate then
      FGrid.Columns.Add( TColumnFormat.CreateEx('', '', vDateLen + 2, taRightJustify, vOpt, 2) );
    if optShowHits then
      FGrid.Columns.Add( TColumnFormat.CreateEx('', '', vHitsLen + 2, taRightJustify, vOpt, 3) );
  end;


  procedure TCmdMenuDlg.ReinitGrid; {override;}
  begin
    FMaxHits := 0;
    inherited ReinitGrid;
  end;


 {-----------------------------------------------------------------------------}

  function TCmdMenuDlg.ItemMarkHidden(AItem :THistoryEntry) :Boolean; {override;}
  begin
    Result := False;
  end;


  function TCmdMenuDlg.GetEntryStr(AItem :THistoryEntry; AColTag :Integer) :TString; {override;}
  begin
    if AColTag = 3 then
      Result := Int2Str((AItem as TCmdHistoryEntry).Hits)
    else
      Result := inherited GetEntryStr(AItem, AColTag);
  end;

 {-----------------------------------------------------------------------------}

  procedure TCmdMenuDlg.CommandsMenu;
  var
    vMenu :TFarMenu;
  begin
    vMenu := TFarMenu.CreateEx(
      GetMsg(strCommandsTitle),
    [
      GetMsg(strMOpen),
      '',
      GetMsg(strMDelete),
      GetMsg(strMClearHitCount),
      '',
      GetMsg(strMOptions)
    ]);
    try
      if not vMenu.Run then
        Exit;

      case vMenu.ResIdx of
        0 : SelectItem(1);

        2 : DeleteSelected;
        3 : ClearSelectedHits;

        5 : ProfileMenu;
      end;

    finally
      FreeObj(vMenu);
    end;
  end;


  procedure TCmdMenuDlg.ProfileMenu;
  var
    vMenu :TFarMenu;
  begin
    vMenu := TFarMenu.CreateEx(
      GetMsg(strOptionsTitle1),
    [
      GetMsg(strMGroupBy),
      GetMsg(strMShowHidden),
      '',
      GetMsg(strMAccessTime),
      GetMsg(strMHitCount),
      '',
      GetMsg(strMSortBy)
    ]);
    try
      while True do begin
        vMenu.Checked[0] := optHierarchical;
        
        vMenu.Checked[1] := optShowHidden;
        vMenu.Visible[1] := False;

        vMenu.Checked[3] := optShowDate;
        vMenu.Checked[4] := optShowHits;

        vMenu.SetSelected(vMenu.ResIdx);

        if not vMenu.Run then
          Exit;

        case vMenu.ResIdx of
          0 : ChangeHierarchMode;
          1 : ToggleOption(optShowHidden);

          3 : ToggleOption(optShowDate);
          4 : ToggleOption(optShowHits);

          6 : SortByMenu;
        end;
      end;

    finally
      FreeObj(vMenu);
    end;
  end;

  
  procedure TCmdMenuDlg.SortByMenu;
  var
    vMenu :TFarMenu;
    vRes :Integer;
    vChr :TChar;
  begin
    vMenu := TFarMenu.CreateEx(
      GetMsg(strSortByTitle),
    [
      GetMsg(strMByName),
      GetMsg(strMByAccessTime),
      GetMsg(strMByHitCount),
      GetMsg(strMUnsorted)
    ]);

    try
      vRes := Abs(optSortMode) - 1;
      if vRes = -1 then
        vRes := vMenu.Count - 1;
      vChr := '+';
      if optSortMode < 0 then
        vChr := '-';
      vMenu.Items[vRes].Flags := SetFlag(0, MIF_CHECKED or Word(vChr), True);

      if not vMenu.Run then
        Exit;

      vRes := vMenu.ResIdx;
      Inc(vRes);
      if vRes = vMenu.Count then
        vRes := 0;
      if vRes >= 2 then
        vRes := -vRes;
      SetOrder(vRes);

    finally
      FreeObj(vMenu);
    end;
  end;

 {-----------------------------------------------------------------------------}

  procedure TCmdMenuDlg.ClearSelectedHits;
  var
    I :Integer;
    vItem :TCmdHistoryEntry;
  begin
    if FSelectedCount = 0 then begin
      vItem := GetHistoryEntry(FGrid.CurRow, True) as TCmdHistoryEntry;
      if vItem = nil then
        Exit;
      vItem.HitInfoClear;
    end else
    begin
      if ShowMessage(GetMsgStr(strConfirmation), GetMsgStr(strClearSelectedPrompt), FMSG_MB_YESNO) <> 0 then
        Exit;
      for I := 0 to FGrid.RowCount - 1 do
        if DlgItemSelected(I) then
           with GetHistoryEntry(I) as TCmdHistoryEntry do
             HitInfoClear;
    end;
    CmdHistory.SetModified;
    ReinitGrid;
  end;


  function TCmdMenuDlg.KeyDown(AID :Integer; AKey :Integer) :Boolean; {override;}
  begin
    Result := True;
    case AKey of
      KEY_F2:
        CommandsMenu;
      KEY_F9:
        ProfileMenu;
      KEY_CTRLF12:
        SortByMenu;

      KEY_SHIFTF8:
        ClearSelectedHits;

      KEY_CTRL2:
        ToggleOption(optShowDate);
      KEY_CTRL3:
        ToggleOption(optShowHits);
    else
      Result := inherited KeyDown(AID, AKey);
    end;
  end;


 {-----------------------------------------------------------------------------}
 {                                                                             }
 {-----------------------------------------------------------------------------}

  var
    vMenuLock :Integer;


  procedure ApplyCmd(const ACmd :TString);
  var
    vWinInfo :TWindowInfo;
  begin
    FarGetWindowInfo(-1, vWinInfo);
    if vWinInfo.WindowType = WTYPE_PANELS then begin
      FARAPI.Control(INVALID_HANDLE_VALUE, FCTL_SETCMDLINE, 0, PFarChar(ACmd));
      FarPostMacro('history.enable(1);Enter', 0);
    end else
      Beep;
  end;


  procedure InsertCmd(const ACmd :TString);
  var
    vWinInfo :TWindowInfo;
  begin
    FarGetWindowInfo(-1, vWinInfo);
    if vWinInfo.WindowType = WTYPE_PANELS then
      FARAPI.Control(INVALID_HANDLE_VALUE, FCTL_SETCMDLINE, 0, PFarChar(ACmd))
    else
      InsertText(ACmd);
  end;


  procedure TryJumpToPath(const ACmd :TString);
  var
    vPath :TString;
    vStr :PTChar;
  begin
    vPath := ACmd;
    if (ACmd <> '') and (ACmd[1] = '"') then begin
      vStr := PTChar(ACmd);
      vPath := AnsiExtractQuotedStr(vStr, '"');
    end else
      vPath := ExtractWord(1, vPath, [' ']);
    vPath := FarExpandFileName(vPath);
    if WinFileExists(vPath) or WinFolderExists(vPath) then
      JumpToPath(ExtractFilePath(vPath), ExtractFileName(vPath), False);
  end;



  procedure OpenCmdHistoryDlg(const ACaption, AModeName :TString; const AFilter :TString);
  var
    vDlg :TCmdMenuDlg;
    vFinish :Boolean;
    vFilter :TString;
  begin
    if vMenuLock > 0 then
      Exit;

    CmdHistory.LoadModifiedHistory;
    CmdHistory.UpdateHistory;

    optShowHidden := False;
    optSeparateName := False;
    optShowFullPath := True;
    optHierarchical := True;
    optHierarchyMode := hmDate;
    optShowDate := True;
    optShowHits := False;
    optSortMode := 0;

    ReadSetup(AModeName);

    Inc(vMenuLock);
    CmdHistory.LockHistory;
    vDlg := TCmdMenuDlg.Create;
    try
      vDlg.FCaption := ACaption;
      vDlg.FHistory := CmdHistory;
      vDlg.FModeName := AModeName;

      vFilter := AFilter;
      if (vFilter = '') and optSaveMask then
        vFilter := FCmdLastFilter;
      vDlg.SetFilter(vFilter);

      vFinish := False;
      while not vFinish do begin
        if vDlg.Run = -1 then
          Exit;

        case vDlg.FResCmd of
          1: ApplyCmd(vDlg.FResStr);
          2: InsertCmd(vDlg.FResStr);
          3: TryJumpToPath(vDlg.FResStr);
        end;
        vFinish := True;
      end;

    finally
      FCmdLastFilter := vDlg.GetFilter;
      FreeObj(vDlg);
      CmdHistory.UnlockHistory;
      Dec(vMenuLock);
    end;
  end;


end.
