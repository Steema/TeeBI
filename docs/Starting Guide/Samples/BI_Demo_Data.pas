unit BI_Demo_Data;

interface

uses
  BI.DataItem;

function CreateDemoData:TDataItem;

implementation

uses
  System.SysUtils;

// Creates and returns a database of two tables: Customers and Orders
// Customers is the "master" of Orders "detail"
function CreateDemoData:TDataItem;
const
  CustomerNames:Array[0..7] of String=('Acme','Cocacola','Dell','Pepsi','Microsoft','adidas','intel','at&t');

var Customers,
    Orders : TDataItem;

    t : Integer;

    tmpDate : TDateTime;
begin
  result:=TDataItem.Create;

  // Customers table:

  Customers:=TDataItem.Create(True);
  Customers.Name:='Customers';
  Customers.Items.Add('ID',TDataKind.dkInt32);
  Customers.Items.Add('Name',TDataKind.dkText);

  // Fill Customers:

  Customers.Resize(Length(CustomerNames));

  for t:=0 to High(CustomerNames) do
  begin
    Customers['ID'].Int32Data[t]:=t;
    Customers['Name'].TextData[t]:=CustomerNames[t];
  end;

  // Add Customers to result:
  result.Items.Add(Customers);

  // Orders

  Orders:=TDataItem.Create(True);
  Orders.Name:='Orders';
  Orders.Items.Add('ID',TDataKind.dkInt32);
  Orders.Items.Add('Quantity',TDataKind.dkInt32);
  Orders.Items.Add('Price',TDataKind.dkSingle);
  Orders.Items.Add('Date',TDataKind.dkDateTime);
  Orders.Items.Add('Customer',TDataKind.dkInt32);

  // Set master-detail:
  Orders['Customer'].Master:=Customers['ID'];

  // Fill Orders:
  Orders.Resize(100);

  tmpDate:=Round(Now);

  for t:=0 to 99 do
  begin
    Orders['ID'].Int32Data[t]:=t;
    Orders['Quantity'].Int32Data[t]:=Random(1000);
    Orders['Price'].SingleData[t]:=Random(1000)*0.01;

    // Set some Date items null (Missing)
    if Random(1000)<250 then
       Orders['Date'].Missing[t]:=True
    else
    begin
      tmpDate:=tmpDate+Random(5);
      Orders['Date'].DateTimeData[t]:=tmpDate;
    end;

    // Random/demo link between Orders and Customers:
    Orders['Customer'].Int32Data[t]:=Random(Customers.Count);

  end;

  // Add Orders to result:
  result.Items.Add(Orders);
end;

end.
