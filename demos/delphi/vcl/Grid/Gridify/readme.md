## TGridify algorithm

Convert any flat table to a pivot-grid.


![](https://raw.github.com/Steema/BI/master/docs/img/TeeBI_Gridify_colored.png)

This example also shows how to fill cells using colors from "ranks" (the order of a column value in its group).

Ranquings are calculated using the ```TDataRank``` class.

The ```TGridify``` class is used to create the right-side table from the left-side one.


```delphi
BIGrid2.Data := TGridify.From(BIGrid1.Data,'Rank','Year','Person');
```
