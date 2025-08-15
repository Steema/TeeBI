## What is a TDataItem ?

TDataItem is a class, a versatile and all-purpose structure.

```delphi
// pseudo-code
type
  TDataItem = class
    Items : Array of TDataItem
    Values : Array of (Integer or String or Boolean or Single or TDateTime)
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

// Multi-dimensional
Array of Array of...

// Versatile, N-dimensional, hierarchical
TDataItem
```

Fields of a TDataItem can also be a TDataItem, this recursivity allows tree structures of any kind, for example the traditional:

Database -> Tables -> Fields

TeeBI uses this capability to for example directly display grid columns that contain tables.

Anyway, a TDataItem can also be used as a simple one-dimension array.
