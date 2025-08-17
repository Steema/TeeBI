4## What is a TDataItem ?

```TDataItem``` is a class, a versatile and all-purpose structure.

```delphi
// pseudo-code
uses BI.DataItem;

type
  TDataItem = class
    Items  : Array of TDataItem
    Values : Array of (Integer or String or
                       Boolean or Single or TDateTime)
  end
```

### From plain to advanced data structures:

```delphi
// Basic types
Integer, Single, String, Boolean, TDateTime...

// Simple
Array, TList, TStrings, TCollection, TDictionary...

// Hard-coded
Record, Class

// Database oriented
TDataset

// Multi-dimensional, hierarchical
Array of Array of..., *Generic Tree

// Versatile, N-dimensional, hierarchical
TDataItem
```

[Example project: What can be done with a TDataItem?](https://github.com/Steema/TeeBI/tree/master/docs/Starting%20Guide/Samples)


Fields of a ```TDataItem``` can also be a ```TDataItem```.
This recursivity allows tree structures of any kind, 
for example the traditional:

Database -> Tables -> Fields

can be emulated using ```TDataItem``` children.

TeeBI uses this capability to for example directly display grid columns that contain tables.

A ```TDataItem``` can also be used as a simple one-dimension array.

There are no dependencies other than the Delphi RTL, no dlls, just 100% Pascal code.

* [Generic Tree code](https://github.com/davidberneda/GenericTree)

