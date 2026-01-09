unit uMyFanStack;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Math;

type
  { tStackFan<TData> — универсальный класс стека с динамическим управлением памятью.

    Особенности:
    - Поддерживает любой тип TData (включая управляемые: строки, интерфейсы).
    - Автоматически расширяет/сжимает внутренний массив.
    - Предоставляет безопасные методы (Try...) без исключений.
    - Позволяет доступ к элементам по индексу (peekAt).

    Пример использования:
    TStackInt = specialize tStackFan<int64>;
  }
  generic tStackFan<TData> = class(TObject)
  private
    FItems: array of TData;
    // Динамический массив для хранения элементов
    FTopIndex: integer;
    // Индекс верхнего элемента (-1 = стек пуст)

    function FastPop: TData; inline;
      { Быстрое извлечение верхнего элемента (без проверок).
        Возвращает: значение элемента.
        Побочный эффект: уменьшает FTopIndex, обнуляет ячейку (Default(TData)). }

    function FastPeek: TData; inline;
      { Быстрое получение верхнего элемента (без изменений стека).
        Возвращает: значение верхнего элемента. }

    function FastPeekAt(const i: integer): TData; inline;
      { Быстрое получение элемента по индексу (без проверок).
        Параметры: i — индекс элемента (0 ≤ i ≤ FTopIndex).
        Возвращает: значение элемента. }

    procedure Compression; inline;
      { Сжимает внутренний массив, если занято <25% ёмкости.
        Условия: длина массива > 32 и FTopIndex + 1 < Length(FItems) div 4.
        Новая длина: max(Length(FItems) div 2, 8). }

  public
    constructor Create;
    { Инициализирует пустой стек (FTopIndex = -1, FItems = пустой массив). }

    destructor Destroy; override;
    { Освобождает ресурсы (вызывает Clear). }

    procedure push(const n: TData);
      { Добавляет элемент в вершину стека.
        Параметры: n — значение для добавления.
        Побочный эффект: при нехватке места удваивает массив (минимум до 8 элементов). }

    function pop: TData;
      { Извлекает и возвращает верхний элемент.
        Возвращает: значение верхнего элемента.
        Исключение: EStackEmpty, если стек пуст.
        Побочный эффект: вызывает Compression после извлечения. }

    function peek: TData;
      { Возвращает верхний элемент без удаления.
        Возвращает: значение верхнего элемента.
        Исключение: EStackEmpty, если стек пуст. }

    function peekAt(const i: integer): TData;
      { Возвращает элемент по индексу i (от 0 до FTopIndex).
        Параметры: i — индекс элемента.
        Возвращает: значение элемента.
        Исключения:
          - EStackEmpty, если стек пуст.
          - EIndexOutOfRange, если i вне диапазона [0..FTopIndex]. }

    function TryPop(out Value: TData): boolean;
      { Безопасное извлечение верхнего элемента.
        Параметры: Value — переменная для результата.
        Возвращает: True, если элемент извлечён; False, если стек пуст.
        Побочный эффект: если успех, Value = элемент, иначе Value = Default(TData). }

    function TryPeek(out Value: TData): boolean;
      { Безопасное получение верхнего элемента.
        Параметры: Value — переменная для результата.
        Возвращает: True, если элемент существует; False, если стек пуст.
        Побочный эффект: если успех, Value = элемент, иначе Value = Default(TData). }

    function TryPeekAt(const i: integer; out Value: TData): boolean;
      { Безопасное получение элемента по индексу.
        Параметры:
          - i — индекс элемента.
          - Value — переменная для результата.
        Возвращает: True, если индекс корректен; False иначе.
        Побочный эффект: если успех, Value = элемент, иначе Value = Default(TData). }

    function getLastIndex: integer;
      { Возвращает индекс верхнего элемента (FTopIndex).
        Возвращает: -1, если стек пуст; иначе — индекс последнего элемента. }

    procedure removeUnnecessaryItems;
      { Урезает внутренний массив до фактического размера (FTopIndex + 1).
        Побочный эффект: SetLength(FItems, FTopIndex + 1). }

    function size: integer;
      { Возвращает количество элементов в стеке.
        Возвращает: FTopIndex + 1 (0, если стек пуст). }

    function isEmpty: boolean;
      { Проверяет, пуст ли стек.
        Возвращает: True, если FTopIndex < 0; иначе False. }

    procedure Clear;
      { Очищает стек:
        - Для управляемых типов (строки, интерфейсы) обнуляет элементы.
        - Сбрасывает FTopIndex = -1.
        - Очищает массив FItems. }

    procedure Reserve(Capacity: integer);
      { Гарантирует минимальную ёмкость внутреннего массива.
        Параметры: Capacity — желаемая длина массива.
        Побочный эффект: если Capacity > Length(FItems), увеличивает массив. }

    function GetCapacity: integer;
      { Возвращает текущую длину внутреннего массива (Length(FItems)).
        Возвращает: количество выделенных ячеек (может быть > size). }
  end;


implementation

function tStackFan.FastPop: TData;
begin
  Result := FItems[FTopIndex];
  FItems[FTopIndex] := Default(TData);
  Dec(FTopIndex);
end;

function tStackFan.FastPeek: TData;
begin
  Result := FItems[FTopIndex];
end;

function tStackFan.FastPeekAt(const i: integer): TData;
begin
  Result := FItems[i];
end;

procedure tStackFan.Compression;
begin
  if (Length(FItems) > 32) and (FTopIndex + 1 < Length(FItems) div 4) then
    SetLength(FItems, Max(Length(FItems) div 2, 8));
end;

constructor tStackFan.Create;
begin
  FTopIndex := -1;
  SetLength(FItems, 0);
end;

destructor tStackFan.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure tStackFan.push(const n: TData);
begin
  Inc(FTopIndex);
  if FTopIndex >= Length(FItems) then
    SetLength(FItems, Max(Length(FItems) * 2, 8));
  FItems[FTopIndex] := n;
end;

function tStackFan.pop: TData;
begin
  if IsEmpty then
    raise Exception.Create('Стек пуст');
  Result := FastPop;

  // Автоматическое сжатие при сильном недозаполнении
  Compression;
end;

function tStackFan.peek: TData;
begin
  if IsEmpty then
    raise Exception.Create('Стек пуст');
  Result := FastPeek;
end;

function tStackFan.peekAt(const i: integer): TData;
const
  tt = 'Индекс %d вне допустимого диапазона [0..%d]';
  tp = 'Стек пуст, невозможно получить элемент';
begin
  // Проверка на пустой стек
  if IsEmpty then
    raise Exception.Create(tp);

  // Проверка диапазона индекса
  if (i < 0) or (i > FTopIndex) then
    raise Exception.CreateFmt(tt, [i, FTopIndex]);

  Result := FastPeekAt(i);
end;

function tStackFan.TryPop(out Value: TData): boolean;
begin
  Result := not isEmpty;
  if Result then
    // Используем существующий FastPop для консистентности
    Value := FastPop
  else
    Value := Default(TData);
  Compression;
end;

function tStackFan.TryPeek(out Value: TData): boolean;
begin
  Result := not isEmpty;
  if Result then
    Value := FastPeek  // Используем существующий Peek
  else
    Value := Default(TData);
end;

function tStackFan.TryPeekAt(const i: integer; out Value: TData): boolean;
begin
  Result := not ((i < 0) or (i > FTopIndex));
  if Result then
    Value := FastPeekAt(i)
  else
    Value := Default(TData);
end;

function tStackFan.getLastIndex: integer;
begin
  Result := FTopIndex;
end;


procedure tStackFan.removeUnnecessaryItems;
begin
  if Length(FItems) > FTopIndex + 1 then
    SetLength(FItems, FTopIndex + 1);
end;

function tStackFan.size: integer;
begin
  Result := FTopIndex + 1;
end;

function tStackFan.isEmpty: boolean;
begin
  Result := FTopIndex < 0; //FTopIndex = -1
end;

procedure tStackFan.Clear;
var
  i: integer;
begin
  // Для строк, интерфейсов и других управляемых типов
  if IsManagedType(TData) then
  begin
    for i := 0 to FTopIndex do
      FItems[i] := Default(TData);
  end;

  FTopIndex := -1;
  SetLength(FItems, 0);
end;

procedure tStackFan.Reserve(Capacity: integer);
begin
  if Capacity > Length(FItems) then
    SetLength(FItems, Capacity);
end;

function tStackFan.GetCapacity: integer;
begin
  Result := Length(FItems);
end;

end.
