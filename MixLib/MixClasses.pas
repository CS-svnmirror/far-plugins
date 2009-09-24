{$I Defines.inc}

unit MixClasses;

interface

  uses
    Windows,
    MixTypes,
    MixConsts,
    MixUtils,
    MixStrings;

  type
    TNotifyEvent = procedure(Sender: TObject) of object;

  type
    TBasisClass = class of TBasis;

    PBasis = ^TBasis;
    TBasis = class(TObject)
    public
      constructor Create; virtual;
//    constructor CreateCopy(Source :TBasis);
     {$ifdef bUseStreams}
      constructor CreateStream(Stream :TStream);
     {$endif bUseStreams}
      destructor Destroy; override;

      class function NewInstance :TObject; override;
      procedure FreeInstance; override;

//    function Clone :TBasis;

     {$ifdef bUseStreams}
      procedure WriteToStream(Stream :TStream); virtual;
      procedure ReadFromStream(Stream :TStream); virtual;
     {$endif bUseStreams}

      function CompareObj(Another :TBasis; Context :TIntPtr) :Integer; virtual;
      function CompareKey(Key :Pointer; Context :TIntPtr) :Integer; virtual;

      function ValidInstanceEx(AClass :TBasisClass) :Boolean;

    protected
     {$ifdef bAsserts}
      { ��������� �� ����� �������, ��� �������� ValidInstance }
      FClass  :{$ifdef bDelphi}TBasisClass;{$else}Pointer;{$endif bDelphi}
     {$endif bAsserts}

      function GetValidInstance :Boolean;

    public
      property ValidInstance :Boolean read GetValidInstance;
    end;


  type
    TDuplicates = (
      dupIgnore,
      dupAccept,
      dupError
    );

    TFindOptions = set of (
      foCompareObj,
      foBinary,
      foSimilary,
      foExceptOnFail
    );

    TListOption  = (
      loItemFree,      { ��� Item'� ���� �������� ��������� ����������� }
      loItemSave       { ��� Item'� ���� �������� ��������� ItemToStream/ItemFromStream }
    );
    TListOptions = set of TListOption;

    PPointerList = ^TPointerList;
    TPointerList = array[0..MaxInt div SizeOf(Pointer) - 1] of Pointer;

    TExList = class(TBasis)
    public
      constructor Create; override;
      constructor CreateSize(AItemSize :Integer);
      destructor Destroy; override;

     {$ifdef bUseStreams}
      procedure WriteToStream(Stream :TStream); override;
      procedure ReadFromStream(Stream :TStream); override;
      procedure AppendFromStream(Stream :TStream); virtual;
        { ��� ������/������ Item'� ���������� ItemToStream/ItemFromStream }
        { ��� ������� �������� ������ - ����������� � ���������� ������ }
     {$endif bUseStreams}

      procedure Clear;

      function NewItem(AIndex :Integer) :Pointer;

      function Add(Item: Pointer) :Integer;
      procedure Insert(Index :Integer; Item: Pointer);

      function AddSorted(Item :Pointer; Context :TIntPtr; Duplicates :TDuplicates) :Integer;
        { ��������� ������� � ����������� }

      function AddData(const Item) :Integer;
      procedure InsertData(Index :Integer; const Item);

      procedure Delete(AIndex: Integer);
      procedure DeleteRange(AIndex, ACount :Integer);
      function Remove(Item: Pointer): Integer;
      function RemoveData(const Item) :Integer;

      procedure ReplaceRangeFrom(const ABuffer; AIndex, AOldCount, ANewCount :Integer);

      function Contain(Item :Pointer) :Boolean;
      function IndexOf(Item :Pointer) :Integer;
      function IndexOfData(const Item) :Integer;

      function First: Pointer;
      function Last: Pointer;

      function FindKey(Key :Pointer; Context :TIntPtr; Opt :TFindOptions; var Index :Integer) :Boolean; virtual;
        { �������������� ������� ������. ���������� ��������� � ���� }
      procedure SortList(Ascend :Boolean; Context :TIntPtr); {virtual;}
        { ������� ���������� ������ }

      { ��������� ������� �������� ������ ��� �������� ������ : FItemSize = 4 }

      procedure Exchange(Index1, Index2: Integer); virtual;
      procedure Move(CurIndex, NewIndex: Integer);

    protected
      FItemSize  : Integer;
      FItemLimit : Integer;
      FList      : PPointerList;
      FCount     : Integer;
      FCapacity  : Integer;
      FOptions   : TListOptions;

      procedure Grow; virtual;

      procedure ItemFree(PItem :Pointer); virtual;
//    procedure ItemAssign(PItem, PSource :Pointer); virtual;
      function  ItemCompare(PItem, PAnother :Pointer; Context :TIntPtr) :Integer; virtual;
      function  ItemCompareKey(PItem :Pointer; Key :Pointer; Context :TIntPtr) :Integer; virtual;
     {$ifdef bUseStreams}
      procedure ItemToStream(PItem :Pointer; Stream :TStream); virtual;
      procedure ItemFromStream(PItem :Pointer; Stream :TStream); virtual;
     {$endif bUseStreams}

    protected
      function  GetItems(Index :Integer) :Pointer;
      procedure PutItems(Index :Integer; Item: Pointer);
      function  GetPItems(Index :Integer) :Pointer; {virtual;}
      procedure SetCapacity(NewCapacity :Integer); virtual;
      function  GetCount :Integer;
      procedure SetCount(NewCount :Integer);

    public
      property Options :TListOptions read FOptions write FOptions;
      property ItemSize :Integer read FItemSize;
      property Count :Integer read FCount write SetCount;
      property Capacity :Integer read FCapacity write SetCapacity;
      property List :PPointerList read FList;

      { �������� Items �������� ������ ��� �������� ������ : FItemSize = 4 }
      property Items[I :Integer]: Pointer read GetItems write PutItems; default;

      property PItems[I :Integer]: Pointer read GetPItems;
    end; {TExList}


  type
    TObjList = class(TExList)
    public
      constructor Create; override;

//    procedure Assign(Source :TPersistent); override;
     {$ifdef bUseStreams}
      procedure ReadFromStream(Stream :TStream); override;
     {$endif bUseStreams}

      procedure FreeAll;
      procedure FreeAt(AIndex: Integer);

    protected
      procedure ItemFree(PItem :Pointer); override;
      function ItemCompare(PItem, PAnother :Pointer; Context :TIntPtr) :Integer; override;
      function ItemCompareKey(PItem :Pointer; Key :Pointer; Context :TIntPtr) :Integer; override;
     {$ifdef bUseStreams}
      procedure ItemToStream(PItem :Pointer; Stream :TStream); override;
      procedure ItemFromStream(PItem :Pointer; Stream :TStream); override;
     {$endif bUseStreams}
    end; {TObjList}


  type
    TIntList = class(TExList)
    public
      function Add(Item :TIntPtr) :Integer;

    protected
      function ItemCompare(PItem, PAnother :Pointer; Context :TIntPtr) :Integer; override;
      function ItemCompareKey(PItem :Pointer; Key :Pointer; Context :TIntPtr) :Integer; override;
     {$ifdef bUseStreams}
      procedure ItemToStream(PItem :Pointer; Stream :TStream); override;
      procedure ItemFromStream(PItem :Pointer; Stream :TStream); override;
     {$endif bUseStreams}

      function  GetIntItems(Index :Integer) :TIntPtr;
      procedure PutIntItems(Index :Integer; Value :TIntPtr);

    public
      property Items[I :Integer] :TIntPtr read GetIntItems write PutIntItems; default;
    end;


  type
    TStrList = class(TExList)
    public
      constructor Create; override;

      function Add(const AStr :TString) :Integer;
      function AddSorted(const AStr :TString; Context :TIntPtr; Duplicates :TDuplicates) :Integer;
      procedure Insert(Index :Integer; const AStr :TString);
      function IndexOf(const AStr :TString) :Integer;

    protected
      procedure ItemFree(PItem :Pointer); override;
      function ItemCompare(PItem, PAnother :Pointer; Context :TIntPtr) :Integer; override;
     {$ifdef bUseStreams}
      procedure ItemToStream(PItem :Pointer; Stream :TStream); override;
      procedure ItemFromStream(PItem :Pointer; Stream :TStream); override;
     {$endif bUseStreams}
      function GetStrItems(Index :Integer) :TString;
      procedure PutStrItems(Index :Integer; const Value :TString);

    public
      property Items[I :Integer] :TString read GetStrItems write PutStrItems; default;
//    property Strings[I :Integer] :TString read GetStrItems write PutStrItems;
    end;


  type
    TNamedObject = class(TBasis)
    public
      constructor CreateName(const AName :TString); virtual;

//    procedure Assign(Source :TPersistent); override;
     {$ifdef bUseStreams}
      procedure WriteToStream(Stream :TStream); override;
      procedure ReadFromStream(Stream :TStream); override;
     {$endif bUseStreams}

      function CompareObj(Another :TBasis; Context :TIntPtr) :Integer; override;
      function CompareKey(Key :Pointer; Context :TIntPtr) :Integer; override;

    protected
      FName :TString;

    public
      property Name :TString read FName write FName;
    end;


  type
    TDescrObject = class(TNamedObject)
    public
      constructor CreateEx(const AName, ADescr :TString);

//    procedure Assign(Source :TPersistent); override;
     {$ifdef bUseStreams}
      procedure WriteToStream(AStream :TStream); override;
      procedure ReadFromStream(AStream :TStream); override;
     {$endif bUseStreams}

    protected
      FDescr :TString;

    public
      property Descr :TString read FDescr write FDescr;
    end;


  type
    PStringItem = ^TStringItem;
    TStringItem = record
      FString :TString;
      FObject :TObject;
    end;

    TStringList = class(TObjList)
    public
      constructor Create; override;

      function Add(const S :TString) :Integer;
      procedure Insert(AIndex :Integer; const S :TString);
      function AddObject(const S :TString; AObject :Pointer) :Integer;
      procedure InsertObject(AIndex: Integer; const S :TString; AObject :Pointer);

      function IndexOf(const S :TString): Integer;

      procedure SaveToFile(const AFileName :TString; AMode :TStrFileFormat = sffAuto);
      procedure LoadFromFile(const AFileName :TString; AMode :TStrFileFormat = sffAuto);

    protected
      procedure ItemFree(Item :Pointer); override;
      function ItemCompareKey(PItem :Pointer; Key :Pointer; Context :TIntPtr) :Integer; override;

    private
      FSorted     :Boolean;
      FDuplicates :TDuplicates;

      function GetTextStr :TString;
      procedure SetTextStr(const Value :TString);

      function GetStrItems(Index :Integer) :TString;
      procedure PutStrItems(Index :Integer; const Value :TString);
      function GetObject(Index :Integer) :TObject;
      procedure PutObject(Index :Integer; Value :TObject);

    public
      property Sorted :Boolean read FSorted write FSorted {SetSorted};
      property Duplicates :TDuplicates read FDuplicates write FDuplicates;

      property Strings[I :Integer] :TString read GetStrItems write PutStrItems; default;
      property Objects[I :Integer] :TObject read GetObject write PutObject;
      property Text :TString read GetTextStr write SetTextStr;
    end;


  type
    TObjStrings = class(TStringList)
    protected
      procedure ItemFree(Item :Pointer); override;
    end;



  type
    TBits = class
    public
      destructor Destroy; override;
      function OpenBit: Integer;

    private
      FSize: Integer;
      FBits: Pointer;

      procedure Error;
      procedure SetSize(Value: Integer);
      procedure SetBit(Index: Integer; Value: Boolean);
      function GetBit(Index: Integer): Boolean;

    public
      property BitsPtr :Pointer read FBits;
      property Bits[I :Integer]: Boolean read GetBit write SetBit; default;
      property Size :Integer read FSize write SetSize;
    end;


  type
    TThreadPriority = (tpIdle, tpLowest, tpLower, tpNormal, tpHigher, tpHighest, tpTimeCritical);

    TThread = class
    public
      constructor Create(CreateSuspended: Boolean);
      destructor Destroy; override;
      procedure Resume;
      procedure Suspend;
      procedure Terminate;
      function WaitFor: LongWord;
    protected
      procedure DoTerminate; virtual;
      procedure Execute; virtual; abstract;
//    procedure Synchronize(Method: TThreadMethod);
    private
      FHandle: THandle;
      FThreadID: THandle;
      FTerminated: Boolean;
      FSuspended: Boolean;
      FFreeOnTerminate: Boolean;
      FFinished: Boolean;
      FReturnValue: Integer;
//    FOnTerminate: TNotifyEvent;
//    FMethod: TThreadMethod;
//    FSynchronizeException: TObject;
//    procedure CallOnTerminate;
      function GetPriority: TThreadPriority;
      procedure SetPriority(Value: TThreadPriority);
      procedure SetSuspended(Value: Boolean);
    public
      property Handle: THandle read FHandle;
      property ThreadID: THandle read FThreadID;
      property Priority: TThreadPriority read GetPriority write SetPriority;
      property Suspended: Boolean read FSuspended write SetSuspended;
      property FreeOnTerminate: Boolean read FFreeOnTerminate write FFreeOnTerminate;
      property Terminated: Boolean read FTerminated;
      property ReturnValue: Integer read FReturnValue write FReturnValue;
//    property OnTerminate: TNotifyEvent read FOnTerminate write FOnTerminate;
    end;


{******************************************************************************}
{******************************} implementation {******************************}
{******************************************************************************}

  uses
    MixDebug;


 {-----------------------------------------------------------------------------}
 { TBasis                                                                      }
 {-----------------------------------------------------------------------------}

  constructor TBasis.Create; {virtual;}
  begin
//  inherited Create;
  end;

//constructor TBasis.CreateCopy(Source :TPersistent);
//begin
//  Create;
//  Assign(Source);
//end;

 {$ifdef bUseStreams}
  constructor TBasis.CreateStream(Stream :TStream);
  begin
    Create;
    ReadFromStream(Stream);
  end;
 {$endif bUseStreams}


  destructor TBasis.Destroy; {override;}
  begin
   {$ifdef bAsserts}
    try
      Assert(ValidInstance);
    except
      Nop;
    end;
   {$endif bAsserts}
//  inherited Destroy;
  end;


  class function TBasis.NewInstance :TObject; {override;}
  begin
   {$ifdef bDebug}
    SetReturnAddrNewInstance;
   {$endif bDebug}
    Result := inherited NewInstance;
   {$ifdef bAsserts}
    TBasis(Result).FClass := Self;
   {$endif bAsserts}
  end;


  procedure TBasis.FreeInstance; {override;}
  begin
   {$ifdef bAsserts}
    FClass := nil;
   {$endif bAsserts}
    inherited FreeInstance;
  end;


  function TBasis.GetValidInstance :Boolean;
  begin
   {$ifdef bAsserts}
    Result :=
      (Self <> nil) and (TUnsPtr(Self) and $3 = 0) and
      (FClass <> nil) and (TUnsPtr(FClass) and $3 = 0) and
      (FClass = ClassType) and (TObject(Self) is TBasis);
   {$else}
    Result := True;
   {$endif bAsserts}
  end;

  function TBasis.ValidInstanceEx(AClass :TBasisClass) :Boolean;
  begin
   {$ifdef bAsserts}
    Result :=
      (Self <> nil) and (TUnsPtr(Self) and $3 = 0) and
      (FClass <> nil) and (TUnsPtr(FClass) and $3 = 0) and
      (FClass = ClassType) and (TObject(Self) is AClass);
   {$else}
    Result := True;
   {$endif bAsserts}
  end;


//function TBasis.Clone :TBasis;
//begin
//  Result := TBasisClass(ClassType).CreateCopy(Self);
//end;


  function TBasis.CompareObj(Another :TBasis; Context :TIntPtr) :Integer; {virtual;}
//var
//  Str :TString;
  begin
    Wrong;
    Result := 0;
//  if Another <> nil then
//    Str := Another.ClassName
//  else
//    Str := 'nil';
//  AppErrorFmt(errComCompareError, [ClassName, Str]);
  end;

  function TBasis.CompareKey(Key :Pointer; Context :TIntPtr) :Integer; {virtual;}
  begin
    Wrong;
    Result := 0;
//  InternalErrorResFmt(errComCompareKeyError, [ClassName]);
  end;


 {$ifdef bUseStreams}
  procedure TBasis.WriteToStream(Stream :TStream); {virtual;}
  begin
    {Nothing}
  end;

  procedure TBasis.ReadFromStream(Stream :TStream); {virtual;}
  begin
    {Nothing}
  end;
 {$endif bUseStreams}


 {-----------------------------------------------------------------------------}
 { TExList                                                                     }
 {-----------------------------------------------------------------------------}

  {!!!}
  function MemCompare (a1, a2 :Pointer; len :Integer) :Integer;
  begin
    Result := 0;
    while (Result < len) and ((PAnsiChar(a1)+Result)^ = (PAnsiChar(a2)+Result)^) DO
      inc(Result);
  end;


  constructor TExList.Create; {override;}
  begin
    inherited Create;
    FItemSize  := SizeOf(Pointer);
    FItemLimit := MaxInt div FItemSize;
  end;


  constructor TExList.CreateSize(AItemSize :Integer);
  begin
    Create;
    FItemSize  := AItemSize;
    FItemLimit := MaxInt div FItemSize;
  end;


  destructor TExList.Destroy; {override;}
  begin
    Clear;
    inherited Destroy;
  end;


  procedure TExList.Clear;
  begin
    if FCount > 0 then
      DeleteRange(0, FCount);
    SetCapacity(0);
  end;


  function TExList.GetItems(Index :Integer) :Pointer;
  begin
    Assert(ValidInstance);
    if (Index >= 0) and (Index < FCount) then
      Result := FList[Index]
    else begin
      AppErrorResFmt(@SListIndexError, [Index]);
      Result := nil;
    end;
  end;

  procedure TExList.PutItems(Index :Integer; Item :Pointer);
  begin
    Assert(ValidInstance);
    if (Index >= 0) and (Index < FCount) then
      FList[Index] := Item
    else
      AppErrorResFmt(@SListIndexError, [Index]);
  end;


  function TExList.GetPItems(Index :Integer) :Pointer; {virtual;}
  begin
    Assert(ValidInstance);
    if (Index < 0) or (Index >= FCount) then
      AppErrorResFmt(@SListIndexError, [Index]);
    if FItemSize = SizeOf(Pointer) then
      Result := @FList[Index]
    else
      Result := Pointer1(FList) + Index * FItemSize;
  end;


  function TExList.First :Pointer;
  begin
    Result := GetItems(0);
  end;

  function TExList.Last :Pointer;
  begin
    Result := GetItems(FCount - 1);
  end;


  function TExList.Add(Item :Pointer) :Integer;
  begin
    Assert(FItemSize = SizeOf(Pointer));
    Result := FCount;
    Pointer(NewItem(FCount)^) := Item;
  end;

  procedure TExList.Insert(Index :Integer; Item :Pointer);
  begin
    Assert(FItemSize = SizeOf(Pointer));
    Pointer(NewItem(Index)^) := Item;
  end;


  function TExList.AddSorted(Item :Pointer; Context :TIntPtr; Duplicates :TDuplicates) :Integer;
  begin
    if FindKey(Item, Context, [foCompareObj, foBinary], Result) then begin
      case Duplicates of
        dupIgnore : Exit;
        dupError  : AppErrorRes(@SDuplicateError);
      end;
    end;
    Insert(Result, Item);
  end;


  function TExList.AddData(const Item) :Integer;
  begin
    Result := FCount;
    InsertData(FCount, Item);
  end;


  procedure TExList.InsertData(Index :Integer; const Item);
  begin
    if FItemSize = SizeOf(Pointer) then
      Pointer(NewItem(Index)^) := Pointer(Item)
    else
      System.Move(Item, NewItem(Index)^, FItemSize);
  end;


  function TExList.NewItem(AIndex :Integer) :Pointer;
  begin
    if (AIndex < 0) or (AIndex > FCount) then
      AppErrorResFmt(@SListIndexError, [AIndex]);
    if FCount = FCapacity then
      Grow;
    if FItemSize = SizeOf(Pointer) then begin
      Result := Pointer(@FList[AIndex]);
      if AIndex < FCount then
        System.Move(Result^, (Pointer1(Result) + SizeOf(Pointer))^, (FCount - AIndex) * SizeOf(Pointer));
    end else
    begin
      Result := Pointer1(FList) + AIndex * FItemSize;
      if AIndex < FCount then
        System.Move(Result^, (Pointer1(Result) + FItemSize)^, (FCount - AIndex) * FItemSize);
    end;
    Inc(FCount);
  end;


  procedure TExList.Delete(AIndex: Integer);
  begin
    DeleteRange(AIndex, 1)
  end;


  procedure TExList.DeleteRange(AIndex, ACount :Integer);
  var
    I :Integer;
    P :Pointer1;
  begin
    Assert(ValidInstance);
    if (AIndex < 0) or (AIndex + ACount > FCount) then
      AppErrorResFmt(@SListIndexError, [AIndex]);

    if loItemFree in fOptions then begin
      P := Pointer1(FList) + AIndex * FItemSize;
      for I := 0 to ACount - 1 do begin
        ItemFree(P);
        Inc(P, FItemSize);
      end;
    end;

    if AIndex + ACount < FCount then begin
      P := Pointer1(FList) + AIndex * FItemSize;
      System.Move((P + ACount * FItemSize)^, P^, (FCount - AIndex - ACount) * FItemSize);
    end;
    Dec(FCount, ACount);
  end;


  function TExList.Remove(Item :Pointer) :Integer;
  begin
    Result := RemoveData(Item);
  end;

  function TExList.RemoveData(const Item) :Integer;
  begin
    Result := IndexOfData(Item);
    if Result <> -1 then
      DeleteRange(Result, 1);
  end;


  procedure TExList.ReplaceRangeFrom(const ABuffer; AIndex, AOldCount, ANewCount :Integer);
  var
    vNewCount :Integer;
    P :Pointer1;
  begin
    if (AIndex < 0) or (AIndex + AOldCount > FCount) then
      AppErrorResFmt(@SListIndexError, [AIndex]);
    if AOldCount < ANewCount then begin
      vNewCount := FCount + (ANewCount - AOldCount);
      if vNewCount > FCapacity then
        SetCapacity(vNewCount); {!!! Delta....}
      if AIndex + AOldCount < FCount then begin
        P := Pointer1(FList) + (AIndex + AOldCount) * FItemSize;
        System.Move(P^, (P + (ANewCount - AOldCount) * FItemSize)^, (FCount - AIndex - AOldCount) * FItemSize);
      end;
      FCount := vNewCount;
    end else
    if AOldCount > ANewCount then
      DeleteRange(AIndex + ANewCount, AOldCount - ANewCount);
    if ANewCount > 0 then
      System.Move(ABuffer, (Pointer1(FList) + AIndex * FItemSize)^, ANewCount * FItemSize);
  end;


  function TExList.Contain(Item :Pointer) :Boolean;
  begin
    Result := IndexOfData(Item) <> -1;
  end;

  function TExList.IndexOf(Item :Pointer) :Integer;
  begin
    Result := IndexOfData(Item);
  end;

  function TExList.IndexOfData(const Item) :Integer;
  var
    I :Integer;
    P :Pointer1;
    F :Boolean;
  begin
    P := Pointer1(FList);
    for I := 0 to FCount - 1 do begin
      if FItemSize = SizeOf(Pointer) then begin
        F := PPointer(P)^ = Pointer(Item)
      end else begin
        F := MemCompare(P, @Item, FItemSize) = FItemSize;
      end;
      if F then begin
        Result := I;
        Exit;
      end;
      inc(P, FItemSize);
    end;
    Result := -1;
  end;


  procedure TExList.Grow; {virtual;}
  var
    Delta: Integer;
  begin
    if FCapacity > 64 then
      Delta := FCapacity div 4
    else
    if FCapacity > 8 then
      Delta := 16
    else
      Delta := 4;
    SetCapacity(FCapacity + Delta);
  end;


  procedure TExList.SetCapacity(NewCapacity :Integer); {virtual;}
  begin
    if (NewCapacity < FCount) or (NewCapacity > FItemLimit) then
      AppErrorResFmt(@SListCapacityError, [NewCapacity]);
    if NewCapacity <> FCapacity then begin
      ReallocMem(FList, NewCapacity * FItemSize);
      FCapacity := NewCapacity;
    end;
  end;


  function  TExList.GetCount :Integer;
  begin
    Assert(ValidInstance);
    Result := FCount;
  end;


  procedure TExList.SetCount(NewCount :Integer);
  begin
    Assert(ValidInstance);
    if (NewCount < 0) or (NewCount > FItemLimit) then
      AppErrorResFmt(@SListCountError, [NewCount]);
    if NewCount > FCapacity then
      SetCapacity(NewCount);
    if NewCount > FCount then
      FillChar((Pointer1(FList) + FCount * FItemSize)^, (NewCount - FCount) * FItemSize, 0);
    FCount := NewCount;
  end;


 {---------------------------------------------}

 {$ifdef bUseStreams}
  procedure TExList.ItemToStream(PItem :Pointer; Stream :TStream); {virtual;}
  begin
    Wrong;
  end;


  procedure TExList.ItemFromStream(PItem :Pointer; Stream :TStream); {virtual;}
  begin
    Wrong;
  end;


  procedure TExList.WriteToStream(Stream :TStream); {override;}
  var
    I :Integer;
    P :Pointer1;
  begin
    P := Pointer1(FList);
    for I := 0 to FCount - 1 do begin
      ByteToStream(Stream, 1);
      ItemToStream(P, Stream);
      inc(P, FItemSize);
    end;
    ByteToStream(Stream, 0);
  end;


  procedure TExList.ReadFromStream(Stream :TStream); {override;}
  begin
    Clear;
    AppendFromStream(Stream);
  end;


  procedure TExList.AppendFromStream(Stream :TStream); {virtual;}
  var
    P :Pointer;
  begin
    while ByteFromStream(Stream) = 1 do begin
      if FCount = FCapacity then
        Grow;
      P := Pointer1(FList) + FCount * FItemSize;
      ItemFromStream(P, Stream);
      Inc(FCount);
    end;
  end;
 {$endif bUseStreams}


 {---------------------------------------------}

  procedure TExList.ItemFree(PItem :Pointer); {virtual;}
  begin
    {};
  end;


  function TExList.ItemCompare(PItem, PAnother :Pointer; Context :TIntPtr) :Integer; {virtual;}
  begin
    Wrong; Result := 0;
  end;


  function TExList.ItemCompareKey(PItem :Pointer; Key :Pointer; Context :TIntPtr) :Integer; {virtual;}
  begin
    Wrong; Result := 0;
  end;


  function TExList.FindKey(Key :Pointer; Context :TIntPtr; Opt :TFindOptions; var Index :Integer) :Boolean; {virtual;}
  var
    I, L, H, C :Integer;
    P :Pointer;
  begin
    Result := False;

    if not (foBinary in Opt) then begin
      { ����� ������� ��������� }

      P := FList;
      for I := 0 to FCount - 1 do begin
        if foCompareObj in Opt then
          C := ItemCompare(P, @Key, Context)
        else
          C := ItemCompareKey(P, Key, Context);
        if C = 0 then begin
          Result := True;
          Index  := I;
          Exit;
        end;
        inc(Pointer1(P), FItemSize);
      end;

      Index := FCount;
    end else
    begin
      { �������� �����. ������ ���� �������, ��� ��������� �������������! }

      L := 0;
      H := FCount - 1;

      while L <= H do begin
        I := (L + H) shr 1;
        P := Pointer1(FList) + I * FItemSize;
        if foCompareObj in Opt then
          C := ItemCompare(P, @Key, Context)
        else
          C := ItemCompareKey(P, Key, Context);
        if C = 0 then begin
          Result := True;
          Index := I;
          Exit;
        end;
        if C < 0 then
          L := I + 1
        else
          H := I - 1;
      end;

      Index := L;
    end;

//  if not Result and (foExceptOnFail in Opt) then
//    ListError(errComListItemNotFound);
  end;


  procedure TExList.SortList(Ascend :Boolean; Context :TIntPtr);

    procedure LocQuickSort(L, R :Integer);
    var
      I, J, P :Integer;
      vPtr :Pointer;
    begin
      repeat
        I := L;
        J := R;
        P := (L + R) shr 1;
        repeat
          vPtr := PItems[P];

          if Ascend then begin
            while ItemCompare(PItems[I], vPtr, Context) < 0 do
              Inc(I);
            while ItemCompare(PItems[J], vPtr, Context) > 0 do
              Dec(J);
          end else
          begin
            while ItemCompare(PItems[I], vPtr, Context) > 0 do
              Inc(I);
            while ItemCompare(PItems[J], vPtr, Context) < 0 do
              Dec(J);
          end;

          if I <= J then begin
            if I <> J then
              Exchange(I, J);
            if P = I then
              P := J
            else
            if P = J then
              P := I;
            Inc(I);
            Dec(J);
          end;
        until I > J;

        if L < J then
          LocQuickSort(L, J);

        L := I;
      until I >= R;
    end;

  begin
    if Count > 1 then
      LocQuickSort(0, Count - 1)
  end;


 {---------------------------------------------}

  procedure MemExchange(APtr1, APtr2 :Pointer; ASize :Integer);
  var
    vCnt :Integer;
    vInt :TUnsPtr;
    vByte :Byte;
  begin
    vCnt := SizeOf(Pointer);
    while ASize >= vCnt do begin
      vInt := TUnsPtr(APtr1^);
      TUnsPtr(APtr1^) := TUnsPtr(APtr2^);
      TUnsPtr(APtr2^) := vInt;
      Inc(Pointer1(APtr1), vCnt);
      Inc(Pointer1(APtr2), vCnt);
      Dec(ASize, vCnt);
    end;
    while ASize >=1 do begin
      vByte := Byte(APtr1^);
      Byte(APtr1^) := Byte(APtr2^);
      Byte(APtr2^) := vByte;
      Inc(Pointer1(APtr1));
      Inc(Pointer1(APtr2));
      Dec(ASize);
    end;
  end;


  procedure TExList.Exchange(Index1, Index2: Integer); {virtual;}
  begin
    if (Index1 < 0) or (Index1 >= FCount) then
      AppErrorResFmt(@SListIndexError, [Index1]);
    if (Index2 < 0) or (Index2 >= FCount) then
      AppErrorResFmt(@SListIndexError, [Index2]);
    MemExchange(Pointer1(FList) + Index1 * FItemSize, Pointer1(FList) + Index2 * FItemSize, FItemSize)
  end;


  procedure TExList.Move(CurIndex, NewIndex: Integer);
  const
    cTmpBufSize = 128;
  var
    vPtr1, vPtr2 :Pointer1;
    vTmp :Pointer;
    vBuf :array[0..cTmpBufSize - 1] of Byte;
  begin
    if CurIndex <> NewIndex then begin
      vTmp := @vBuf;
      if FItemSize > cTmpBufSize then
        vTmp := MemAlloc(FItemSize);
      try
        vPtr1 := GetPItems(CurIndex);
        vPtr2 := GetPItems(NewIndex);
        System.Move(vPtr1^, vTmp^, FItemSize);
        if NewIndex > CurIndex then
          System.Move((vPtr1 + FItemSize)^, vPtr1^, vPtr2 - vPtr1)
        else
          System.Move(vPtr2^, (vPtr2 + FItemSize)^, vPtr1 - vPtr2);
        System.Move(vTmp^, vPtr2^, FItemSize);
      finally
        if FItemSize > cTmpBufSize then
          MemFree(vTmp);
      end;
    end;
  end;


 {-----------------------------------------------------------------------------}
 { TObjList                                                                    }
 {-----------------------------------------------------------------------------}

  constructor TObjList.Create; {override;}
  begin
    inherited Create;
    FOptions := [loItemFree];
  end;

(*
  procedure TObjList.Assign(Source :TPersistent); {overrite;}
  var
    I :Integer;
  begin
    if Source is TObjList then begin
      FreeAll;
      with TObjList(Source) do
        for I := 0 to Count - 1 do
          Self.Add( (TObject(List[I]) as TBasis).Clone );
    end else
      inherited Assign(Source);
  end;
*)

 {$ifdef bUseStreams}
  procedure TObjList.ReadFromStream(Stream :TStream); {override;}
  begin
    Clear;
    AppendFromStream(Stream);
  end;
 {$endif bUseStreams}


  procedure TObjList.FreeAll;
  begin
    Clear;
  end;

  
  procedure TObjList.FreeAt(AIndex: Integer);
  begin
    Delete(AIndex);
  end;


 {-----------------------------------------------------------------------------}

  procedure TObjList.ItemFree(PItem :Pointer); {override;}
  begin
    FreeObj(PItem^);
  end;


//procedure TObjList.ItemAssign(PItem, PSource :Pointer); {override;}
//begin
//  Assert(TBasis(PSource^).ValidInstance);
//  TBasis(PItem^) := TBasis(PSource^).Clone;
//end;


  function TObjList.ItemCompare(PItem, PAnother :Pointer; Context :TIntPtr) :Integer; {override;}
  begin
    Assert(TBasis(PItem^).ValidInstance and TBasis(PAnother^).ValidInstance);
    Result := TBasis(PItem^).CompareObj(TBasis(PAnother^), Context);
  end;

  function TObjList.ItemCompareKey(PItem :Pointer; Key :Pointer; Context :TIntPtr) :Integer; {override;}
  begin
    Assert(TBasis(PItem^).ValidInstance);
    Result := TBasis(PItem^).CompareKey(Key, Context);
  end;


 {$ifdef bUseStreams}
  procedure TObjList.ItemToStream(PItem :Pointer; Stream :TStream); {override;}
  begin
    Assert(TBasis(PItem^).ValidInstance);
    ObjectToStream(Stream, TBasis(PItem^));
  end;

  procedure TObjList.ItemFromStream(PItem :Pointer; Stream :TStream); {override;}
  begin
    TBasis(PItem^) := ObjectFromStream(Stream);
  end;
 {$endif bUseStreams}


 {-----------------------------------------------------------------------------}
 { TIntList                                                                    }
 {-----------------------------------------------------------------------------}

  function TIntList.Add(Item :TIntPtr) :Integer;
  begin
    Result := AddData(Item);
  end;


  function TIntList.ItemCompare(PItem, PAnother :Pointer; Context :TIntPtr) :Integer; {override;}
  begin
    Result := IntCompare(PIntPtr(PItem)^, PIntPtr(PAnother)^);
  end;


  function TIntList.ItemCompareKey(PItem :Pointer; Key :Pointer; Context :TIntPtr) :Integer; {override;}
  begin
    Result := IntCompare(PIntPtr(PItem)^, TIntPtr(Key));
  end;


 {$ifdef bUseStreams}
  procedure TIntList.ItemToStream(PItem :Pointer; Stream :TStream); {override;}
  begin
    IntToStream(Stream, Integer(PItem^));
  end;


  procedure TIntList.ItemFromStream(PItem :Pointer; Stream :TStream); {override;}
  begin
    Integer(PItem^) := IntFromStream(Stream);
  end;
 {$endif bUseStreams}


  function TIntList.GetIntItems(Index :Integer) :TIntPtr;
  begin
    Result := TIntPtr(inherited GetItems(Index));
  end;


  procedure TIntList.PutIntItems(Index :Integer; Value :TIntPtr);
  begin
    inherited PutItems(Index, Pointer(Value));
  end;


 {-----------------------------------------------------------------------------}
 { TStrList                                                                    }
 {-----------------------------------------------------------------------------}

  constructor TStrList.Create; {override;}
  begin
    inherited Create;
    FOptions := [loItemFree];
  end;


  procedure TStrList.ItemFree(PItem :Pointer); {override;}
  begin
    TString(PItem^) := '';
  end;


  function TStrList.ItemCompare(PItem, PAnother :Pointer; Context :TIntPtr) :Integer; {override;}
  begin
    Result := UpCompareStr(TString(PItem^), TString(PANother^));
  end;


 {$ifdef bUseStreams}
  procedure TStrList.ItemToStream(PItem :Pointer; Stream :TStream); {override;}
  begin
    StrToStream(Stream, TString(PItem^));
  end;

  procedure TStrList.ItemFromStream(PItem :Pointer; Stream :TStream); {override;}
  begin
    Pointer(PItem^) := nil;
    TString(PItem^) := StrFromStream(Stream);
  end;
 {$endif bUseStreams}


  function TStrList.IndexOf(const AStr :TString) :Integer;
  var
    I :Integer;
  begin
    for I := 0 to FCount - 1 do begin
      if StrEqual(TString(FList[I]), AStr) then begin
        Result := I;
        Exit;
      end;
    end;
    Result := -1;
  end;


  function TStrList.Add(const AStr :TString) :Integer;
  begin
    Result := FCount;
    Insert(FCount, AStr);
  end;

  procedure TStrList.Insert(Index :Integer; const AStr :TString);
  var
    vTmp :Pointer;
  begin
    vTmp := nil;
    TString(vTmp) := AStr;
    { � InsertData ����� ��������� �� AStr, � vTmp, ����� ������ � Unicode-������ }
    InsertData(Index, vTmp);
  end;


  function TStrList.AddSorted(const AStr :TString; Context :TIntPtr; Duplicates :TDuplicates) :Integer;
  begin
    if FindKey(Pointer(AStr), Context, [foCompareObj, foBinary], Result) then begin
      case Duplicates of
        dupIgnore : Exit;
        dupError  : AppErrorRes(@SDuplicateError);
      end;
    end;
    Insert(Result, AStr);
  end;


  function TStrList.GetStrItems(Index :Integer) :TString;
  begin
    Result := TString(inherited GetItems(Index));
  end;

  procedure TStrList.PutStrItems(Index :Integer; const Value :TString);
  begin
    Assert(ValidInstance);
    if (Index < 0) or (Index >= FCount) then
      AppErrorResFmt(@SListIndexError, [Index]);
    TString(FList[Index]) := Value;
  end;


 {-----------------------------------------------------------------------------}
 { TNamedObject                                                                }
 {-----------------------------------------------------------------------------}

  constructor TNamedObject.CreateName(const AName :TString); {virtual;}
  begin
    Create;
    FName := AName;
  end;


(*
  procedure TNamedObject.Assign(Source :TPersistent); {override;}
  begin
    if Source is TNamedObject then
      FName := TNamedObject(Source).Name
    else
      inherited Assign(Source);
  end;
*)

 {$ifdef bUseStreams}
  procedure TNamedObject.WriteToStream (Stream :TStream); {override;}
  begin
    StrToStream(Stream, FName);
  end;


  procedure TNamedObject.ReadFromStream (Stream :TStream); {override;}
  begin
    FName := StrFromStream(Stream);
  end;
 {$endif bUseStreams}


  function TNamedObject.CompareObj(Another :TBasis; Context :TIntPtr) :Integer; {override;}
  begin
    if Another is TNamedObject then
      Result := UpCompareStr(FName, TNamedObject(Another).Name)
    else
      Result := inherited CompareObj(Another, Context);
  end;


  function TNamedObject.CompareKey(Key :Pointer; Context :TIntPtr) :Integer; {override;}
  begin
    Result := UpCompareStr(FName, TString(Key));
  end;


 {-----------------------------------------------------------------------------}
 { TDescrObject                                                                }
 {-----------------------------------------------------------------------------}

  constructor TDescrObject.CreateEx(const AName, ADescr :TString);
  begin
    Create;
    FName := AName;
    FDescr := ADescr;
  end;

(*
  procedure TDescrObject.Assign(Source :TPersistent); {override;}
  begin
    if Source is TDescrObject then begin
      inherited Assign(Source);
      FDescr := TDescrObject(Source).Descr;
    end else
      inherited Assign(Source);
  end;
*)

 {$ifdef bUseStreams}
  procedure TDescrObject.WriteToStream(AStream :TStream); {override;}
  begin
    inherited WriteToStream(AStream);
    StrToStream(AStream, FDescr);
  end;


  procedure TDescrObject.ReadFromStream(AStream :TStream); {override;}
  begin
    inherited ReadFromStream(AStream);
    FDescr := StrFromStream(AStream);
  end;
 {$endif bUseStreams}


 {-----------------------------------------------------------------------------}
 { TStringList = class(TStringList)                                            }
 {-----------------------------------------------------------------------------}

  constructor TStringList.Create; {override;}
  begin
    inherited Create;
    FItemSize  := SizeOf(TStringItem);
    FItemLimit := MaxInt div FItemSize;
    FOptions := [loItemFree];
  end;


  procedure TStringList.ItemFree(Item :Pointer); {override;}
  begin
    with PStringItem(Item)^ do
      FString := '';
  end;


  function TStringList.ItemCompareKey(PItem :Pointer; Key :Pointer; Context :TIntPtr) :Integer; {override;}
  begin
    Result := UpCompareStr(PStringItem(PItem).FString, TString(Key));
  end;


  function TStringList.Add(const S :TString) :Integer;
  begin
    Result := AddObject(S, nil);
  end;

  procedure TStringList.Insert(AIndex :Integer; const S :TString);
  begin
    InsertObject(AIndex, S, nil);
  end;


  function TStringList.AddObject(const S :TString; AObject :Pointer) :Integer;
  begin
    if not FSorted then
      Result := FCount
    else
      if FindKey(Pointer(S), 0, [foBinary], Result) then
        case FDuplicates of
          dupIgnore: Exit;
          dupError: AppErrorRes(@SDuplicateError);
        end;
    InsertObject(Result, S, AObject);
  end;


  procedure TStringList.InsertObject(AIndex: Integer; const S :TString; AObject :Pointer);
  begin
    with PStringItem(NewItem(AIndex))^ do begin
      Pointer(FString) := nil;
      FString := S;
      FObject := AObject;
    end;
  end;


  function TStringList.IndexOf(const S :TString): Integer;
  var
    vOpt :TFindOptions;
  begin
    vOpt := [];
    if FSorted then
      vOpt := [foBinary];
    if not FindKey(Pointer(S), 0, vOpt, Result) then
      Result := -1;
  end;


  function TStringList.GetStrItems(Index :Integer) :TString;
  begin
    Result := PStringItem(GetPItems(Index)).FString;
  end;

  procedure TStringList.PutStrItems(Index :Integer; const Value :TString);
  begin
    PStringItem(GetPItems(Index)).FString := Value;
  end;

  function TStringList.GetObject(Index :Integer) :TObject;
  begin
    Result := PStringItem(GetPItems(Index)).FObject;
  end;

  procedure TStringList.PutObject(Index :Integer; Value :TObject);
  begin
    PStringItem(GetPItems(Index)).FObject := Value;
  end;


  function TStringList.GetTextStr :TString;
  var
    I, vLen, vSize :Integer;
    vFrame :PStringItem;
    vPtr :PTChar;
  begin
    vSize := 0;
    vFrame := Pointer(FList);
    for I := 0 to FCount - 1 do begin
      Inc(vSize, Length(vFrame.FString) + 2);
      Inc(Pointer1(vFrame), FItemSize);
    end;

    SetString(Result, nil, vSize);
    vPtr := Pointer(Result);
    vFrame := Pointer(FList);
    for I := 0 to FCount - 1 do begin
      vLen := Length(vFrame.FString);
      if vLen > 0 then begin
        StrMove(vPtr, PTChar(vFrame.FString), vLen);
        Inc(vPtr, vLen);
      end;
      Inc(Pointer1(vFrame), FItemSize);
      vPtr^ := #13;
      Inc(vPtr);
      vPtr^ := #10;
      Inc(vPtr);
    end;
  end;


  procedure TStringList.SetTextStr(const Value :TString);
  var
    vPtr, vBeg :PTChar;
    vStr :TString;
  begin
    Clear;
    vPtr := PTChar(Value);
    while vPtr^ <> #0 do begin
      vBeg := vPtr;
      while (vPtr^ <> #0) and (vPtr^ <> #10) and (vPtr^ <> #13) do
        Inc(vPtr);
      SetString(vStr, vBeg, vPtr - vBeg);
      Add(vStr);
      if vPtr^ = #13 then
        Inc(vPtr);
      if vPtr^ = #10 then
        Inc(vPtr);
    end;
  end;


  procedure TStringList.SaveToFile(const AFileName :TString; AMode :TStrFileFormat = sffAuto);
  begin
    StrToFile(AFileName, GetTextStr, AMode);
  end;

  procedure TStringList.LoadFromFile(const AFileName :TString; AMode :TStrFileFormat = sffAuto);
  begin
    SetTextStr( StrFromFile(AFileName, AMode) );
  end;


 {-----------------------------------------------------------------------------}
 { TObjStrings = class(TStringList)                                            }
 {-----------------------------------------------------------------------------}

  procedure TObjStrings.ItemFree(Item :Pointer); {override;}
  begin
    with PStringItem(Item)^ do begin
      FString := '';
      FreeObj(FObject);
    end;
  end;

 {-----------------------------------------------------------------------------}
 { TBits                                                                       }
 {-----------------------------------------------------------------------------}

 {$ifdef b64}
  procedure _SetBit({RCX:}ABits :Pointer; {RDX:}ABitIdx :TIntPtr); register;
  asm
    BTS     [RCX], RDX
  end;

  procedure _ClearBit({RCX:}ABits :Pointer; {RDX:}ABitIdx :TIntPtr); register;
  asm
    BTR     [RCX], RDX
  end;

  function _GetBit({RCX:}ABits :Pointer; {RDX:}ABitIdx :TIntPtr): Boolean; register;
  asm
    BT      [RCX], RDX
    SBB     RAX, RAX
    AND     RAX, 1
  end;

 {$else}

  procedure _SetBit({EAX:}ABits :Pointer; {EDX:}ABitIdx :TIntPtr); register;
  asm
    BTS     [EAX],EDX
  end;

  procedure _ClearBit({EAX:}ABits :Pointer; {EDX:}ABitIdx :TIntPtr); register;
  asm
    BTR     [EAX],EDX
  end;

  function _GetBit({EAX:}ABits :Pointer; {EDX:}ABitIdx :TIntPtr) :Boolean; register;
  asm
    BT      [EAX], EDX
    SBB     EAX, EAX
    AND     EAX, 1
  end;
 {$endif b64}


  const
    BitsPerInt = SizeOf(Integer) * 8;

  type
    TBitEnum = 0..BitsPerInt - 1;
    TBitSet = set of TBitEnum;
    PBitArray = ^TBitArray;
    TBitArray = array[0..4096] of TBitSet;

  destructor TBits.Destroy;
  begin
    SetSize(0);
    inherited Destroy;
  end;

  procedure TBits.Error;
  begin
    AppErrorRes(@SBitsIndexError);
  end;

  procedure TBits.SetSize(Value: Integer);
  var
    NewMem: Pointer;
    NewMemSize: Integer;
    OldMemSize: Integer;

    function Min(X, Y: Integer): Integer;
    begin
      Result := X;
      if X > Y then
        Result := Y;
    end;

  begin
    if Value <> Size then begin
      if Value < 0 then
        Error;
      NewMemSize := ((Value + BitsPerInt - 1) div BitsPerInt) * SizeOf(Integer);
      OldMemSize := ((Size + BitsPerInt - 1) div BitsPerInt) * SizeOf(Integer);
      if NewMemSize <> OldMemSize then begin
        NewMem := nil;
        if NewMemSize <> 0 then begin
          GetMem(NewMem, NewMemSize);
          FillChar(NewMem^, NewMemSize, 0);
        end;
        if OldMemSize <> 0 then begin
          if NewMem <> nil then
            Move(FBits^, NewMem^, Min(OldMemSize, NewMemSize));
          FreeMem(FBits, OldMemSize);
        end;
        FBits := NewMem;
      end;
      FSize := Value;
    end;
  end;


  procedure TBits.SetBit(Index: Integer; Value: Boolean);
  begin
    if Index < 0 then
      Error;
    if Index >= FSize then
      SetSize(Index + 1);
    if Value then
      _SetBit(FBits, Index)
    else
      _ClearBit(FBits, Index)
  end;


  function TBits.GetBit(Index: Integer): Boolean;
  begin
    if (Index < 0) or (Index >= FSize) then
      Error;
    Result := _GetBit(FBits, Index);
  end;


  function TBits.OpenBit: Integer;
  var
    I: Integer;
    B: TBitSet;
    J: TBitEnum;
    E: Integer;
  begin
    E := (Size + BitsPerInt - 1) div BitsPerInt - 1;
    for I := 0 to E do
      if PBitArray(FBits)^[I] <> [0..BitsPerInt - 1] then begin
        B := PBitArray(FBits)^[I];
        for J := Low(J) to High(J) do begin
          if not (J in B) then begin
            Result := I * BitsPerInt + J;
            if Result >= Size then
              Result := Size;
            Exit;
          end;
        end;
      end;
    Result := Size;
  end;


 {-----------------------------------------------------------------------------}
 { TThread                                                                     }
 {-----------------------------------------------------------------------------}

  function ThreadProc(Thread: TThread): Integer;
  var
    FreeThread :Boolean;
   {$ifdef bTrace}
    vName :TAnsiStr;
   {$endif bTrace}
  begin
    try
     {$ifdef bTrace}
      vName := Thread.ClassName;
     {$endif bTrace}

     {$ifdef bTrace}
      try
     {$endif bTrace}

       {$ifdef bTrace}
        TraceF('Thread begin: %s', [vName]);
       {$endif bTrace}

        Thread.Execute;

       {$ifdef bTrace}
        TraceF('Thread finish: %s', [vName]);
       {$endif bTrace}

     {$ifdef bTrace}
      except
        on E :Exception do begin
          TraceF('Unhandled thread exception. %s, %s: %s', [vName, E.ClassName, E.Message]);
          raise;
        end;
      end;
     {$endif bTrace}

    finally
     {$ifdef bTrace}
      vName := '';
     {$endif bTrace}
      FreeThread := Thread.FFreeOnTerminate;
      Result := Thread.FReturnValue;
      Thread.FFinished := True;
      Thread.DoTerminate;
      if FreeThread then
        Thread.Free;
      EndThread(Result);
    end;
  end;


  constructor TThread.Create(CreateSuspended: Boolean);
  var
    Flags: DWORD;
  begin
    inherited Create;
  //{$ifdef bTrace}
  // TraceExF('ThreadInfo', 'Create thread object: %s', [ClassName]);
  //{$endif bTrace}
   {$ifdef bSynchronize}
  //AddThread;
   {$endif bSynchronize}
    FSuspended := CreateSuspended;
    Flags := 0;
    if CreateSuspended then
      Flags := CREATE_SUSPENDED;
    FHandle := BeginThread(nil, 0, Pointer(@ThreadProc), Pointer(Self), Flags, FThreadID);
  end;

  destructor TThread.Destroy;
  begin
    if not FFinished and not Suspended then begin
      Terminate;
      WaitFor;
    end;
    if FHandle <> 0 then
      CloseHandle(FHandle);
    inherited Destroy;
  //{$ifdef bTrace}
  // TraceExF('ThreadInfo', 'Destroy thread object: %s', [ClassName]);
  //{$endif bTrace}
   {$ifdef bSynchronize}
  //RemoveThread;
   {$endif bSynchronize}
  end;

//procedure TThread.CallOnTerminate;
//begin
//  if Assigned(FOnTerminate) then
//    FOnTerminate(Self);
//end;

  procedure TThread.DoTerminate; {virtual;}
  begin
//  if Assigned(FOnTerminate) then
//    Synchronize(CallOnTerminate);
  end;

  const
    Priorities: array [TThreadPriority] of Integer =
     (THREAD_PRIORITY_IDLE, THREAD_PRIORITY_LOWEST, THREAD_PRIORITY_BELOW_NORMAL,
      THREAD_PRIORITY_NORMAL, THREAD_PRIORITY_ABOVE_NORMAL,
      THREAD_PRIORITY_HIGHEST, THREAD_PRIORITY_TIME_CRITICAL);

  function TThread.GetPriority: TThreadPriority;
  var
    P: Integer;
    I: TThreadPriority;
  begin
    P := GetThreadPriority(FHandle);
    Result := tpNormal;
    for I := Low(TThreadPriority) to High(TThreadPriority) do
      if Priorities[I] = P then Result := I;
  end;

  procedure TThread.SetPriority(Value: TThreadPriority);
  begin
    SetThreadPriority(FHandle, Priorities[Value]);
  end;

//procedure TThread.Synchronize(Method: TThreadMethod);
//begin
//  FSynchronizeException := nil;
//  FMethod := Method;
//end;

  procedure TThread.SetSuspended(Value: Boolean);
  begin
    if Value <> FSuspended then
      if Value then
        Suspend else
        Resume;
  end;

  procedure TThread.Suspend;
  begin
    FSuspended := True;
    SuspendThread(FHandle);
  end;

  procedure TThread.Resume;
  begin
    if ResumeThread(FHandle) = 1 then FSuspended := False;
  end;

  procedure TThread.Terminate;
  begin
    FTerminated := True;
  end;

  function TThread.WaitFor: LongWord;
  var
    Msg: TMsg;
    H: THandle;
  begin
    H := FHandle;
    if GetCurrentThreadID = MainThreadID then
      while MsgWaitForMultipleObjects(1, H, False, INFINITE,
        QS_SENDMESSAGE) = WAIT_OBJECT_0 + 1 do PeekMessage(Msg, 0, 0, 0, PM_NOREMOVE)
    else WaitForSingleObject(H, INFINITE);
    GetExitCodeThread(H, Result);
  end;


end.
