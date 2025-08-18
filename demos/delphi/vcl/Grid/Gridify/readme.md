## TGridify algorithm

Convert any flat table to a pivot-grid.

The ```TGridify``` class is used to create the right-side table from the left-side one.


```delphi
BIGrid2.Data := TGridify.From(BIGrid1.Data,'Rank','Year','Person');
```

This example also shows how to fill cells using colors from "ranks" (the order of a column value in its group).

Ranquings are first calculated using the ```TDataRank``` class and added to a new "Rank" column in the left-side table.

And then that ranquing values are used to calculate the colors to fill the right-side table cells.

![](https://raw.github.com/Steema/BI/master/docs/img/TeeBI_Gridify_colored.png)

