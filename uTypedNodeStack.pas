unit uTypedNodeStack;

{$mode ObjFPC}{$H+}{$T+}

interface

uses
  Classes, SysUtils, syncobjs;

const
  strDateTypes: array of string =
    ('dtNone', 'dtInt', 'dtFloat', 'dtBool', 'dtStr', 'dtPtr');

type
  DateTypes = (dtNone, dtInt, dtFloat, dtBool, dtStr, dtPtr);


  TNode = record
    PrevNode: ^TNode;
    Data: array[0..SizeOf(Pointer) - 1] of byte;
    TData: DateTypes;
  end;
  PNode = ^TNode;

type

  { TStackNode }

  TStackNode = class(TObject)
  private
    lastNode: PNode;
    fs: TFormatSettings;
    Count: integer;
    FLock: TCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    function isEmpty: boolean;
    procedure push(const Value: int64); overload;
    procedure push(const Value: double); overload;
    procedure push(const Value: boolean); overload;
    procedure push(const Value: Pointer); overload;
    procedure push(const Value: string); overload;
    function popInt: int64;
    function popFloat: double;
    function popBool: boolean;
    function popPtr: Pointer;
    function popStr: string;
    function peekInt: int64;
    function peekFloat: double;
    function peekBool: boolean;
    function peekPointer: Pointer;
    function peekStr: string;
    function topType: DateTypes;
    function GetArrToStr: string;
    procedure Clear;
    function GetCount: integer;
    function GetCountChickens: integer;
    function popToStr: string;

  end;

implementation

{ TStackNode }

constructor TStackNode.Create;
begin
  lastNode := nil;
  FLock := TCriticalSection.Create;
  Count := 0;
  fs.DecimalSeparator := '.';
  fs.ListSeparator := ',';
end;

destructor TStackNode.Destroy;
begin
  Clear;
  FLock.Free;
  inherited Destroy;
end;

function TStackNode.isEmpty: boolean;
begin
  Result := lastNode = nil;
end;

procedure TStackNode.push(const Value: int64);
var
  Node: PNode;
begin
  FLock.Enter;
  try
    New(Node);
    try
      Node^.TData := dtInt;
      Move(Value, Node^.Data, SizeOf(int64));
      Node^.PrevNode := lastNode;
      lastNode := Node;
      Inc(Count);
    except
      Dispose(Node);
      raise;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TStackNode.push(const Value: double);
var
  Node: PNode;
begin
  FLock.Enter;
  try
    New(Node);
    try
      Node^.TData := dtFloat;
      Move(Value, Node^.Data, SizeOf(double));
      Node^.PrevNode := lastNode;
      lastNode := Node;
      Inc(Count);
    except
      Dispose(Node);
      raise;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TStackNode.push(const Value: boolean);
var
  Node: PNode;
begin
  FLock.Enter;
  try
    New(Node);
    try
      Node^.TData := dtBool;
      Move(Value, Node^.Data, SizeOf(boolean));
      Node^.PrevNode := lastNode;
      lastNode := Node;
      Inc(Count);
    except
      Dispose(Node);
      raise;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TStackNode.push(const Value: Pointer);
var
  Node: PNode;
begin
  FLock.Enter;
  try
    New(Node);
    try
      Node^.TData := dtPtr;
      Move(Value, Node^.Data, SizeOf(Pointer));
      Node^.PrevNode := lastNode;
      lastNode := Node;
      Inc(Count);
    except
      Dispose(Node);
      raise;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TStackNode.push(const Value: string);
var
  Node: PNode;
begin
  FLock.Enter;
  try
    New(Node);
    try
      Node^.TData := dtStr;
      Move(Value, Node^.Data, SizeOf(string));
      Node^.PrevNode := lastNode;
      lastNode := Node;
      Inc(Count);
    except
      Dispose(Node);
      raise;
    end;
  finally
    FLock.Leave;
  end;
end;

function TStackNode.popInt: int64;
var
  Node: PNode;
  Value: int64 = 0;
begin
  FLock.Enter;
  try
    if isEmpty then
      raise Exception.Create('Стек пустой!');
    if lastNode^.TData <> dtInt then
      raise Exception.Create('Неверный тип! Запрос на ' +
        strDateTypes[Ord(dtInt)] + ', в стеке ' +
        strDateTypes[Ord(lastNode^.TData)]);

    Node := lastNode;
    Move(Node^.Data, Value, SizeOf(int64));
    Result := Value;

    lastNode := Node^.PrevNode;
    Dispose(Node);
    Dec(Count);
  finally
    FLock.Leave;
  end;
end;

function TStackNode.popFloat: double;
var
  Node: PNode;
  Value: double = 0.0;
begin
  FLock.Enter;
  try
    if isEmpty then
      raise Exception.Create('Стек пустой!');
    if lastNode^.TData <> dtFloat then
      raise Exception.Create('Неверный тип! Запрос на ' +
        strDateTypes[Ord(dtFloat)] + ', в стеке ' +
        strDateTypes[Ord(lastNode^.TData)]);

    Node := lastNode;
    Move(Node^.Data, Value, SizeOf(double));
    Result := Value;

    lastNode := Node^.PrevNode;
    Dispose(Node);
    Dec(Count);
  finally
    FLock.Leave;
  end;
end;

function TStackNode.popBool: boolean;
var
  Node: PNode;
  Value: boolean = False;
begin
  FLock.Enter;
  try
    if isEmpty then
      raise Exception.Create('Стек пустой!');
    if lastNode^.TData <> dtBool then
      raise Exception.Create('Неверный тип! Запрос на ' +
        strDateTypes[Ord(dtBool)] + ', в стеке ' +
        strDateTypes[Ord(lastNode^.TData)]);

    Node := lastNode;
    Move(Node^.Data, Value, SizeOf(boolean));
    Result := Value;

    lastNode := Node^.PrevNode;
    Dispose(Node);
    Dec(Count);
  finally
    FLock.Leave;
  end;
end;

function TStackNode.popPtr: Pointer;
var
  Node: PNode;
  Value: Pointer = nil;
begin
  FLock.Enter;
  try
    Value := nil;
    if isEmpty then
      raise Exception.Create('Стек пустой!');
    if lastNode^.TData <> dtPtr then
      raise Exception.Create('Неверный тип! Запрос на ' +
        strDateTypes[Ord(dtPtr)] + ', в стеке ' +
        strDateTypes[Ord(lastNode^.TData)]);

    Node := lastNode;
    Move(Node^.Data, Value, SizeOf(Pointer));
    Result := Value;

    lastNode := Node^.PrevNode;
    Dispose(Node);
    Dec(Count);
  finally
    FLock.Leave;
  end;
end;

function TStackNode.popStr: string;
var
  Node: PNode;
  Value: string = '';
begin
  FLock.Enter;
  try
    if isEmpty then
      raise Exception.Create('Стек пустой!');
    if lastNode^.TData <> dtStr then
      raise Exception.Create('Неверный тип! Запрос на ' +
        strDateTypes[Ord(dtStr)] + ', в стеке ' +
        strDateTypes[Ord(lastNode^.TData)]);
    Value := '';
    Node := lastNode;
    Move(Node^.Data, Value, SizeOf(string));
    Result := Value;

    lastNode := Node^.PrevNode;
    Dispose(Node);
    Dec(Count);
  finally
    FLock.Leave;
  end;
end;

function TStackNode.peekInt: int64;
begin
  FLock.Enter;
  try
    if isEmpty then
      raise Exception.Create('Стек пустой!');
    if lastNode^.TData <> dtInt then
      raise Exception.Create('Неверный тип! Запрос на ' +
        strDateTypes[Ord(dtInt)] + ', в стеке ' +
        strDateTypes[Ord(lastNode^.TData)]);
    Result := PInt64(lastNode^.Data)^;
  finally
    FLock.Leave;
  end;
end;

function TStackNode.peekFloat: double;
begin
  FLock.Enter;
  try
    if isEmpty then
      raise Exception.Create('Стек пустой!');
    if lastNode^.TData <> dtFloat then
      raise Exception.Create('Неверный тип! Запрос на ' +
        strDateTypes[Ord(dtFloat)] + ', в стеке ' +
        strDateTypes[Ord(lastNode^.TData)]);
    Result := PDouble(lastNode^.Data)^;
  finally
    FLock.Leave;
  end;
end;

function TStackNode.peekBool: boolean;
begin
  FLock.Enter;
  try
    if isEmpty then
      raise Exception.Create('Стек пустой!');
    if lastNode^.TData <> dtBool then
      raise Exception.Create('Неверный тип! Запрос на ' +
        strDateTypes[Ord(dtBool)] + ', в стеке ' +
        strDateTypes[Ord(lastNode^.TData)]);
    Result := PBoolean(lastNode^.Data)^;
  finally
    FLock.Leave;
  end;
end;

function TStackNode.peekPointer: Pointer;
begin
  FLock.Enter;
  try
    if isEmpty then
      raise Exception.Create('Стек пустой!');
    if lastNode^.TData <> dtPtr then
      raise Exception.Create('Неверный тип! Запрос на ' +
        strDateTypes[Ord(dtPtr)] + ', в стеке ' +
        strDateTypes[Ord(lastNode^.TData)]);
  finally
    FLock.Leave;
  end;
end;

function TStackNode.peekStr: string;
begin
  FLock.Enter;
  try
    if isEmpty then
      raise Exception.Create('Стек пустой!');
    if lastNode^.TData <> dtStr then
      raise Exception.Create('Неверный тип! Запрос на ' +
        strDateTypes[Ord(dtStr)] + ', в стеке ' +
        strDateTypes[Ord(lastNode^.TData)]);
    Result := PString(lastNode^.Data)^;
  finally
    FLock.Leave;
  end;
end;

function TStackNode.topType: DateTypes;
begin
  FLock.Enter;
  try
    if isEmpty then
      Result := dtNone
    else
      Result := lastNode^.TData;
  finally
    FLock.Leave;
  end;
end;

function TStackNode.GetArrToStr: string;
var
  curNode: PNode;

  function pr(const cr: PNode): string; inline;
  var
    valueInt: int64 = 0;
    valueFloat: double = 0.0;
    valueBool: boolean = False;
    valueStr: string = '';
    valuePtr: Pointer = nil;
  begin
    case cr^.TData of
      dtInt: begin
        Move(cr^.Data, valueInt, SizeOf(int64));
        Result := IntToStr(valueInt);
      end;
      dtFloat:
      begin
        Move(cr^.Data, valueFloat, SizeOf(double));
        Result := floattostr(valueFloat, fs);
      end;
      dtBool:
      begin
        Move(cr^.Data, valueBool, SizeOf(boolean));
        Result := BoolToStr(valueBool, 'True', 'False');
      end;
      dtStr:
      begin
        Move(cr^.Data, valueStr, SizeOf(string));
        Result := '"' + valueStr + '"';
      end;
      dtPtr: begin
        Move(cr^.Data, valuePtr, SizeOf(Pointer));
        Result := BoolToStr(valuePtr <> nil, 'Ptr', 'Nil');
      end;
    end;
  end;

begin
  FLock.Enter;
  try
    curNode := lastNode;
    Result := '[';
    while curNode <> nil do
    begin
      Result := Result + pr(curNode);
      curNode := curNode^.PrevNode;
      if curNode <> nil then Result := Result + fs.ListSeparator + ' ';
    end;
    Result := Result + ']';
  finally
    FLock.Leave;
  end;
end;

procedure TStackNode.Clear;
var
  curNode: PNode;
begin
  FLock.Enter;
  try
    while not isEmpty do
    begin
      curNode := lastNode;
      lastNode := curNode^.PrevNode;
      Dispose(curNode);
    end;
    Count := 0;
  finally
    FLock.Leave;
  end;
end;

function TStackNode.GetCount: integer;
begin
  FLock.Enter;
  try
    Result := Count;
  finally
    FLock.Leave;
  end;
end;

function TStackNode.GetCountChickens: integer;
var
  curNode: PNode;
begin
  FLock.Enter;
  try
    Result := 0;
    curNode := lastNode;
    while curNode <> nil do
    begin
      curNode := curNode^.PrevNode;
      Inc(Result);
    end;
  finally
    FLock.Leave;
  end;
end;

function TStackNode.popToStr: string;
begin
  case topType of
    dtInt: Result := IntToStr(popInt);
    dtFloat: Result := FloatToStr(popFloat,fs);
    dtBool: Result := BoolToStr(popBool, 'True', 'False');
    dtStr: Result := '"' + popStr + '"';
    dtPtr: Result := BoolToStr(popPtr <> nil, 'Ptr', 'Nil');
    else
      Result := 'Неизвестный тип';
  end;
end;


end.
