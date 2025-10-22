## TDateTimeConvert example

Use TDateTimeConvert methods to convert from a single DateTime data item to a
structure of sub-items (Day,Month,Year, etc), and vice-versa: from a structure
to a single TDataItem.

```delphi
uses BI.DataItem, BI.Convert;

var
  DateTimeColumn,
  DateTimeTable : TDataItem;

// Create single column
DateTimeColumn:=TDataItem.Create(TDataKind.dkDateTime,'DateTime');

// Show in left Grid
BIGrid1.Data:=DateTimeColumn;

// Convert the single column to a table:
DateTimeTable:=TDateTimeConvert.ToTable(DateTimeColumn);

// Show it at right Grid
BIGrid2.Data:=DateTimeTable;
```
  

<img width="1263" height="971" alt="image" src="https://github.com/user-attachments/assets/d7adf1be-63c4-4b97-9beb-934dd9a95716" />
