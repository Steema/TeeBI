{*********************************************}
{  TeeBI Software Library                     }
{  TDataItem Kind Conversion                  }
{  Copyright (c) 2015-2025 by Steema Software }
{  All Rights Reserved                        }
{*********************************************}
unit BI.Convert;

interface

uses
  BI.DataItem;

type
{
  Use TDataKindConvert.Convert method to change the "Kind" property of a
  TDataItem object.

  For example to convert Integers to Doubles, or Text to numbers, etc.

  All data is preserved and checked for compatibility with the new Kind.
  All "Missing" data values are also preserved (not converted).

  Note:
    TDataItem AsTable (multiple fields) cannot be converted.
    All Items must be converted individually.
}
  TDataKindConvert=record
  public
    class function CanConvert(const AData:TDataItem; const AKind:TDataKind):Boolean; static;
    class function Convert(const AData:TDataItem; const AKind:TDataKind):Boolean; static;
  end;

{
  Use TDateTimeConvert methods to convert from a single DateTime data item to a
  structure of sub-items (Day,Month,Year, etc), and vice-versa: from a structure
  to a single TDataItem.
}
  TDateTimeConvert=record
  public
    class function ToTable(const AData:TDataItem):TDataItem; static;
    class function ToDateTime(const AData:TDataItem):TDataItem; static;
  end;

implementation

uses
  BI.Arrays,
  {System.}SysUtils, {System.}Math, {System.}DateUtils;

{$IFDEF FPC}
{$IFNDEF CPUX64}
{$DEFINE HASEXTENDED}
{$ENDIF}
{$ELSE}
{$DEFINE HASEXTENDED}
{$ENDIF}

{ TDataKindConvert }

type
  TDataItemAccess=class(TDataItem);
  TDataItemsAccess=class(TDataItems);

class function TDataKindConvert.Convert(const AData: TDataItem;
  const AKind: TDataKind): Boolean;

  procedure DoEmpty;
  begin
    case AData.Kind of
        dkInt32: AData.Int32Data.Empty;
        dkInt64: AData.Int64Data.Empty;
       dkSingle: AData.SingleData.Empty;
       dkDouble: AData.DoubleData.Empty;
     dkExtended: AData.ExtendedData.Empty;
         dkText: AData.TextData.Empty;
     dkDateTime: AData.DateTimeData.Empty;
      dkBoolean: AData.BooleanData.Empty;
      dkUnknown: ;
    end;
  end;

  procedure CopyData(const ASource:TDataItem);
  begin
    case ASource.Kind of
        dkInt32: AData.Int32Data:=ASource.Int32Data;
        dkInt64: AData.Int64Data:=ASource.Int64Data;
       dkSingle: AData.SingleData:=ASource.SingleData;
       dkDouble: AData.DoubleData:=ASource.DoubleData;
     dkExtended: AData.ExtendedData:=ASource.ExtendedData;
         dkText: AData.TextData:=ASource.TextData;
     dkDateTime: AData.DateTimeData:=ASource.DateTimeData;
      dkBoolean: AData.BooleanData:=ASource.BooleanData;
      dkUnknown: ;
    end;
  end;

var
  tmp : TDataItem;

  procedure SetValue(const AIndex:TLoopInteger; const Value:Int32); overload;
  begin
    case AKind of
      dkInt32: ;
      dkInt64: tmp.Int64Data[AIndex]:=Value;
     dkSingle: tmp.SingleData[AIndex]:=Value;
     dkDouble: tmp.DoubleData[AIndex]:=Value;
   dkExtended: tmp.ExtendedData[AIndex]:=Value;
       dkText: tmp.TextData[AIndex]:=IntToStr(Value);
   dkDateTime: tmp.DateTimeData[AIndex]:=Value;
    dkBoolean: tmp.BooleanData[AIndex]:=(Value<>0);
    dkUnknown: ;
    end;
  end;

  procedure SetValue(const AIndex:TLoopInteger; const Value:Int64); overload;
  begin
    case AKind of
      dkInt32: tmp.Int32Data[AIndex]:=Value;
      dkInt64: ;
     dkSingle: tmp.SingleData[AIndex]:=Value;
     dkDouble: tmp.DoubleData[AIndex]:=Value;
   dkExtended: tmp.ExtendedData[AIndex]:=Value;
       dkText: tmp.TextData[AIndex]:=IntToStr(Value);
   dkDateTime: tmp.DateTimeData[AIndex]:=Value;
    dkBoolean: tmp.BooleanData[AIndex]:=(Value<>0);
    dkUnknown: ;
    end;
  end;

  procedure SetValue(const AIndex:TLoopInteger; const Value:Single); overload;
  begin
    case AKind of
      dkInt32: tmp.Int32Data[AIndex]:=Round(Value);
      dkInt64: tmp.Int64Data[AIndex]:=Round(Value);
     dkSingle: ;
     dkDouble: tmp.DoubleData[AIndex]:=Value;
   dkExtended: tmp.ExtendedData[AIndex]:=Value;
       dkText: tmp.TextData[AIndex]:=FloatToStr(Value);
   dkDateTime: tmp.DateTimeData[AIndex]:=Value;
    dkBoolean: tmp.BooleanData[AIndex]:=(Value<>0); // Epsilon !
    dkUnknown: ;
    end;
  end;

  procedure SetValue(const AIndex:TLoopInteger; const Value:Double); overload;
  begin
    case AKind of
      dkInt32: tmp.Int32Data[AIndex]:=Round(Value);
      dkInt64: tmp.Int64Data[AIndex]:=Round(Value);
     dkSingle: tmp.SingleData[AIndex]:=Value;
     dkDouble: ;
   dkExtended: tmp.ExtendedData[AIndex]:=Value;
       dkText: tmp.TextData[AIndex]:=FloatToStr(Value);
   dkDateTime: tmp.DateTimeData[AIndex]:=Value;
    dkBoolean: tmp.BooleanData[AIndex]:=(Value<>0);
    dkUnknown: ;
    end;
  end;

  {$IFDEF HASEXTENDED}
  procedure SetValue(const AIndex:TLoopInteger; const Value:Extended); overload;
  begin
    case AKind of
      dkInt32: tmp.Int32Data[AIndex]:=Round(Value);
      dkInt64: tmp.Int64Data[AIndex]:=Round(Value);
     dkSingle: tmp.SingleData[AIndex]:=Value;
     dkDouble: tmp.DoubleData[AIndex]:=Value;
   dkExtended: ;
       dkText: tmp.TextData[AIndex]:=FloatToStr(Value);
   dkDateTime: tmp.DateTimeData[AIndex]:=Value;
    dkBoolean: tmp.BooleanData[AIndex]:=(Value<>0);
    dkUnknown: ;
    end;
  end;
  {$ENDIF}

  procedure SetValue(const AIndex:TLoopInteger; const Value:TDateTime); overload;
  begin
    case AKind of
      dkInt32: tmp.Int32Data[AIndex]:=Round(Value);
      dkInt64: tmp.Int64Data[AIndex]:=Round(Value);
     dkSingle: tmp.SingleData[AIndex]:=Value;
     dkDouble: tmp.DoubleData[AIndex]:=Value;
   dkExtended: tmp.ExtendedData[AIndex]:=Value;
       dkText: tmp.TextData[AIndex]:=DateTimeToStr(Value);
   dkDateTime: ;
    dkBoolean: tmp.BooleanData[AIndex]:=(Value<>0);
    dkUnknown: ;
    end;
  end;

  procedure SetValue(const AIndex:TLoopInteger; const Value:Boolean); overload;
  var tmpBool : Integer;
  begin
    tmpBool:=Ord(Value);

    case AKind of
       dkText: tmp.TextData[AIndex]:=BoolToStr(Value,True);
      dkInt32: tmp.Int32Data[AIndex]:=tmpBool;
      dkInt64: tmp.Int64Data[AIndex]:=tmpBool;
     dkSingle: tmp.SingleData[AIndex]:=tmpBool;
     dkDouble: tmp.DoubleData[AIndex]:=tmpBool;
   dkExtended: tmp.ExtendedData[AIndex]:=tmpBool;
   dkDateTime: tmp.DateTimeData[AIndex]:=tmpBool;
    dkBoolean: ;
    dkUnknown: ;
   end;
  end;

  procedure SetValue(const AIndex:TLoopInteger; const Value:String); overload;
  begin
    case AKind of
      dkInt32: tmp.Int32Data[AIndex]:=StrToInt(Value);
      dkInt64: tmp.Int64Data[AIndex]:=StrToInt64(Value);
     dkSingle: tmp.SingleData[AIndex]:=StrToFloat(Value);
     dkDouble: tmp.DoubleData[AIndex]:=StrToFloat(Value);
   dkExtended: tmp.ExtendedData[AIndex]:=StrToFloat(Value);
   dkDateTime: tmp.DateTimeData[AIndex]:=StrToDateTime(Value);
    dkBoolean: tmp.BooleanData[AIndex]:=StrToBool(Value);
    else
      result:=True;
    end;
  end;

  procedure ConvertAllData;
  var t : TLoopInteger;
  begin
    tmp.Resize(AData.Count);

    for t:=0 to AData.Count-1 do
    if not AData.Missing[t] then
    begin
      case AData.Kind of
        dkInt32: SetValue(t,AData.Int32Data[t]);
        dkInt64: SetValue(t,AData.Int64Data[t]);
       dkSingle: SetValue(t,AData.SingleData[t]);
       dkDouble: SetValue(t,AData.DoubleData[t]);
     dkExtended: SetValue(t,AData.ExtendedData[t]);
         dkText: SetValue(t,AData.TextData[t]);
     dkDateTime: SetValue(t,AData.DateTimeData[t]);
      dkBoolean: SetValue(t,AData.BooleanData[t]);
      end;
    end;
  end;

begin
  if AData.Kind=AKind then
     result:=True // same Kind, do nothing
  else
  if CanConvert(AData,AKind) then
  begin
    AData.Load;

    tmp:=TDataItem.Create(AKind);
    try
      ConvertAllData;

      // Direct array copy (new data->old data)
      CopyData(tmp);

      // Clear old kind array
      DoEmpty;

      // Set new Kind array
      TDataItemAccess(AData).FKind:=AKind;

      // Ensure Stats are recreated
      AData.ReCalculate;

      result:=True;

      if AData.Parent<>nil then
         TDataItemsAccess(AData.Parent.Items).DoChanged;

    finally
      // Prevent new data clear at tmp.Free
      TDataItemAccess(tmp).FKind:=TDataKind.dkUnknown;

      tmp.Free;
    end;
  end;
end;

class function TDataKindConvert.CanConvert(const AData:TDataItem; const AKind:TDataKind):Boolean;

  function AllDateTimeInt32:Boolean;
  var t : TLoopInteger;
      tmp : Int32;
  begin
    for t:=0 to AData.Count-1 do
        if not AData.Missing[t] then
        begin
          tmp:=Trunc(AData.DateTimeData[t]);

          if tmp<>AData.DateTimeData[t] then
             Exit(False);
        end;

    result:=True;
  end;

  function AllDateTimeInt64:Boolean;
  var t : TLoopInteger;
      tmp : Int64;
  begin
    for t:=0 to AData.Count-1 do
        if not AData.Missing[t] then
        begin
          tmp:=Trunc(AData.DateTimeData[t]);

          if tmp<>AData.DateTimeData[t] then
             Exit(False);
        end;

    result:=True;
  end;

  function In32BitBounds(const Value:Int64):Boolean; overload; inline;
  const
    MinInt32=-2147483648;
    MaxInt32=+2147483647;
  begin
    result:=(Value>=MinInt32) and (Value<=MaxInt32);
  end;

  function In32BitBounds(const Value:Single):Boolean; overload; inline;
  var tmp : Int64;
  begin
    tmp:=Trunc(Value);
    result:=(tmp=Value) and In32BitBounds(tmp);
  end;

  function In64BitBounds(const Value:Single):Boolean; overload; inline;
  begin
    result:=(Trunc(Value)=Value);
  end;

  function InSingleBounds(const Value:Double):Boolean; overload; inline;
  begin
    result:=(Value>=MinSingle) and (Value<=MaxSingle);
  end;

  {$IFDEF HASEXTENDED}
  function InSingleBounds(const Value:Extended):Boolean; overload; inline;
  begin
    result:=(Value>=MinSingle) and (Value<=MaxSingle);
  end;
  {$ENDIF}

  function InDoubleBounds(const Value:Extended):Boolean; overload; inline;
  begin
    result:=(Value>=MinDouble) and (Value<=MaxDouble);
  end;

  function AllInt64AreAlso32:Boolean;
  var t : TLoopInteger;
  begin
    for t:=0 to AData.Count-1 do
        if not AData.Missing[t] then
           if not In32BitBounds(AData.Int64Data[t]) then
              Exit(False);

    result:=True;
  end;

  function AllZeroOrOne(const Values:TInt32Array):Boolean; overload;
  var t : TLoopInteger;
      tmp : Int32;
  begin
    for t:=0 to AData.Count-1 do
        if not AData.Missing[t] then
        begin
          tmp:=Values[t];

           if (tmp<>0) and (tmp<>1) then
              Exit(False);
        end;

    result:=True;
  end;

  function AllZeroOrOne(const Values:TInt64Array):Boolean; overload;
  var t : TLoopInteger;
      tmp : Int64;
  begin
    for t:=0 to AData.Count-1 do
        if not AData.Missing[t] then
        begin
          tmp:=Values[t];

           if (tmp<>0) and (tmp<>1) then
              Exit(False);
        end;

    result:=True;
  end;

  function AllZeroOrOne(const Values:TSingleArray):Boolean; overload;
  var t : TLoopInteger;
      tmp : Single;
  begin
    for t:=0 to AData.Count-1 do
        if not AData.Missing[t] then
        begin
          tmp:=Values[t];

           if (tmp<>0) and (tmp<>1) then
              Exit(False);
        end;

    result:=True;
  end;

  function AllZeroOrOne(const Values:TDoubleArray):Boolean; overload;
  var t : TLoopInteger;
      tmp : Double;
  begin
    for t:=0 to AData.Count-1 do
        if not AData.Missing[t] then
        begin
          tmp:=Values[t];

           if (tmp<>0) and (tmp<>1) then
              Exit(False);
        end;

    result:=True;
  end;

  {$IFDEF CPUX86}
  function AllZeroOrOne(const Values:TExtendedArray):Boolean; overload;
  var t : TLoopInteger;
      tmp : Extended;
  begin
    for t:=0 to AData.Count-1 do
        if not AData.Missing[t] then
        begin
          tmp:=Values[t];

           if (tmp<>0) and (tmp<>1) then
              Exit(False);
        end;

    result:=True;
  end;
  {$ENDIF}

  function CompatibleDateTime:Boolean;
  begin
    case AKind of
      dkInt32: result:=AllDateTimeInt32;
      dkInt64: result:=AllDateTimeInt64;
      dkSingle,
      dkDouble,
      dkExtended,
      dkText : result:=True;
    else
      result:=False;
    end;
  end;

  function CompatibleSingle:Boolean;
  var t : TLoopInteger;
      tmp : Single;
  begin
    result:=(AKind=TDataKind.dkDouble) or
            (AKind=TDataKind.dkExtended) or
            (AKind=TDataKind.dkDateTime) or
            (AKind=TDataKind.dkText);

    if not result then
    begin
      for t:=0 to AData.Count-1 do
          if not AData.Missing[t] then
          begin
            tmp:=AData.SingleData[t];

            case AKind of
               dkInt32: if not In32BitBounds(tmp) then Exit(False);
               dkInt64: if not In64BitBounds(tmp) then Exit(False);
             end;
          end;

      result:=True;
    end;
  end;

  function CompatibleDouble:Boolean;
  var t : TLoopInteger;
      tmp : Double;
  begin
    result:=(AKind=TDataKind.dkExtended) or
            (AKind=TDataKind.dkDateTime) or
            (AKind=TDataKind.dkText);

    if not result then
    begin
      for t:=0 to AData.Count-1 do
          if not AData.Missing[t] then
          begin
            tmp:=AData.DoubleData[t];

            case AKind of
               dkInt32: if not In32BitBounds(tmp) then Exit(False);
               dkInt64: if not In64BitBounds(tmp) then Exit(False);
              dkSingle: if not InSingleBounds(tmp) then Exit(False);
             end;
          end;

      result:=True;
    end;
  end;

  function CompatibleExtended:Boolean;
  var t : TLoopInteger;
      tmp : Extended;
  begin
    result:=(AKind=TDataKind.dkText);

    if not result then
    begin
      for t:=0 to AData.Count-1 do
          if not AData.Missing[t] then
          begin
            tmp:=AData.ExtendedData[t];

            case AKind of
               dkInt32: if not In32BitBounds(tmp) then Exit(False);
               dkInt64: if not In64BitBounds(tmp) then Exit(False);
              dkSingle: if not InSingleBounds(tmp) then Exit(False);
              dkDouble,
            dkDateTime: if not InDoubleBounds(tmp) then Exit(False);
             end;
          end;

      result:=True;
    end;
  end;

  function StringToValue(const Value:String):Boolean; overload;
  var tmpInt32 : Integer;
      tmpInt64 : Int64;
      tmpSingle : Single;
      tmpDouble : Double;
      tmpExtended : Extended;
      tmpDate : TDateTime;
      tmpBool : Boolean;
  begin
    case AKind of
      dkInt32: result:=TryStrToInt(Value,tmpInt32);
      dkInt64: result:=TryStrToInt64(Value,tmpInt64);
     dkSingle: result:=TryStrToFloat(Value,tmpSingle);
     dkDouble: result:=TryStrToFloat(Value,tmpDouble);
   dkExtended: result:=TryStrToFloat(Value,tmpExtended);
   dkDateTime: result:=TryStrToDateTime(Value,tmpDate);
    dkBoolean: result:=TryStrToBool(Value,tmpBool);
    else
      result:=True;
    end;
  end;

  function CanStringToValue:Boolean;
  var t : TLoopInteger;
  begin
    for t:=0 to AData.Count-1 do
        if not AData.Missing[t] then
           if not StringToValue(AData.TextData[t]) then
              Exit(False);

    result:=True;
  end;

begin
  if AKind=TDataKind.dkUnknown then
     result:=False
  else
  if AData.Missing.All then
     result:=True
  else
  case AData.Kind of
      dkInt32: result:=(AKind<>TDataKind.dkBoolean) or AllZeroOrOne(AData.Int32Data);

      dkInt64: if AKind=TDataKind.dkBoolean then
                  result:=AllZeroOrOne(AData.Int64Data)
               else
               if AKind=TDataKind.dkInt32 then
                  result:=AllInt64AreAlso32
               else
                  result:=True;

     dkSingle: if AKind=TDataKind.dkBoolean then
                  result:=AllZeroOrOne(AData.SingleData)
               else
                  result:=CompatibleSingle;

     dkDouble: if AKind=TDataKind.dkBoolean then
                  result:=AllZeroOrOne(AData.DoubleData)
               else
                  result:=CompatibleDouble;

   dkExtended: if AKind=TDataKind.dkBoolean then
                  result:=AllZeroOrOne(AData.ExtendedData)
               else
                  result:=CompatibleExtended;

       dkText: result:=CanStringToValue;
   dkDateTime: result:=CompatibleDateTime;
    dkBoolean: result:=AKind<>TDataKind.dkUnknown;
  else
    result:=AKind=TDataKind.dkUnknown;
  end;
end;

{ TDateTimeConvert }

const
  stDay    = 'Day';
  stMonth  = 'Month';
  stYear   = 'Year';
  stHour   = 'Hour';
  stMinute = 'Minute';
  stSecond = 'Second';
  stMillisecond = 'Millisecond';

// Returns a TDataItem of DateTime kind and fills it with the datetime
// values from the Day,Month,Year,Hour,Minute,Second and Millisecond item structure.
class function TDateTimeConvert.ToDateTime(const AData: TDataItem): TDataItem;

  procedure DoError(const AMessage:String); {$IFNDEF FPC}{$IF CompilerVersion>=37}noreturn;{$ENDIF}{$ENDIF}
  begin
    raise EBIException.Create(AMessage);
  end;

var
  _day, _month, _year,
  _hour, _minute, _second, _millisecond : TDataItem;

  procedure DoTime(const AIndex:Integer);
  var msec : Word;
  begin
    if _millisecond=nil then
       msec:=0
    else
       msec:=_millisecond.Int32Data[AIndex];

    result.DateTimeData[AIndex]:=
       EncodeTime(_hour.Int32Data[AIndex],
                  _minute.Int32Data[AIndex],
                  _second.Int32Data[AIndex],
                  msec);
  end;

  procedure DoDate(const AIndex:Integer);
  begin
    result.DateTimeData[AIndex]:=
       EncodeDate(_year.Int32Data[AIndex],
                  _month.Int32Data[AIndex],
                  _day.Int32Data[AIndex]);
  end;

  procedure DoDateTime(const AIndex:Integer);
  var msec : Word;
  begin
    if _millisecond=nil then
       msec:=0
    else
       msec:=_millisecond.Int32Data[AIndex];

    result.DateTimeData[AIndex]:=
       EncodeDateTime(_year.Int32Data[AIndex],
                  _month.Int32Data[AIndex],
                  _day.Int32Data[AIndex],
                  _hour.Int32Data[AIndex],
                  _minute.Int32Data[AIndex],
                  _second.Int32Data[AIndex],
                  msec);
  end;

var tmp : String;
    hasDate,
    hasTime : Boolean;

    t : TLoopInteger;
begin
  if AData.AsTable then
  begin
    _day:=AData.Items.Find(stDay);
    _month:=AData.Items.Find(stMonth);
    _year:=AData.Items.Find(stYear);

    hasDate:=(_day<>nil) and
             (_month<>nil) and
             (_year<>nil);

    _hour:=AData.Items.Find(stHour);
    _minute:=AData.Items.Find(stMinute);
    _second:=AData.Items.Find(stSecond);
    _millisecond:=AData.Items.Find(stMillisecond);

    hasTime:=(_hour<>nil) and
             (_minute<>nil) and
             (_second<>nil);

    if (not hasDate) and (not hasTime) then
       DoError('Data items must contain either date (Day,Month,Year), time (Hour,Minute,Second and optional Millisecond) or both items');

    tmp:=AData.Name;

    if tmp='' then
       if hasDate then
          if hasTime then
             tmp:='DateTime'
          else
             tmp:='Date'
       else
       if hasTime then
          tmp:='Time';

    result:=TDataItem.Create(TDataKind.dkDateTime,tmp);

    result.Resize(AData.Count);

    for t:=0 to AData.Count-1 do
    begin
      if hasDate then
         if hasTime then
            DoDateTime(t)
         else
            DoDate(t)
      else
        DoTime(t);
    end;
  end
  else
    DoError('Data must be a table with Day,Month,Year and optionally Hour,Minute,Second (and Millisecond)');
end;

// Returns a table (with Day,Month,Year,Hour,Minute,Second and Millisecond items),
// and fills it with values from AData (which must be of DateTime kind)
class function TDateTimeConvert.ToTable(const AData: TDataItem): TDataItem;
var day,month,year,
    hour,minute,second,millisecond : TDataItem;

    t : TLoopInteger;
    tmp : TDateTime;

    d,m,y,h,mm,s,msec : Word;
begin
  if AData.Kind=TDataKind.dkDateTime then
  begin
    result:=TDataItem.Create(True);

    day:=result.Items.Add('Day',TDataKind.dkInt32);
    month:=result.Items.Add('Month',TDataKind.dkInt32);
    year:=result.Items.Add('Year',TDataKind.dkInt32);
    hour:=result.Items.Add('Hour',TDataKind.dkInt32);
    minute:=result.Items.Add('Minute',TDataKind.dkInt32);
    second:=result.Items.Add('Second',TDataKind.dkInt32);
    millisecond:=result.Items.Add('Millisecond',TDataKind.dkInt32);

    result.Resize(AData.Count);

    for t:=0 to AData.Count-1 do
    begin
      tmp:=AData.DateTimeData[t];

      DecodeDate(tmp,y,m,d);
      DecodeTime(tmp,h,mm,s,msec);

      year.Int32Data[t]:=y;
      month.Int32Data[t]:=m;
      day.Int32Data[t]:=d;
      hour.Int32Data[t]:=h;
      minute.Int32Data[t]:=mm;
      second.Int32Data[t]:=s;
      millisecond.Int32Data[t]:=msec;
    end;
  end
  else
    raise EBIException.Create('Data Kind must be DateTime');
end;

end.
