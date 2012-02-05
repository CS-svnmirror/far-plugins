{$I Defines.inc}

unit FarMenu;

{******************************************************************************}
{* (c) 2010 Max Rusov                                                         *}
{*                                                                            *}
{* FAR Library                                                                *}
{* ��������� ������� ��� ���� FAR                                             *}
{******************************************************************************}

interface

  uses
    Windows,
    MixTypes,
    MixUtils,
    MixClasses,

    Far_API,
    FarCtrl;


  type
    TFarMenu = class(TBasis)
    public
      constructor Create; override;
      constructor CreateEx(ATitle :PTChar; const AItems :array of PFarChar); overload;
      constructor CreateEx(const ATitle :TString; const AItems :array of PFarChar); overload;
      destructor Destroy; override;

      procedure SetSelected(AIndex :Integer);

      function Run :Boolean;

    protected
      FItems    :PFarMenuItemsArray;
      FCount    :Integer;
      FTitle    :TString;
      FFooter   :TString;
      FHelp     :TString;
      FFlags    :DWORD;
      FX, FY    :Integer;
      FMaxDY    :Integer;
     {$ifdef Far3}
      FMenuID   :TGUID;
     {$endif Far3}

      FResIdx   :Integer;

      function GetChecked(AIndex :Integer) :Boolean;
      procedure SetChecked(AIndex :Integer; AValue :Boolean);
      function GetEnabled(AIndex :Integer) :Boolean;
      procedure SetEnabled(AIndex :Integer; AValue :Boolean);
      function GetVisible(AIndex :Integer) :Boolean;
      procedure SetVisible(AIndex :Integer; AValue :Boolean);

    public
      property Items :PFarMenuItemsArray read FItems;
      property Count :Integer read FCount;
      property Title :TString read FTitle write FTitle;
      property Footer :TString read FFooter write FFooter;
      property Help :TString read FHelp write FHelp;
      property Flags :DWORD read FFlags write FFlags;
     {$ifdef Far3}
      property MenuID :TGUID read FMenuID write FMenuID;
     {$endif Far3}

      property Checked[I :Integer] :Boolean read GetChecked write SetChecked;
      property Enabled[I :Integer] :Boolean read GetEnabled write SetEnabled;
      property Visible[I :Integer] :Boolean read GetVisible write SetVisible;

      property ResIdx :Integer read FResIdx;
    end;


{******************************************************************************}
{******************************} implementation {******************************}
{******************************************************************************}

  uses
    MixDebug;


 {-----------------------------------------------------------------------------}
 { TFarMenu                                                                    }
 {-----------------------------------------------------------------------------}

  constructor TFarMenu.Create; {override;}
  begin
    inherited Create;
    FFlags := FMENU_WRAPMODE
     {$ifdef Far3}
     {$else}
      or FMENU_USEEXT
     {$endif Far3};
    FX := -1;
    FY := -1;
  end;


  constructor TFarMenu.CreateEx(ATitle :PTChar; const AItems :array of PFarChar);
  begin
    Create;
    FTitle := ATitle;
    FItems := FarCreateMenu(AItems, @FCount);
  end;


  constructor TFarMenu.CreateEx(const ATitle :TString; const AItems :array of PFarChar);
  begin
    Create;
    FTitle := ATitle;
    FItems := FarCreateMenu(AItems, @FCount);
  end;


  destructor TFarMenu.Destroy; {override;}
  begin
    MemFree(FItems);
    inherited Destroy;
  end;


  procedure TFarMenu.SetSelected(AIndex :Integer);
  var
    I :Integer;
  begin
    for I := 0 to FCount - 1 do
      FItems[I].Flags := SetFlag(FItems[I].Flags, MIF_SELECTED, I = AIndex);
  end;


  function TFarMenu.GetChecked(AIndex :Integer) :Boolean;
  begin
    Result := MIF_CHECKED1 and FItems[AIndex].Flags <> 0;
  end;


  procedure TFarMenu.SetChecked(AIndex :Integer; AValue :Boolean);
  begin
    FItems[AIndex].Flags := SetFlag(FItems[AIndex].Flags, MIF_CHECKED1, AValue);
  end;


  function TFarMenu.GetEnabled(AIndex :Integer) :Boolean;
  begin
    Result := MIF_DISABLE and FItems[AIndex].Flags = 0;
  end;

  procedure TFarMenu.SetEnabled(AIndex :Integer; AValue :Boolean);
  begin
    FItems[AIndex].Flags := SetFlag(FItems[AIndex].Flags, MIF_DISABLE, not AValue);
  end;


  function TFarMenu.GetVisible(AIndex :Integer) :Boolean;
  begin
    Result := MIF_HIDDEN and FItems[AIndex].Flags = 0;
  end;

  procedure TFarMenu.SetVisible(AIndex :Integer; AValue :Boolean);
  begin
    FItems[AIndex].Flags := SetFlag(FItems[AIndex].Flags, MIF_HIDDEN, not AValue);
  end;


  function TFarMenu.Run :Boolean;
  begin
    FResIdx := FARAPI.Menu(
     {$ifdef Far3}
      PluginID,
      FMenuID,
     {$else}
      hModule,
     {$endif Far3}
      FX, FY,
      FMaxDY,
      FFlags,
      PTChar(FTitle),
      PTChar(FFooter),
      PTChar(FHelp),
      nil, nil,
      Pointer(FItems),
      FCount);

    Result := FResIdx <> -1;
  end;


end.

