{$I Defines.inc}

unit MoreHistoryOptionsDlg;

{******************************************************************************}
{* (c) 2009-2011, Max Rusov                                                   *}
{*                                                                            *}
{* MoreHistory plugin                                                         *}
{* ������ �����                                                               *}
{******************************************************************************}

interface

  uses
    Windows,
    MixTypes,
    MixUtils,
    MixStrings,
    MixClasses,
    Far_API,
    FarCtrl,
    FarDlg,
    MoreHistoryCtrl;


  function OptionsDlg :Boolean;


{******************************************************************************}
{******************************} implementation {******************************}
{******************************************************************************}


  uses
    MixDebug;


  type
    TOptionsDlg = class(TFarDialog)
    public
      constructor Create; override;

    protected
      procedure Prepare; override;
      procedure InitDialog; override;
      function CloseDialog(ItemID :Integer) :Boolean; override;
    end;


  constructor TOptionsDlg.Create; {override;}
  begin
    inherited Create;
  end;


  const
    IdHistLimit       =  2;

    IdHideCurrent     =  3;
    IdCaseSensCmdHist =  4;

    IdWrapMode        =  6;
    IdFollowMouse     =  7;
    IdShowHints       =  8;

    IdXLatMask        =  9;
    IdSaveMask        = 10;

    IdMidnightHour    = 12;

    IdCancel          = 15;


  procedure TOptionsDlg.Prepare; {override;}
  const
    DX = 72;
    DY = 17;
  var
    vPrompt1, vPrompt2 :PTChar;
    X2 :Integer;
  begin
    FHelpTopic := 'Options';
    FWidth := DX;
    FHeight := DY;

    vPrompt1 := GetMsg(strHistoryLimit);
    vPrompt2 := GetMsg(strMidnightHour);

    X2 := DX div 2;

    FDialog := CreateDialog(
      [
        NewItemApi(DI_DoubleBox, 3,  1,   DX-6, DY-2, 0, GetMsg(strGeneralOptionsTitle)),

        NewItemApi(DI_Text,      5,  2,   strlen(vPrompt1), -1,     0, PTChar(vPrompt1) ),
        NewItemApi(DI_FixEdit,   5 + strlen(vPrompt1), 2,   5, -1,  0),

        NewItemApi(DI_CHECKBOX,  5,  4,  -1, -1,  0, GetMsg(strMHideCurrent)),
        NewItemApi(DI_CHECKBOX,  5,  5,  -1, -1,  0, GetMsg(strCaseSensitiveCommands)),

        NewItemApi(DI_Text,      0,  7,  -1, -1, DIF_SEPARATOR, GetMsg(strVisualizationOptions)),

        NewItemApi(DI_CHECKBOX,  5,  8,  -1, -1,  0, GetMsg(strWrapMode)),
        NewItemApi(DI_CHECKBOX,  5,  9,  -1, -1,  0, GetMsg(strFollowMouse)),
        NewItemApi(DI_CHECKBOX,  5, 10,  -1, -1,  0, GetMsg(strShowHints)),

        NewItemApi(DI_CHECKBOX,  X2, 8,  -1, -1,  0, GetMsg(strAutoXLatMask)),
        NewItemApi(DI_CHECKBOX,  X2, 9,  -1, -1,  0, GetMsg(strRememberLastMask)),

        NewItemApi(DI_Text,      5, 12,   strlen(vPrompt2), -1,   0, PTChar(vPrompt2) ),
        NewItemApi(DI_FixEdit,   5 + strlen(vPrompt2),  12,   3,  -1,  0),

        NewItemApi(DI_Text,      0, DY-4, -1, -1, DIF_SEPARATOR),
        NewItemApi(DI_DefButton, 0, DY-3, -1, -1, DIF_CENTERGROUP, GetMsg(strOk) ),
        NewItemApi(DI_Button,    0, DY-3, -1, -1, DIF_CENTERGROUP, GetMsg(strCancel) )
      ], @FItemCount
    );
  end;

  procedure TOptionsDlg.InitDialog; {override;}
  begin
    SetText(IdHistLimit, Int2Str(optHistoryLimit));
    SetText(IdMidnightHour, Int2Str(optMidnightHour));

    SetChecked(IdShowHints, optShowHints);
    SetChecked(IdWrapMode, optWrapMode);
    SetChecked(IdFollowMouse, optFollowMouse);
    SetChecked(IdXLatMask, optXLatMask);
    SetChecked(IdSaveMask, optSaveMask);
    SetChecked(IdHideCurrent, optHideCurrent);
    SetChecked(IdCaseSensCmdHist, optCaseSensCmdHist = 1);
  end;


  function TOptionsDlg.CloseDialog(ItemID :Integer) :Boolean; {override;}
  var
    vLimit, vHour :Integer;
  begin
    if (ItemID <> -1) and (ItemID <> IdCancel) then begin

      vLimit := Str2IntDef(GetText(IdHistLimit), -1);
      if (vLimit < cMinHistoryLimit) or (vLimit > cMaxHistoryLimit) then begin
        SendMsg(DM_SetFocus, IdHistLimit, 0);
        AppErrorIdFmt(byte(strValidRangeError), [cMinHistoryLimit, cMaxHistoryLimit]);
      end;

      vHour := Str2IntDef(GetText(IdMidnightHour), -1);
      if (vHour < 0) or (vHour > 23) then begin
        SendMsg(DM_SetFocus, IdMidnightHour, 0);
        AppErrorIdFmt(byte(strValidRangeError), [0, 23]);
      end;

      optHistoryLimit := vLimit;
      optMidnightHour := vHour;

      optShowHints := GetChecked(IdShowHints);
      optWrapMode := GetChecked(IdWrapMode);
      optFollowMouse := GetChecked(IdFollowMouse);
      optXLatMask := GetChecked(IdXLatMask);
      optSaveMask := GetChecked(IdSaveMask);
      optHideCurrent := GetChecked(IdHideCurrent);
      optCaseSensCmdHist := IntIf(GetChecked(IdCaseSensCmdHist), 1, 0);
    end;
    Result := True;
  end;


 {-----------------------------------------------------------------------------}
 {                                                                             }
 {-----------------------------------------------------------------------------}

  function OptionsDlg :Boolean;
  var
    vDlg :TOptionsDlg;
    vRes :Integer;
  begin
    Result := False;

    vDlg := TOptionsDlg.Create;
    try
      vRes := vDlg.Run;
      if (vRes = -1) or (vRes = IdCancel) then
        Exit;

      WriteSetup('');

      Result := True;
    finally
      FreeObj(vDlg);
    end;
  end;


end.

