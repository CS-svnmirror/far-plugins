{$I Defines.inc}

unit FarConfig;

{******************************************************************************}
{* (c) 2011 Max Rusov                                                         *}
{*                                                                            *}
{* FAR Library                                                                *}
{* ��������� ������� �������� ��������                                        *}
{******************************************************************************}

interface

  uses
    Windows,
    MixTypes,
    MixUtils,
    MixClasses,
    MixStrings,
    MixWinUtils,
   {$ifdef Far3}
    Plugin3,
   {$else}
    PluginW,
   {$endif Far3}
    FarCtrl;


  type
    TFarConfig = class(TBasis)
    public
      constructor CreateEx(AStore :Boolean; const AName :TString);
      destructor Destroy; override;

      function OpenKey(const AName :TString) :Boolean;

      procedure StrValue(const AName :TString; var AValue :TString);
      procedure IntValue(const AName :TString; var AValue :Integer);
      procedure LogValue(const AName :TString; var AValue :Boolean);
      procedure ColorValue(const AName :TString; var AValue :TFarColor);
      function IntValue1(const AName :TString; AValue :Integer) :Integer;

    private
      FStore   :Boolean;
     {$ifdef Far3}
      FHandle  :THandle;
      FCurKey  :THandle;
     {$else}
      FPath    :TString;
      FRootKey :HKEY;
      FCurKey  :HKEY;
     {$endif Far3}
      FExists  :Boolean;

    public
      property Exists :Boolean read FExists;
    end;


 {$ifdef Far3}
  function FarOpenSetings(const APluginID :TGUID) :THandle;
  function FarOpenKey(AHandle, AKey :THandle; const AName :TString) :THandle;
  function FarCreateKey(AHandle, AKey :THandle; const AName :TString) :THandle;
  function FarSetValue(AHandle, AKey :THandle; const AName :TString; AType :Integer; AInt :Int64; AStr :PFarChar) :Boolean;
  function FarGetValueInt(AHandle, AKey :THandle; const AName :TString; ADefault :Int64) :Int64;
  function FarGetValueStr(AHandle, AKey :THandle; const AName :TString; var AStr :TString) :Boolean;
 {$endif Far3}


{******************************************************************************}
{******************************} implementation {******************************}
{******************************************************************************}

  uses
    MixDebug;


(*
API ��� �������� ��������:

   int WINAPI SettingsControl(HANDLE hHandle, int Command, int Param1, INT_PTR Param2)

   Command:

   SCTL_CREATE            - hHandle - INVALID_HANDLE_VALUE.
                            Param2 - FarSettingsCreate, �� ����� guid �������, �� ������ - ����� ��������.
                            ��� ������� ����� FALSE.

   SCTL_FREE              - hHandle - HANDLE, ������� ������ SCTL_CREATE.

   SCTL_SET               - hHandle - HANDLE, ������� ������ SCTL_CREATE.
                            Param2 - ��������� �� FarSettingsItem.
                            Root - ����� ����� ���������� ��������. 0 - ������ ��� �������. �������� ���������� ��� ������ SCTL_SUBKEY.
                            Name - ��� ������������ ��������.
                            Type - ���.
                            Value - ���� ��������.

   SCTL_GET               - hHandle - HANDLE, ������� ������ SCTL_CREATE.
                            Param2 - ��������� �� FarSettingsItem.
                            Value ��������� ���, ��������� - ������.

   SCTL_CREATESUBKEY, SCTL_OPENSUBKEY (���� SCTL_SUBKEY)
                            - hHandle - HANDLE, ������� ������ SCTL_CREATE.
                            Param2 - ��������� �� FarSettingsValue.
                            ���������� ��������� �������� � ������ Value ��� ����� � ���������� Root.

   SCTL_ENUM              - �������� ����� ��������� � ��������.
                            hHandle - HANDLE, ������� ������ SCTL_CREATE.
                            Param2 - ��������� �� FarSettingsEnum.
                            Root - ��������� �����, ������ ����� ����������.
                            Count - ���������� ������������ ���������.
                            Items - ��������.

   SCTL_DELETE            - ������� ������� ��� ��������.
                            hHandle - HANDLE, ������� ������ SCTL_CREATE.
                            Param2 - ��������� �� FarSettingsValue.
                            Root - ��������� �����, � ������� ��������� ���������.
                            Value - ��� �������� ��� ��������, ������� ���� �������.
*)


 {$ifdef Far3}
  function FarOpenSetings(const APluginID :TGUID) :THandle;
  var
    vCreate :TFarSettingsCreate;
  begin
    Result := 0;
    vCreate.StructSize := SizeOf(vCreate);
    vCreate.Guid := APluginID;
    vCreate.Handle := 0;
    if FARAPI.SettingsControl(INVALID_HANDLE_VALUE, SCTL_CREATE, 0, @vCreate) <> 0 then
      Result := vCreate.Handle;
  end;


  function FarOpenKey(AHandle, AKey :THandle; const AName :TString) :THandle;
  var
    vItem :TFarSettingsValue;
  begin
    vItem.Root := AKey;
    vItem.Value := PFarChar(AName);
    Result := THandle(FARAPI.SettingsControl(AHandle, SCTL_OPENSUBKEY, 0, @vItem));
  end;


  function FarCreateKey(AHandle, AKey :THandle; const AName :TString) :THandle;
  var
    vItem :TFarSettingsValue;
  begin
    vItem.Root := AKey;
    vItem.Value := PFarChar(AName);
    Result := THandle(FARAPI.SettingsControl(AHandle, SCTL_CREATESUBKEY, 0, @vItem));
  end;


  function FarSetValue(AHandle, AKey :THandle; const AName :TString; AType :Integer; AInt :Int64; AStr :PFarChar) :Boolean;
  var
    vItem :TFarSettingsItem;
  begin
    vItem.Root := AKey;
    vItem.Name := PFarChar(AName);
    vItem.FType := AType;
    case AType of
      FST_QWORD:
        vItem.Value.Number := AInt;
      FST_STRING:
        vItem.Value.Str := AStr;
      FST_DATA: begin
        vItem.Value.Data.Size := AInt;
        vItem.Value.Data.Data := AStr;
      end;
    end;
    Result := FARAPI.SettingsControl(AHandle, SCTL_SET, 0, @vItem) <> 0;
  end;


  function FarGetValueInt(AHandle, AKey :THandle; const AName :TString; ADefault :Int64) :Int64;
  var
    vItem :TFarSettingsItem;
  begin
    FillZero(vItem, SIzeOf(vItem));
    vItem.Root := AKey;
    vItem.Name := PFarChar(AName);
    vItem.FType := FST_QWORD;
    if FARAPI.SettingsControl(AHandle, SCTL_GET, 0, @vItem) <> 0 then
      Result := vItem.Value.Number
    else
      Result := ADefault;
  end;


  function FarGetValueStr(AHandle, AKey :THandle; const AName :TString; var AStr :TString) :Boolean;
  var
    vItem :TFarSettingsItem;
  begin
    FillZero(vItem, SIzeOf(vItem));
    vItem.Root := AKey;
    vItem.Name := PFarChar(AName);
    vItem.FType := FST_STRING;
    Result := FARAPI.SettingsControl(AHandle, SCTL_GET, 0, @vItem) <> 0;
    if Result then
      AStr := vItem.Value.Str;
  end;
 {$endif Far3}


 {-----------------------------------------------------------------------------}
 { TFarConfig                                                                  }
 {-----------------------------------------------------------------------------}

  constructor TFarConfig.CreateEx(AStore :Boolean; const AName :TString);
  begin
    Create;
    FStore := AStore;
   {$ifdef Far3}
    FHandle := FarOpenSetings(PluginID);
    FExists := FHandle <> 0;
    FCurKey := 0;
   {$else}
    FPath := TString(FARAPI.RootKey) + '\' + AName;
    if AStore then begin
      RegOpenWrite(HKCU, FPath, FRootKey);
      FExists := True;
    end else
      FExists := RegOpenRead(HKCU, FPath, FRootKey);
    FCurKey := FRootKey;
   {$endif Far3}
  end;


  destructor TFarConfig.Destroy; {override;}
  begin
   {$ifdef Far3}
    if FHandle <> 0 then
      FARAPI.SettingsControl(FHandle, SCTL_FREE, 0, nil);
   {$else}
    if (FCurKey <> 0) and (FCurKey <> FRootKey) then
      RegCloseKey(FCurKey);
    if FRootKey <> 0 then
      RegCloseKey(FRootKey);
   {$endif Far3}
    inherited Destroy;
  end;


  function TFarConfig.OpenKey(const AName :TString) :Boolean;
  var
    vName :TString;
   {$ifdef Far3}
    vPtr :PTChar;
   {$endif Far3}
  begin
   {$ifdef Far3}
    FCurKey := 0;
    Result := True;
    if AName <> '' then begin
      vPtr := PTChar(AName);
      while (vPtr^ <> #0) and (Result) do begin
        vName := ExtractNextWord(vPtr, ['\']);
        if FStore then
          FCurKey := FarCreateKey(FHandle, FCurKey, vName)
        else
          FCurKey := FarOpenKey(FHandle, FCurKey, vName);
        Result := FCurKey <> 0;
      end;
    end;
   {$else}
    if AName = '' then begin
      if (FCurKey <> 0) and (FCurKey <> FRootKey) then
        RegCloseKey(FCurKey);
      FCurKey := FRootKey;
      Result := True;
    end else
    begin
      vName := FPath + '\' + AName;
      if FStore then begin
        RegOpenWrite(HKCU, vName, FCurKey);
        Result := True;
      end else
        Result := RegOpenRead(HKCU, vName, FCurKey);
    end
   {$endif Far3}
  end;


  procedure TFarConfig.StrValue(const AName :TString; var AValue :TString);
  begin
   {$ifdef Far3}
    if FStore then
      FarSetValue(FHandle, FCurKey, AName, FST_STRING, 0, PTChar(AValue))
    else
      FarGetValueStr(FHandle, FCurKey, AName, AValue);
   {$else}
    if FStore then
      RegWriteStr(FCurKey, AName, AValue)
    else
      AValue := RegQueryStr(FCurKey, AName, AValue);
   {$endif Far3}
  end;


  procedure TFarConfig.IntValue(const AName :TString; var AValue :Integer);
  begin
   {$ifdef Far3}
    if FStore then
      FarSetValue(FHandle, FCurKey, AName, FST_QWORD, AValue, nil)
    else
      AValue := FarGetValueInt(FHandle, FCurKey, AName, AValue);
   {$else}
    if FStore then
      RegWriteInt(FCurKey, AName, AValue)
    else
      AValue := RegQueryInt(FCurKey, AName, AValue);
   {$endif Far3}
  end;


  function TFarConfig.IntValue1(const AName :TString; AValue :Integer) :Integer;
  begin
    IntValue(AName, AValue);
    Result := AValue;
  end;


  procedure TFarConfig.LogValue(const AName :TString; var AValue :Boolean);
  var
    vInt :Integer;
  begin
    vInt := Byte(AValue);
    IntValue(AName, vInt);
    AValue := vInt <> 0;
  end;


  procedure TFarConfig.ColorValue(const AName :TString; var AValue :TFarColor);
 {$ifdef Far3}
  var
    vInt :Int64;
  begin
    vInt := MakeInt64(GetColorFG(AValue), GetColorBG(AValue));
    if FStore then
      FarSetValue(FHandle, FCurKey, AName, FST_QWORD, vInt, nil)
    else begin
      vInt := FarGetValueInt(FHandle, FCurKey, AName, vInt);
      AValue := MakeColor(Int64Rec(vInt).Lo, Int64Rec(vInt).Hi);
    end;
 {$else}
  begin
    IntValue(AName, Integer(AValue));
 {$endif Far3}
  end;



end.
