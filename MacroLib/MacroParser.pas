{$I Defines.inc}

unit MacroParser;

{******************************************************************************}
{* (c) 2011 Max Rusov                                                         *}
{*                                                                            *}
{* FAR Macro Library                                                          *}
{* ������ ����������                                                          *}
{******************************************************************************}

interface

  uses
    Windows,
    ActiveX,

    MixTypes,
    MixUtils,
    MixWinUtils,
    MixStrings,
    MixClasses,

   {$ifdef Far3}
    Plugin3,
   {$else}
    PluginW,
   {$endif Far3}
    FarCtrl,
    MacroLibConst;


  var
    ParserResBase :Integer;


  type
    TMacroParser = class;

    TLexType = (
      lexError,
      lexWord,
      lexString,
      lexNumber,
      lexSymbol,
      lexStartSeq,
      lexEOF
    );

    TParseError = (
      errFatalError,
      errKeywordExpected,
      errIdentifierExpected,
      errAlreadyDeclared,
      errUnknownKeyword,
      errUnknownConst,
      errExpectMacroBody,
      errExpectEqualSign,
      errExpectValue,
      errExceptString,
      errUnclosedString,
      errBadNumber,
      errBadGUID,
      errBadHotkey,
      errBadMacroarea,
      errBadCondition,
      errBadEvent,
      errExpectColon,
      errExpect0or1,
      errUnexpectedEOF,
      errBadMacroSequence,
      errFileNotFound,
      errRecursiveInclude,
      wrnUnknownParam
    );

    TIntArray = array of Integer;
    TGUIDArray = array of TGUID;

    PStrArray = ^TStrArray;
    TStrArray = array of TString;

    TMacroOption =
    (
      moDisableOutput,
      moSendToPlugins,
      moRunOnRelease,
      moEatOnRun,
      moDefineAKey
    );
    TMacroOptions = set of TMacroOption;

    TMacroCondition =
    (
      mcCmdLineEmpty,
      mcCmdLineNotEmpty,
      mcBlockNotSelected,
      mcBlockSelected,
      mcPanelTypeFile,
      mcPanelTypePlugin,
      mcPanelItemFile,
      mcPanelItemFolder,
      mcPanelNotSelected,
      mcPanelSelected,
      mcPPanelTypeFile,
      mcPPanelTypePlugin,
      mcPPanelItemFile,
      mcPPanelItemFolder,
      mcPPanelNotSelected,
      mcPPanelSelected
    );
    TMacroConditions = set of TMacroCondition;

    TMacroArea =
    (
      maOther,
      maShell,
      maViewer,
      maEditor,
      maDialog,
      maSearch,
      maDisks,
      maMainMenu,
      maMenu,
      maHelp,
      maInfoPanel,
      maQViewPanel,
      maTreePanel,
      maFindFolder,
      maUserMenu,
      maAutoCompletion
    );
    TMacroAreas = set of TMacroArea;

    TMacroEvent =
    (
      meOpen,
      meGotFocus
    );
    TMacroEvents = set of TMacroEvent;

    TKeyModifier =
    (
      kmPress,
//    kmOnce,
      kmSingle,
      kmDouble,
      kmHold,
      kmRelease,
      kmDown,
      kmUp
    );

    TKeyRec = record
      Key  :Integer;
      KMod :TKeyModifier;
    end;

    TKeyArray = array of TKeyRec;

    TMacroRec = record
      Name     :TString;           { ��� ������� (��� ������ �� �����, ��������������) }
      Descr    :TString;           { �������� ������� (��� ������ ������������) }
      Bind     :TKeyArray;         { ������ ����� ������ � �������������� - array of TKeyRec }
      Area     :TMacroAreas;       { ������� ����� MacroAreas }
      Dlgs     :TGUIDArray;        { ������ GUID-�� �������� - ��� �������� ������� � ������� }
      Dlgs1    :TStrArray;         { ������ ���������� �������� - �������������� ������� �������� }
      Edts     :TStrArray;         { ������ ����� ������ ��� �������� � ��������� }
      Views    :TStrArray;         { -/-/- � viewer'� }
      Cond     :TMacroConditions;  { ������� ����� ��� ����������� ������� ������������ }
      Events   :TMacroEvents;      { ������� ������������ �� �������� }
      Where    :TString;           { ������� ������������ � ���� ����������� ��������� - �� �������, ���� �� ������������ }
      Priority :Integer;           { ��������� �������, ��� ���������� ���������� }
      Options  :TMacroOptions;     { ����� ���������� �������: DisableOutput, SendToPlugins, EatOnRun }
      Text     :TString;           { ����� ����������������������� }
      Row, Col :Integer;           { �������� � ��������� ������ }
      Index    :Integer;           { ���������� ����� ������� }
    end;

    PStackRec = ^TStackRec;
    TStackRec = record
      SName :TString;
      SText :TString;
      SPtr  :PTChar;
      SRow  :Integer;
      SBeg  :PTChar;
      SCur  :PTChar;
    end;


    TMacroConst = class(TNamedObject)
    public
      function CompareKey(Key :Pointer; Context :TIntPtr) :Integer; override;
    end;

    TIntMacroConst = class(TMacroConst)
    public
      Num :Integer;
      constructor CreateEx(const AName :TString; ANum :Integer);
    end;

    TStrMacroConst = class(TMacroConst)
    public
      Str :TString;
      constructor CreateEx(const AName :TString; const AStr :TString);
    end;


    TGrowBuf = class(TBasis)
    public
      constructor Create; override;
      destructor Destroy; override;

      procedure Clear;
      procedure Add(APtr :PTChar; ALen :Integer);
      procedure AddChars(AChr :TChar; ALen :Integer);
      procedure AddInt(AInt :Integer);
      procedure AddStr(const AStr :TString);

      function GetStrValue :TString;
      function GetIntValue(var ANum :Integer) :Boolean;

    private
      FBuf  :PTChar;
      FLen  :Integer;
      FSize :Integer;

      procedure SetSize(ANewSize :Integer);

    public
      property Len :Integer read FLen;
      property Buf :PTChar read FBuf;
    end;


    EParseError = class(Exception)
    public
      FRow :Integer;
      FCol :Integer;

      constructor CreateEx(ACode :TParseError; ARow, ACol :Integer);
    end;

    TOnAddEvent = procedure(Sender :TMacroParser; const ARec :TMacroRec) of object;
    TOnError = procedure(Sender :TMacroParser; ACode :Integer; const AMessage :TString; const AFileName :TString; ARow, ACol :Integer) of object;

    TMacroParser = class(TBasis)
    public
      constructor Create; override;
      destructor Destroy; override;

      function Parse(AText :PTChar) :boolean;
      function ParseFile(const AFileName :TString) :boolean;

      procedure ShowSequenceError;

    private
      FFileName  :TString;
      FSafe      :Boolean;
      FCheckBody :Boolean;

      FMacro     :TMacroRec;
      FCount     :Integer;

      FText      :TString;
      FRow       :Integer;
      FBeg       :PTChar;
      FCur       :PTChar;

      FBuf       :TGrowBuf;
      FSeq       :TGrowBuf;

      FSeqRow    :Integer;
      FSeqCol    :Integer;

      FConsts    :TObjList;
      FStack     :TExList;

      FOnAdd     :TOnAddEvent;
      FOnError   :TOnError;

      procedure Error(ACode :TParseError; ARow :Integer = 0; ACol :Integer = 0);
      procedure Warning(ACode :TParseError; ARow :Integer = 0; ACol :Integer = 0);
      procedure Warning1(ACode :TParseError; APtr :PTChar);

      procedure ParseMacro(var APtr :PTChar);
      procedure ParseConst(var APtr :PTChar);
      procedure ParseInclude(var APtr :PTChar);
      procedure ParseMacroSequence(var APtr :PTChar);
      procedure CheckMacroSequence(const AText :TString; ASilence :Boolean);
      function GetLex(var APtr :PTChar; var AParam :PTChar; var ALen :Integer) :TLexType;
      procedure PushStack(var AText :TString; var APtr :PTChar);
      procedure PopStack(var APtr :PTChar);
      function FindMacroConst(AName :PTChar; ALen :Integer = -1) :TMacroConst;
      procedure SkipSpacesAndComments(var APtr :PTChar);
      procedure SkipLineComment(var APtr :PTChar);
      procedure SkipMultilineComment(var APtr :PTChar);
      procedure SkipCRLF(var APtr :PTChar);
      procedure ParseBindStr(APtr :PTChar; var ARes :TKeyArray);
      procedure ParseAreaStr(APtr :PTChar; var ARes :TMacroAreas);
      procedure ParseCondStr(APtr :PTChar; var ARes :TMacroConditions);
      procedure ParseEventStr(APtr :PTChar; var ARes :TMacroEvents);
      function GetIntValue :Integer;
      procedure SetMacroParam(AParam :Integer; ALex :TLexType);
      procedure AddMacro;
      procedure NewMacro;
      procedure ShowError(E :EParseError);

    public
      property FileName :TString read FFileName;
      property Safe :Boolean read FSafe write FSafe;
      property CheckBody :Boolean read FCheckBody write FCheckBody;
      property OnAdd :TOnAddEvent read FOnAdd write FOnAdd;
      property OnError :TOnError read FOnError write FOnError;
    end;


  function KeyNameParse(AName :PTChar; var AKey :Integer; var AMod :TKeyModifier) :Boolean;

  procedure MoveStrArray(const ASrc :TStrArray; var ADst :TStrArray);
  procedure SetMacroOption(var AOptions :TMacroOptions; AOption :TMacroOption; AOn :Boolean);
  procedure SetMacroCondition(var AConditions :TMacroConditions; ACondition :TMacroCondition; AOn :Boolean);

  function AreaToName(Area :TMacroArea) :TString;
  function KeyModToName(AMod :TKeyModifier) :TString;

{******************************************************************************}
{******************************} implementation {******************************}
{******************************************************************************}

  uses
    MixDebug;

  const
    cLineComment1 = ';;';
    cLineComment2 = '//';

    cInLineCommentBeg = '/*';
    cInLineCommentEnd = '*/';

  const
    kwMacro     = 1;
    kwConst     = 2;
    kwInclude   = 3;
    kwName      = 4;
    kwDescr     = 5;
    kwBind      = 6;
    kwWhere     = 7;
    kwArea      = 8;
    kwCond      = 9;
    kwEvent     = 10;
    kwPriority  = 11;
    kwSilence   = 12;
    kwSendPlug  = 13;
    kwRunOnRel  = 14;
    kwEatOnRun  = 15;

  const
    kwpInclude  = 1;
    kwpAKey     = 2;
//  kwpAKeyC    = 3;



  procedure MoveStrArray(const ASrc :TStrArray; var ADst :TStrArray);
  var
    L :Integer;
  begin
    L := Length(ASrc);
    SetLength(ADst, L);
    if L > 0 then begin
      Move(ASrc[0], ADst[0], L * SizeOf(pointer));
      FillZero(ASrc[0], L * SizeOf(pointer));
    end;
  end;


  procedure SetMacroOption(var AOptions :TMacroOptions; AOption :TMacroOption; AOn :Boolean);
  begin
    if AOn then
      Include(AOptions, AOption)
    else
      Exclude(AOptions, AOption);
  end;


  procedure SetMacroCondition(var AConditions :TMacroConditions; ACondition :TMacroCondition; AOn :Boolean);
  begin
    if AOn then
      Include(AConditions, Succ(ACondition))
    else
      Include(AConditions, ACondition);
  end;


  function MatchStr(APtr, AMatch :PTChar) :Boolean;
  begin
    while (AMatch^ <> #0) and (APtr^ = AMatch^) do begin
      Inc(AMatch);
      Inc(APtr);
    end;
    Result := AMatch^ = #0;
  end;



  const
    cWordDelims = [' ', ',', ';', charTab];

  function CanExtractNext(var APtr :PTChar; ABuf :PTChar; AMaxLen :Integer; const ADelims :TAnsiCharSet = cWordDelims) :Boolean;
  var
    vBeg :PTChar;
  begin
    Result := False;
    ABuf^ := #0;
    while ChrInSet(APtr^, ADelims) do
      Inc(APtr);
    if APtr^ <> #0 then begin
      vBeg := APtr;
      while (APtr^ <> #0) and not ChrInSet(APtr^, ADelims) do
        Inc(APtr);
      StrLCopy(ABuf, vBeg, IntMin(AMaxLen, APtr - vBeg));
      Result := True;
    end;
  end;


  function CanExtractNextWord(var APtr :PTChar; ABuf :PTChar; AMaxLen :Integer) :Boolean;
  var
    vBeg :PTChar;
  begin
    Result := False;
    while (APtr^ <> #0) and not CharIsWordChar(APtr^) do
      Inc(APtr);
    if APtr^ <> #0 then begin
      vBeg := APtr;
      while (APtr^ <> #0) and CharIsWordChar(APtr^) do
        Inc(APtr);
      StrLCopy(ABuf, vBeg, IntMin(AMaxLen, APtr - vBeg));
      Result := True;
    end;
  end;


 {-----------------------------------------------------------------------------}
 {                                                                             }
 {-----------------------------------------------------------------------------}

  constructor EParseError.CreateEx(ACode :TParseError; ARow, ACol :Integer);
  begin
    CreateHelp('', byte(ACode));
    FRow := ARow;
    FCol := ACol;
  end;


 {-----------------------------------------------------------------------------}
 { TKeywords                                                                   }
 {-----------------------------------------------------------------------------}

  var
    Keywords :TKeywordsList;
    KeyAreas :TKeywordsList;
    KeyConds :TKeywordsList;
    KeyEvnts :TKeywordsList;
    KeyMods  :TKeywordsList;
    KeyPrepr :TKeywordsList;

  procedure InitKeywords;
  begin
    if Keywords <> nil then
      Exit;

    Keywords := TKeywordsList.Create;
    with Keywords do begin
      Add('MACRO', kwMacro); Add('$MACRO',kwMacro);
      Add('CONST', kwConst);
      Add('INCLUDE', kwInclude);

      Add('NAME',  kwName);
      Add('DESCR', kwDescr); Add('DESCRIPTION', kwDescr);
      Add('BIND',  kwBind);  Add('KEY',kwBind); Add('KEYS',kwBind); Add('HOTKEY',kwBind); Add('HOTKEYS',kwBind);
      Add('WHERE', kwWhere); Add('IF', kwWhere);
      Add('AREA',  kwArea);  Add('AREAS',  kwArea);
      Add('COND',  kwCond);  Add('CONDITION', kwCond);
      Add('EVENT', kwEvent); Add('EVENTS', kwEvent);

      Add('PRIORITY',      kwPriority);
      Add('DISABLEOUTPUT', kwSilence);
      Add('SENDTOPLUGIN',  kwSendPlug);
      Add('RUNONRELEASE',  kwRunOnRel);
      Add('EATONRUN',      kwEatOnRun);
    end;

    KeyAreas := TKeywordsList.Create;
    with KeyAreas do begin
      Add('Shell',     MACROAREA_SHELL);
      Add('Viewer',    MACROAREA_VIEWER);
      Add('Editor',    MACROAREA_EDITOR);
      Add('Dialog',    MACROAREA_DIALOG);
      Add('Search',    MACROAREA_SEARCH);
      Add('Disks',     MACROAREA_DISKS);
      Add('MainMenu',  MACROAREA_MAINMENU);
      Add('Menu',      MACROAREA_MENU);
      Add('Help',      MACROAREA_HELP);
      Add('Info',      MACROAREA_INFOPANEL);      Add('InfoPanel',      MACROAREA_INFOPANEL);
      Add('QView',     MACROAREA_QVIEWPANEL);     Add('QViewPanel',     MACROAREA_QVIEWPANEL);
      Add('Tree',      MACROAREA_TREEPANEL);      Add('TreePanel',      MACROAREA_TREEPANEL);
      Add('FFolder',   MACROAREA_FINDFOLDER);     Add('FindFolder',     MACROAREA_FINDFOLDER);
      Add('UserMenu',  MACROAREA_USERMENU);
      Add('ACompl',    MACROAREA_AUTOCOMPLETION); Add('AutoCompletion', MACROAREA_AUTOCOMPLETION);
    end;

    KeyConds := TKeywordsList.Create;
    with KeyConds do begin
      Add('CmdLine',        byte(mcCmdLineEmpty));
      Add('Selected',       byte(mcBlockNotSelected));

      Add('PanelType',      byte(mcPanelTypeFile));
      Add('PanelItem',      byte(mcPanelItemFile));
      Add('PanelSelected',  byte(mcPanelNotSelected));

      Add('PPanelType',     byte(mcPPanelTypeFile));
      Add('PPanelItem',     byte(mcPPanelItemFile));
      Add('PPanelSelected', byte(mcPPanelNotSelected));
    end;

    KeyEvnts := TKeywordsList.Create;
    with KeyEvnts do begin
      Add('Open',           byte(meOpen));
      Add('GotFocus',       byte(meGotFocus));
    end;

    KeyMods := TKeywordsList.Create;
    with KeyMods do begin
      Add('Press',    byte(kmPress));
//    Add('Once',     byte(kmOnce));
      Add('Single',   byte(kmSingle));
      Add('Double',   byte(kmDouble));
      Add('Hold',     byte(kmHold));
      Add('Release',  byte(kmRelease));
      Add('Down',     byte(kmDown));
      Add('Up',       byte(kmUp));
    end;

    KeyPrepr := TKeywordsList.Create;
    with KeyPrepr do begin
      Add('Include',        byte(kwpInclude));
      Add('AKey',           byte(kwpAKey));
    end;
  end;


  function AreaToName(Area :TMacroArea) :TString;
  begin
    InitKeywords;
    Result := KeyAreas.NameByKey(byte(Area));
  end;


  function KeyModToName(AMod :TKeyModifier) :TString;
  begin
    InitKeywords;
    Result := KeyMods.NameByKey(byte(AMod));
  end;


 {-----------------------------------------------------------------------------}
 { TGrowBuf                                                                    }
 {-----------------------------------------------------------------------------}

  constructor TGrowBuf.Create; {override;}
  begin
    inherited Create;
    SetSize(1);
  end;

  destructor TGrowBuf.Destroy; {override;}
  begin
    FreeMem(FBuf);
    inherited Destroy;
  end;


  procedure TGrowBuf.Clear;
  begin
    FLen := 0;
    FBuf^ := #0;
  end;

  procedure TGrowBuf.Add(APtr :PTChar; ALen :Integer);
  begin
    if FLen + ALen + 1 > FSize then
      SetSize(FLen + ALen + 1);
    if ALen = 1 then
      (FBuf + FLen)^ := APtr^
    else
      StrMove(FBuf + FLen, APtr, ALen);
    Inc(FLen, ALen);
    (FBuf + FLen)^ := #0;
  end;

  procedure TGrowBuf.AddChars(AChr :TChar; ALen :Integer);
  begin
    if FLen + ALen + 1 > FSize then
      SetSize(FLen + ALen + 1);
    MemFillChar(FBuf + FLen, ALen, AChr);
    Inc(FLen, ALen);
    (FBuf + FLen)^ := #0;
  end;


  procedure TGrowBuf.AddInt(AInt :Integer);
  var
    vStr :TString;
  begin
    vStr := Int2Str(AInt);
    Add(PTChar(vStr), length(vStr));
  end;


  procedure TGrowBuf.AddStr(const AStr :TString);
  begin
    Add(PTChar(AStr), length(AStr));
  end;


  procedure TGrowBuf.SetSize(ANewSize :Integer);
  const
    cAlign = $100;
  begin
    ANewSize := (((ANewSize + cAlign - 1) div cAlign) * cAlign);
    ReallocMem(FBuf, ANewSize * SizeOf(TChar));
    FSize := ANewSize;
  end;


  function TGrowBuf.GetStrValue :TString;
  begin
    SetString(Result, FBuf, FLen);
  end;


  function TGrowBuf.GetIntValue(var ANum :Integer) :Boolean;
  var
    vErr :Integer;
  begin
    Val(FBuf, ANum, vErr);
    Result := vErr = 0;
  end;



 {-----------------------------------------------------------------------------}
 { TXXXMacroConst                                                              }
 {-----------------------------------------------------------------------------}

  function TMacroConst.CompareKey(Key :Pointer; Context :TIntPtr) :Integer; {override;}
  begin
    if Context <> 0 then
      Result := UpCompareBuf(PTChar(FName)^, Key^, -1, Context)
    else
      Result := inherited CompareKey(Key, Context);
  end;


  constructor TIntMacroConst.CreateEx(const AName :TString; ANum :Integer);
  begin
    CreateName(AName);
    Num := ANum;
  end;


  constructor TStrMacroConst.CreateEx(const AName :TString; const AStr :TString);
  begin
    CreateName(AName);
    Str := AStr;
  end;


 {-----------------------------------------------------------------------------}
 { TMacroParser                                                                }
 {-----------------------------------------------------------------------------}

  constructor TMacroParser.Create;
  begin
    inherited Create;
    InitKeywords;
    FBuf := TGrowBuf.Create;
    FSeq := TGrowBuf.Create;
    FConsts := TObjList.Create;
    FStack := TExList.CreateSize(SizeOf(TStackRec));
  end;


  destructor TMacroParser.Destroy; {override;}
  begin
    FreeObj(FBuf);
    FreeObj(FSeq);
    FreeObj(FConsts);
    FreeObj(FStack);
    inherited Destroy;
  end;


  procedure TMacroParser.Error(ACode :TParseError; ARow :Integer = 0; ACol :Integer = 0);
  begin
    raise EParseError.CreateEx(ACode, ARow, ACol);
  end;


  procedure TMacroParser.Warning(ACode :TParseError; ARow :Integer = 0; ACol :Integer = 0);
  begin
    if FSafe then
      {}
    else
      Error(ACode, ARow, ACol);
  end;


  function TMacroParser.ParseFile(const AFileName :TString) :boolean;
  begin
    FFileName := AFileName;

    { ������ ���� }
    FText := StrFromFile(AFileName);

    Result := Parse(PTChar(FText));
  end;


  function TMacroParser.Parse(AText :PTChar) :boolean;
  var
    vPtr, vParam :PTChar;
    vLen, vKey :Integer;
    vLex :TLexType;
  begin
    Result := False;
    try
      FRow := 0;
      FBeg := AText;
      FCur := FBeg;
      vPtr := AText;
      while vPtr^ <> #0 do begin
        vLex := GetLex(vPtr, vParam, vLen);
        if vLex = lexEOF then
          Break;
        if vLex <> lexWord then
          Error(errKeywordExpected);

        vKey := Keywords.GetKeyword(vParam, vLen);
        if vKey = kwMacro then
          ParseMacro(vPtr)
        else
        if vKey = kwConst then
          ParseConst(vPtr)
        else
        if vKey = kwInclude then
          ParseInclude(vPtr)
        else
          Error(errUnknownKeyword);
      end;

      Result := True;

    except
      on E :EParseError do
        ShowError(E);
      else
        raise;
    end;
  end;


  procedure TMacroParser.ParseConst(var APtr :PTChar);
  var
    vParam :PTChar;
    vLen, vIndex :Integer;
    vLex :TLexType;
    vName :TString;
    vObj :TNamedObject;
  begin
    vLex := GetLex(APtr, vParam, vLen);
    if vLex = lexWord then begin

      SetString(vName, vParam, vLen);
      if FConsts.FindKey(Pointer(vName), 0, [foBinary], vIndex) then
        Warning(errAlreadyDeclared);

      vLex := GetLex(APtr, vParam, vLen);
      if (vLex = lexSymbol) and (vParam^ = '=') then begin

        vLex := GetLex(APtr, vParam, vLen);
        if (vLex <> lexString) and (vLex <> lexNumber) then
          Error(errExpectValue);

        FCur := APtr;

        if vLex = lexString then
          vObj := TStrMacroConst.CreateEx(vName, FBuf.GetStrValue)
        else
          vObj := TIntMacroConst.CreateEx(vName, GetIntValue);
        FConsts.Insert(vIndex, vObj);

      end else
        Error(errExpectEqualSign);

    end else
      Error(errIdentifierExpected);
  end;


  function TMacroParser.FindMacroConst(AName :PTChar; ALen :Integer = -1) :TMacroConst;
  var
    vIndex :Integer;
  begin
    Result := nil;
    if FConsts.FindKey(AName, ALen, [foBinary], vIndex) then
      Result := FConsts[vIndex];
  end;


  procedure TMacroParser.ParseInclude(var APtr :PTChar);
  var
    I, vLen :Integer;
    vText :TString;
    vParam :PTChar;
    vLex :TLexType;
    vFileName :TString;
  begin
    vLex := GetLex(APtr, vParam, vLen);
    if vLex = lexString then begin

      vFileName := StrExpandEnvironment(FBuf.GetStrValue);
      vFileName := ExpandFileName(CombineFileName(ExtractFilePath(FFileName), vFileName));

      if StrEqual(vFileName, FFileName) then
        begin Warning(errRecursiveInclude); Exit; end;

      for I := 0 to FStack.Count - 1 do
        if StrEqual(vFileName, PStackRec(FStack.PItems[I])^.SName) then
          begin Warning(errRecursiveInclude); Exit; end;

      if not WinFileExists(vFileName) then
        begin Warning(errFileNotFound); Exit; end;

      vText := StrFromFile(vFileName);

      PushStack(vText, APtr);
      FFileName := vFileName;

    end else
      Error(errExpectValue);
  end;


  procedure TMacroParser.PushStack(var AText :TString; var APtr :PTChar);
  begin
    with PStackRec(FStack.NewItem(FStack.Count))^ do begin
      pointer(SName) := pointer(FFileName);
      pointer(FFileName) := nil;
      Pointer(SText) := Pointer(FText);
      Pointer(FText) := nil;
      SPtr  := APtr;
      SRow  := FRow;
      SBeg  := FBeg;
      SCur  := FCur;
    end;

    Pointer(FText) := Pointer(AText);
    Pointer(AText) := nil;
    APtr := PTChar(FText);
    FRow := 0;
    FBeg := APtr;
    FCur := APtr;
  end;


  procedure TMacroParser.PopStack(var APtr :PTChar);
  begin
    with PStackRec(FStack.PItems[FStack.Count - 1])^ do begin
      pointer(FFileName) := pointer(SName);
      pointer(SName) := nil;
      Pointer(FText) := Pointer(SText);
      Pointer(SText) := nil;
      APtr  := SPtr;
      FRow  := SRow;
      FBeg  := SBeg;
      FCur  := SCur;
    end;
    FStack.Delete(FStack.Count - 1);
  end;


  procedure TMacroParser.ParseMacro(var APtr :PTChar);
  var
    vLex :TLexType;
    vLen, vLen1, vKey :Integer;
    vParam, vParam1 :PTChar;
    vWasBody :Boolean;
  begin
    NewMacro;
    vWasBody := False;
    while APtr^ <> #0 do begin
      vLex := GetLex(APtr, vParam, vLen);
      if vLex = lexWord then begin

        vKey := Keywords.GetKeyword(vParam, vLen);
        if vKey = -1 then
          Warning(wrnUnknownParam);

        vLex := GetLex(APtr, vParam1, vLen1);
        if (vLex = lexSymbol) and (vParam1^ = '=') then begin

          vLex := GetLex(APtr, vParam1, vLen1);
          if (vLex <> lexString) and (vLex <> lexNumber) then
            Error(errExpectValue);

          SetMacroParam(vKey, vLex);

          FCur := APtr;

        end else
          Error(errExpectEqualSign);

      end else
      if (vLex = lexSymbol) and MatchStr(vParam, '{{') then begin

        Inc(APtr);
        ParseMacroSequence(APtr);

        FMacro.Text := FSeq.GetStrValue;
        vWasBody := True;

        if FCheckBody then
          CheckMacroSequence(PTChar(FMacro.Text), True);

        Break;

      end else
        Error(errExpectMacroBody);
    end;

    if not vWasBody then
      Error(errExpectMacroBody);

    AddMacro;
  end;


  procedure TMacroParser.ParseMacroSequence(var APtr :PTChar);
  var
    vRow, vLen, vKey, vIncl :Integer;
    vPos :PTChar;
    vLex :TLexType;
    vParam :PTChar;
    vConst :TMacroConst;
  begin
    vIncl := 0;
    FSeq.Clear;
    SkipSpacesAndComments(APtr);
    FSeqRow := FRow;
    FSeqCol := APtr - FBeg;
    while (APtr^ <> #0) and not MatchStr(APtr, '}}') do begin
      if (APtr^ = charCR) or (APtr^ = charLF) then begin
        if (FSeq.Len > 0) and (FSeq.Buf[FSeq.Len - 1] <> #13) then
          FSeq.Add(#13, 1)
        else
          FSeq.Add(' '#13, 2);
        SkipCRLF(APtr);
      end else
      if MatchStr(APtr, cLineComment1) or MatchStr(APtr, cLineComment2) then
        { ������������ ����������� }
        SkipLineComment(APtr)
      else
      if MatchStr(APtr, cInLineCommentBeg) then begin
        { ������������� ����������� }
        vRow := FRow;
        vPos := APtr;

        SkipMultilineComment(APtr);

        if FRow > vRow then begin
          while vRow < FRow do begin
            FSeq.Add(' '#13, 2);
            Inc(vRow);
          end;
          vPos := FBeg;
        end;

        if APtr > vPos then
          FSeq.AddChars(' ', APtr - vPos)

      end else
      if APtr^ = '"' then begin
        { ��������� ��������� ��������� }
        vPos := APtr;
        Inc(APtr);
        while (APtr^ <> #0) and (APtr^ <> charCR) and (APtr^ <> charLF) and (APtr^ <> '"') do begin
          if APtr^ = '\' then
            Inc(APtr, 2)
          else
            Inc(APtr);
        end;
        if APtr^ <> '"' then
          Error(errUnclosedString);
        Inc(APtr);
        FSeq.Add(vPos, APtr - vPos);
      end else
      if MatchStr(APtr, '@"') then begin
        { ��������� ��������� ��������� - verbatim string }
        vPos := APtr;
        Inc(APtr, 2);
        while (APtr^ <> #0) and (APtr^ <> charCR) and (APtr^ <> charLF) and ((APtr^ <> '"') or ((APtr + 1)^ = '"')) do begin
          if APtr^ = '"' then
            Inc(APtr, 2)
          else
            Inc(APtr);
        end;
        if APtr^ <> '"' then
          Error(errUnclosedString);
        Inc(APtr);
        FSeq.Add(vPos, APtr - vPos);
      end else
      if APtr^ = '#' then begin
        { ������������ }
        Inc(APtr);
//      vPos := APtr;

        vLex := GetLex(APtr, vParam, vLen);
        if vLex = lexEOF then
          Error(errUnexpectedEOF);

        if vLex = lexWord then begin
          { ��������� �������������  }
          vKey := KeyPrepr.GetKeyword(vParam, vLen);
          if vKey = kwpInclude then begin
            ParseInclude(APtr);
            Inc(vIncl);
          end else
          if vKey = kwpAKey then begin
            FSeq.Add('%_AK_', 5);
            Include(FMacro.Options, moDefineAKey);
          end else
//        if vKey = kwpAKeyC then begin
//          FSeq.Add('%_AKeyC', 7);
//          Include(FMacro.Options, moDefineAKey);
//        end else
            Warning(errUnknownKeyword);
        end else
        if (vLex = lexSymbol) and (vParam^ = '%') then begin
          { ��������� ������������� }
          vLex := GetLex(APtr, vParam, vLen);
          if vLex = lexWord then begin
            vConst := FindMacroConst(vParam, vLen);
            if vConst = nil then
              Warning(errUnknownConst);

            if vConst <> nil then begin
              if vConst is TIntMacroConst then
                FSeq.AddInt(TIntMacroConst(vConst).Num)
              else begin
                FSeq.Add('"', 1);
                FSeq.AddStr(TStrMacroConst(vConst).Str);
                FSeq.Add('"', 1);
              end;
            end;
          end else
            Warning(errIdentifierExpected);
        end;

      end else
      begin
        FSeq.Add(APtr, 1);
        Inc(APtr);
      end;

      if (APtr^ = #0) and (vIncl > 0) then begin
        while (APtr^ = #0) and (vIncl > 0) do begin
          PopStack(APtr);
          FCur := APtr;
          Dec(vIncl);
        end;
      end;

    end;
    if APtr^ = #0 then
      Error(errUnexpectedEOF);
    Inc(APtr, 2);

    while (FSeq.Len > 0) and ChrInSet(FSeq.Buf[FSeq.Len - 1], [charCR, ' ']) do
      Dec(FSeq.FLen);
  end;


  procedure TMacroParser.ShowSequenceError;
  begin
    CheckMacroSequence(PTChar(FMacro.Text), False);
  end;


  procedure TMacroParser.CheckMacroSequence(const AText :TString; ASilence :Boolean);
  var
    vPos :TCoord;
  begin
    if not FarCheckMacro(AText, ASilence, @vPos) and ASilence then
      Error(errBadMacroSequence, FSeqRow + vPos.Y, vPos.X + IntIf(vPos.Y = 0, FSeqCol, 0));
  end;


  function TMacroParser.GetLex(var APtr :PTChar; var AParam :PTChar; var ALen :Integer) :TLexType;
  var
    vCh :TChar;
  begin
    SkipSpacesAndComments(APtr);
    FCur := APtr;

    while (APtr^ = #0) and (FStack.Count > 0) do begin
      PopStack(APtr);
      SkipSpacesAndComments(APtr);
      FCur := APtr;
    end;

    if APtr^ = #0 then begin
      Result := lexEOF
    end else
    if (APtr^ = '"') or (APtr^ = '''') then begin
      FBuf.Clear;

      vCh := APtr^;
      Inc(APtr);

      AParam := APtr;
      while (APtr^ <> #0) and (APtr^ <> charCR) and (APtr^ <> charLF) and ((APtr^ <> vCh) or ((APtr + 1)^ = vCh)) do begin
        FBuf.Add(APtr, 1);
        if APtr^ = vCh then
          Inc(APtr, 2)
        else
          Inc(APtr)
      end;

      if APtr^ <> vCh then
        Error(errUnclosedString);

      ALen := APtr - AParam;
      Inc(APtr);

      Result := lexString
    end else
    if ((APtr^ >= '0') and (APtr^ <= '9')) or (APtr^ = '-') then begin

      FBuf.Clear;

      if MatchStr(APtr, '0x') then begin
        FBuf.Add('$', 1);
        Inc(APtr, 2);
        AParam := APtr;
        while (APtr^ <> #0) and ChrInSet(APtr^, ['0'..'9', 'a'..'f', 'A'..'F']) do
          Inc(APtr);
      end else
      begin
        AParam := APtr;
        if APtr^ = '-' then
          Inc(APtr);
        while (APtr^ >= '0') and (APtr^ <= '9') do
          Inc(APtr);
      end;

      if CharIsWordChar(APtr^) then
        Error(errBadNumber);

      ALen := APtr - AParam;
      FBuf.Add(AParam, ALen);

      Result := lexNumber
    end else
    if CharIsWordChar(APtr^) or (APtr^ = '$') then begin

      AParam := APtr;
      Inc(APtr);
      while (APtr^ <> #0) and CharIsWordChar(APtr^) do
        Inc(APtr);
      ALen := APtr - AParam;

      Result := lexWord;
    end else
    begin
      AParam := APtr;
      ALen := 1;
      Inc(APtr);
      Result := lexSymbol;
    end;
  end;


  procedure TMacroParser.SkipSpacesAndComments(var APtr :PTChar);
  begin
    while APtr^ <> #0 do begin
      if (APtr^ = ' ') or (APtr^ = charTab) then
        Inc(APtr)
      else
      if (APtr^ = charCR) or (APtr^ = charLF) then
        SkipCRLF(APtr)
      else
      if MatchStr(APtr, cLineComment1) or MatchStr(APtr, cLineComment2) then
        SkipLineComment(APtr)
      else
      if MatchStr(APtr, cInLineCommentBeg) then
        SkipMultilineComment(APtr)
      else
        Break;
    end;
  end;


  procedure TMacroParser.SkipLineComment(var APtr :PTChar);
  begin
    while (APtr^ <> #0) and not ((APtr^ = charCR) or (APtr^ = charLF)) do
      Inc(APtr);
  end;


  procedure TMacroParser.SkipMultilineComment(var APtr :PTChar);
  begin
    while (APtr^ <> #0) and not MatchStr(APtr, cInLineCommentEnd) do begin
      if (APtr^ = charCR) or (APtr^ = charLF) then
        SkipCRLF(APtr)
      else
        Inc(APtr);
    end;
    if APtr^ <> #0 then
      Inc(APtr, length(cInLineCommentEnd));
  end;


  procedure TMacroParser.SkipCRLF(var APtr :PTChar);
  begin
    if APtr^ = charCR then
      Inc(APtr);
    if APtr^ = charLF then
      Inc(APtr);
    Inc(FRow);
    FBeg := APtr;
    FCur := FBeg;
  end;


  procedure TMacroParser.Warning1(ACode :TParseError; APtr :PTChar);
  begin
    Warning(ACode, FRow, (FCur - FBeg) + (APtr - FBuf.Buf + 1))
  end;


  function KeyNameParse(AName :PTChar; var AKey :Integer; var AMod :TKeyModifier) :Boolean;
  var
    vModi :Integer;
    vPtr, vName :PTChar;
    vTmp :array[0..255] of TChar;
  begin
    Result := False;

    vPtr := StrScan(AName, ':');
    if vPtr = nil then
      vName := AName
    else begin
      vName := @vTmp[0];
      StrLCopy(vName, AName, IntMin(vPtr - AName, High(vTmp)));
    end;

    AKey := NameToFarKey(vName);
    if AKey = -1 then
      Exit;

    AMod := kmPress;
    if vPtr <> nil then begin
      Inc(vPtr);

      vModi := KeyMods.GetKeyword(vPtr, StrLen(vPtr));
      if vModi = -1 then
        Exit;

      AMod := TKeyModifier(vModi);
    end;

    Result := True;
  end;


  procedure TMacroParser.ParseBindStr(APtr :PTChar; var ARes :TKeyArray);
  var
    vKey :Integer;
    vMod :TKeyModifier;
    vBuf :array[0..255] of TChar;
  begin
    while CanExtractNext(APtr, @vBuf[0], high(vBuf), [' ', charTab]) do begin

      if not KeyNameParse(@vBuf[0], vKey, vMod) then
        begin Warning1(errBadHotkey, APtr); Exit; end;

      SetLength(ARes, Length(ARes) + 1);
      ARes[Length(ARes) - 1].Key := vKey;
      ARes[Length(ARes) - 1].KMod := vMod;
    end;
  end;


  procedure TMacroParser.ParseAreaStr(APtr :PTChar; var ARes :TMacroAreas);
  var
    vArea :Integer;
    vBuf :array[0..255] of TChar;
    vCh :TChar;
    vPtr :PTChar;
    vGUID :TGUID;
    vConst :TMacroConst;
    vArr :PStrArray;
  begin
    vArr := nil;
    while CanExtractNext(APtr, @vBuf[0], high(vBuf), cWordDelims + ['.']) do begin
      if (vBuf[0] = '*') and (vBuf[1] = #0) then
        ARes := [Low(TMacroArea)..High(TMacroArea)]
      else begin
        vArea := KeyAreas.GetKeyword(@vBuf[0], StrLen(@vBuf[0]));
        if vArea = -1 then
          begin Warning1(errBadMacroarea, APtr); Exit; end;

        if APtr^ = '.' then begin
          Inc(APtr);
          if ChrInSet(APtr^, [#0, ' ', charTab]) then
            begin Warning1(errBadMacroarea, APtr); Exit; end;

          if (APtr^ = '"') or (APtr^ = '''') then begin
            FSeq.Clear;
            vCh := APtr^;
            Inc(APtr);
            while (APtr^ <> #0) and ((APtr^ <> vCh) or ((APtr + 1)^ = vCh)) do begin
              FSeq.Add(APtr, 1);
              if APtr^ = vCh then
                Inc(APtr, 2)
              else
                Inc(APtr)
            end;
            if APtr^ <> vCh then
              begin Warning1(errUnclosedString, APtr); Exit; end;
            if (not vArea in [MACROAREA_DIALOG, MACROAREA_EDITOR, MACROAREA_VIEWER]) then
              begin Warning1(errBadMacroarea, APtr); Exit; end;
            Inc(APtr);
            vPtr := FSeq.Buf;
          end else
          begin
            CanExtractNext(APtr, @vBuf[0], high(vBuf));
            if vArea <> MACROAREA_DIALOG then
              begin Warning1(errBadMacroarea, APtr); Exit; end;

            vPtr := @vBuf[0];
            if (vPtr^ <> #0) and CharIsWordChar(vPtr^) then begin
              vConst := FindMacroConst(vPtr);
              if vConst = nil then
                begin Warning1(errUnknownConst, APtr); Exit; end;
              if not (vConst is TStrMacroConst) then
                begin Warning1(errBadGUID, APtr); Exit; end;
              vPtr := PTChar(TStrMacroConst(vConst).Str);
            end;
          end;

          if (vPtr^ = '{') then begin
            { �������� �� GUID }
            FillZero(vGUID, SizeOf(TGUID));
            if CLSIDFRomString(vPtr, vGUID) <> 0 then
              begin Warning1(errBadGUID, APtr); Exit; end;

            SetLength(FMacro.Dlgs, Length(FMacro.Dlgs) + 1);
            FMacro.Dlgs[Length(FMacro.Dlgs) - 1] := vGUID;
          end else
          begin
            { �������� �� Caption }
            if vArea = MACROAREA_DIALOG then
              vArr := @FMacro.Dlgs1
            else
            if vArea = MACROAREA_EDITOR then
              vArr := @FMacro.Edts
            else
            if vARea = MACROAREA_VIEWER then
              vArr := @FMacro.Views
            else
              begin Warning1(errBadMacroarea, APtr); Exit; end;

            SetLength(vArr^, Length(vArr^) + 1);
            vArr^[Length(vArr^) - 1] := vPtr;
          end;

        end else
          ARes := ARes + [TMacroArea(vArea)];
      end;
    end;
  end;


  procedure TMacroParser.ParseCondStr(APtr :PTChar; var ARes :TMacroConditions);
  var
    vCond :Integer;
    vBuf :array[0..255] of TChar;
  begin
    while CanExtractNextWord(APtr, @vBuf[0], high(vBuf)) do begin
      vCond := KeyConds.GetKeyword(@vBuf[0], StrLen(@vBuf[0]));
      if vCond = -1 then
        begin Warning1(errBadCondition, APtr); Exit; end;
      if APtr^ <> ':' then
        begin Warning1(errExpectColon, APtr); Exit; end;
      Inc(APtr);
      if not (((APtr^ = '0') or (APtr^ = '1')) and (((APtr + 1)^ = #0) or ChrInSet((APtr + 1)^, cWordDelims))) then
        begin Warning1(errExpect0or1, APtr); Exit; end;
      SetMacroCondition(ARes, TMacroCondition(Byte(vCond)), APtr^ = '1');
      Inc(APtr);
    end;
  end;


  procedure TMacroParser.ParseEventStr(APtr :PTChar; var ARes :TMacroEvents);
  var
    vEvent :Integer;
    vBuf :array[0..255] of TChar;
  begin
    while CanExtractNextWord(APtr, @vBuf[0], high(vBuf)) do begin
      vEvent := KeyEvnts.GetKeyword(@vBuf[0], StrLen(@vBuf[0]));
      if vEvent = -1 then
        begin Warning1(errBadEvent, APtr); Exit; end;
      ARes := ARes + [TMacroEvent(vEvent)]
    end;
  end;


  function TMacroParser.GetIntValue :Integer;
  begin
    if not FBuf.GetIntValue(Result) then
      Error(errBadNumber);
  end;


  procedure TMacroParser.NewMacro;
  begin
    FMacro.Name     := '';
    FMacro.Descr    := '';
    FMacro.Bind     := nil;
    FMacro.Area     := [];
    FMacro.Dlgs     := nil;
    FMacro.Dlgs1    := nil;
    FMacro.Edts     := nil;
    FMacro.Views    := nil;
    FMacro.Cond     := [];
    FMacro.Events   := [];
    FMacro.Where    := '';
    FMacro.Priority := 0;
    FMacro.Options  := [moDisableOutput, moSendToPlugins, moEatOnRun];
    FMacro.Text     := '';
    FMacro.Row      := FRow;
    FMacro.Col      := FBeg - FCur;
    FMacro.Index    := FCount;
  end;


  procedure TMacroParser.SetMacroParam(AParam :Integer; ALex :TLexType);
  begin
    if (AParam in [kwName, kwDescr, kwBind, kwArea, kwCond, kwEvent, kwWhere]) and (Alex <> lexString) then
      begin Warning(errExceptString); exit; end;

    case AParam of
      kwName     : FMacro.Name  := FBuf.GetStrValue;
      kwDescr    : FMacro.Descr := FBuf.GetStrValue;
      kwBind     : ParseBindStr(FBuf.Buf, FMacro.Bind);
      kwArea     : ParseAreaStr(FBuf.Buf, FMacro.Area);
      kwCond     : ParseCondStr(FBuf.Buf, FMacro.Cond);
      kwEvent    : ParseEventStr(FBuf.Buf, FMacro.Events);
      kwWhere    : FMacro.Where := FBuf.GetStrValue;
      kwPriority : FMacro.Priority := GetIntValue;

      kwSilence  : SetMacroOption(FMacro.Options, moDisableOutput, GetIntValue <> 0);
      kwSendPlug : SetMacroOption(FMacro.Options, moSendToPlugins, GetIntValue <> 0);
      kwRunOnRel : SetMacroOption(FMacro.Options, moRunOnRelease, GetIntValue <> 0);
      kwEatOnRun : SetMacroOption(FMacro.Options, moEatOnRun, GetIntValue <> 0);
    end;
  end;


  procedure TMacroParser.AddMacro;
  var
    I :Integer;
  begin
    if moRunOnRelease in FMacro.Options then
      { ������������ � ����� ������ - ��� ������������� }
      for I := 0 to length(FMacro.Bind) - 1 do
        with FMacro.Bind[I] do begin
          if KMod = kmPress then
            KMod := kmRelease;
        end;

    if Assigned(FOnAdd) then
      FOnAdd(Self, FMacro);
    Inc(FCount);
  end;


  procedure TMacroParser.ShowError(E :EParseError);
  var
    vCode, vRow, vCol :Integer;
    vMessage :TString;
  begin
    if Assigned(FOnError) then begin
      vCode := E.HelpContext;
      if ParserResBase <> 0 then
        vMessage := FarCtrl.GetMsg(ParserResBase + vCode);
      vRow := E.FRow;
      vCol := E.FCol;
      if (vRow = 0) and (vCol = 0)  then begin
        vRow := FRow;
        vCol := FCur - FBeg;
      end;
      FOnError(Self, vCode, vMessage, FFileName, vRow, vCol);
    end;
  end;


initialization
finalization
  FreeObj(Keywords);
  FreeObj(KeyAreas);
  FreeObj(KeyConds);
  FreeObj(KeyEvnts);
  FreeObj(KeyMods);
  FreeObj(KeyPrepr);
end.
