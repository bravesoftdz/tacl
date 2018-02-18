{
@abstract(Template collections test)

This is test for template collections

@author(George Bakhtadze (avagames@gmail.com))
}

unit CollectionTest;
{$I g3config.inc}

interface

uses
  tester, {!}template;

type
  _HashMapKeyType = Integer;
  _HashMapValueType = AnsiString;
  {$MESSAGE 'Instantiating TIntStrHashMap interface'}
  {$I tpl_coll_hashmap.inc}
  TIntStrHashMap = class(_GenHashMap) end;
  TIntStrHashMapIterator = object(_GenHashMapIterator) end;

  TKeyArray = array of _HashMapKeyType;

  _VectorValueType = Integer;
  _PVectorValueType = PInteger;
  {$MESSAGE 'Instantiating TIntVector interface'}
  {$I tpl_coll_vector.inc}
  TIntVector = _GenVector;

  // Base class for all template classes tests
  TTestTemplates = class(TTestSuite)
  end;

  TTestCollections = class(TTestTemplates)
  protected
    function ForCollEl(const e: Integer; Data: Pointer): Boolean;
  end;

  TTestHash = class(TTestCollections)
  private
    procedure ForPair(const Key: Integer; const Value: AnsiString; Data: Pointer);
  published
    procedure TestHashMap();
  end;

  TTestVector = class(TTestCollections)
  private
    procedure TestList(Coll: TIntVector);
  published
    procedure TestVector();
  end;

implementation

uses
  SysUtils,
  g3common;

  const _HashMapOptions = [];
  {$MESSAGE 'Instantiating TIntStrHashMap'}
  {$I tpl_coll_hashmap.inc}

  const _VectorOptions = [];
  {$MESSAGE 'Instantiating TIntVector'}
  {$I tpl_coll_vector.inc}

var
  Rnd: TRandomGenerator;

const
  TESTCOUNT = 1024*8*4;//*256;//*1000*10;
  HashMapElCnt = 1024*8;
  CollElCnt = 1024*8;

{ TTestCollections }

function TTestCollections.ForCollEl(const e: Integer; Data: Pointer): Boolean;
begin
  Assert(_Check(e = Rnd.RndI(CollElCnt)), 'Value check in for each fail');
  Result := True;
end;

{ TTestHash }

procedure TTestHash.ForPair(const Key: Integer; const Value: AnsiString; Data: Pointer);
begin
//  Writeln(Key, ' = ', Value);
  Assert(_Check((Key) = StrToInt(Value)), 'Value check in for each fail');
end;

procedure TTestHash.TestHashMap;
var
  i: Integer;
  cnt, t: NativeInt;
  Map: TIntStrHashMap;
  Iter: _GenHashMapIterator;
begin
  Map := TIntStrHashMap.Create(1);

  cnt := 0;
  for i := 0 to HashMapElCnt-1 do
  begin
    t := Random(HashMapElCnt);
    if not Map.Contains(t) then Inc(cnt);
    Map[t] := IntToStr(t);
    Assert(_Check(Map.Contains(t) and Map.ContainsValue(IntToStr(t))));
  end;
  Map.ForEach(ForPair, nil);

  Assert(_Check(Map.Count = cnt), 'Wrong count after put');

  for i := 0 to HashMapElCnt-1 do
  begin
    t := Random(HashMapElCnt);
    if Map.Remove(t) then Dec(cnt);
  end;
  Assert(_Check(Map.Count = cnt), 'Wrong count after remove');

  Iter := Map.GetIterator();
//  Log('Iterator count: ' + IntToStr(Map.Count));
  for i := 0 to Map.Count-1 do
  begin
    Assert(_Check(Iter.HasNext), 'iterator HasNext() failed');
    t := Iter.Next.Key;
    Assert(_Check(Map.Contains(t)), 'iterator value not found');
    //Log('Iterator next: ' + IntToStr(t));
  end;

  Assert(_Check(not Iter.HasNext), 'iterator HasNext() false positive');

  Map.Clear;
  Assert(_Check(Map.IsEmpty));

  Map[t] := IntToStr(t);
  Assert(_Check(Map.Contains(t) and Map.ContainsValue(IntToStr(t))));

  Map.Free;
end;

{ TTestVector }
procedure TTestVector.TestList(Coll: TIntVector);
var
  i, cnt, t: Integer;
  ValuePtr: PInteger;
begin
  cnt := 0;
  Rnd.InitSequence(1, 0);
  for i := 0 to CollElCnt-1 do
  begin
    t := Rnd.RndI(CollElCnt);
    Coll.Add(t);
    Inc(cnt);
    ValuePtr := Coll.GetPtr(i);
    Assert(_Check(Coll.Get(i) = ValuePtr^), GetName + ': GetPtr failed');
    Assert(_Check(Coll.Contains(t)), GetName + ': Contains failed');
  end;

  Rnd.InitSequence(1, 0);
  Coll.ForEach(ForCollEl, nil);

  for i := 0 to CollElCnt div 2-1 do
  begin
    t := Rnd.RndI(CollElCnt);
    while Coll.Remove(t) do Dec(cnt);
    Assert(_Check(not Coll.Contains(t)), GetName + ': Not conntains failed');
  end;

  for i := 0 to CollElCnt div 2-1 do
  begin
    t := Rnd.RndI(Coll.Count);
    Coll.Put(i, CollElCnt);
    Assert(_Check(Coll.Get(i) = CollElCnt), GetName + ': Put/Get failed');
    Coll.Insert(t, CollElCnt+1);
    Assert(_Check((Coll.Get(t) = CollElCnt+1) and Coll.Contains(CollElCnt+1)),
           GetName + ': Conntains inserted failed');
    Coll.RemoveBy(t);
    Assert(_Check(not Coll.Contains(CollElCnt+1)), GetName + ': Not contains removed failed');
  end;

  Assert(_Check(Coll.Count = cnt), GetName + ': Count failed');

  Coll.Clear;
  Assert(_Check(Coll.IsEmpty()), GetName + ': IsEmpty failed');
  Coll.Free;
end;

procedure TTestVector.TestVector;
var Coll: TIntVector;
begin
  Coll := TIntVector.Create();
  TestList(Coll);
end;

initialization
  Rnd := TRandomGenerator.Create();
  RegisterSuites([TTestCollections, TTestHash, TTestVector]);
finalization  
  Rnd.Free();
end.
