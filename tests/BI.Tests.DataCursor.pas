unit BI.Tests.DataCursor;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TDataCursor_Test=class(TObject)
  strict private
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestFilter;

    [Test]
    procedure TestSort;
  end;

implementation

uses
  BI.Arrays, BI.DataItem, BI.DataSource,
  BI.Tests.SummarySamples, BI.Expressions;

procedure TDataCursor_Test.Setup;
begin
end;

procedure TDataCursor_Test.TearDown;
begin
end;

procedure TDataCursor_Test.TestFilter;
var Cursor : TDataCursor;
    _Result : TDataItem;
begin
  Cursor:=TDataCursor.Create(nil);
  try
    Cursor.Clear; // optional
    Cursor.Data:=Samples.Customers;

    Cursor.Filter:=TDataFilter.FromString(Cursor.Data,'Country<>"Mexico"');

    _Result:=Cursor.ToData;

    Assert.IsNotNull(_Result);
    Assert.AreEqual<Int64>(Cursor.Data.Count,91);
    Assert.AreEqual<Int64>(_Result.Count,86);  // 5 are from Mexico
  finally
    Cursor.Free;
  end;
end;

procedure TDataCursor_Test.TestSort;
var Cursor : TDataCursor;
    _Result : TDataItem;
    Country : TTextArray;
begin
  Cursor:=TDataCursor.Create(nil);
  try
    Cursor.Clear; // optional
    Cursor.Data:=Samples.Customers;

    Cursor.SortBy.Add(Cursor.Data['Country'],False); // Descending

    _Result:=Cursor.ToData;

    Assert.IsNotNull(_Result);
    Assert.AreEqual<Int64>(Cursor.Data.Count,91);
    Assert.AreEqual<Int64>(_Result.Count,91);

    Country:=_Result['Country'].TextData;

    // In descending order
    Assert.AreEqual(Country[0],'Venezuela');
    Assert.AreEqual(Country[90],'Argentina');
  finally
    Cursor.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TDataCursor_Test);
end.
