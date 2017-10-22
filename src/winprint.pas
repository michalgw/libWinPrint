{ libWinPrint

  Copyright (C) 2017 Michał Gawrycki

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}


unit winprint;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  WP_PO_PORTRAIT = 1;
  WP_PO_LANDSCAPE = 2;

  WP_CP437 = 0;
  WP_CP620 = 1;
  WP_CP708 = 2;
  WP_CP720 = 3;
  WP_CP737 = 4;
  WP_CP775 = 5;
  WP_CP790 = 6;
  WP_CP850 = 7;
  WP_CP852 = 8;
  WP_CP855 = 9;
  WP_CP857 = 10;
  WP_CP862 = 11;
  WP_CP865 = 12;
  WP_CP866 = 13;
  WP_CP869 = 14;
  WP_CP874 = 15;
  WP_CP932 = 16;
  WP_CP936 = 17;
  WP_CP949 = 18;
  WP_CP950 = 19;
  WP_CP1250 = 20;
  WP_CP1251 = 21;
  WP_CP1252 = 22;
  WP_CP1253 = 23;
  WP_CP1254 = 24;
  WP_CP1255 = 25;
  WP_CP1256 = 26;
  WP_CP1257 = 27;
  WP_CP1258 = 28;
  WP_CP20866 = 29;
  WP_CP21866 = 30;
  WP_CP28591 = 31;
  WP_CP28592 = 32;
  WP_CP28593 = 33;
  WP_CP28594 = 34;
  WP_CP28595 = 35;
  WP_CP28596 = 36;
  WP_CP28597 = 37;
  WP_CP28598 = 38;
  WP_CP28599 = 39;
  WP_CP65000 = 40;
  WP_CP65001 = 41;

function winPrint_Print(ADataToPrint: PChar; APrinterName: PChar; ACopies: Integer;
  AOrientation: Integer; AFontName: PChar; AFontSize: Integer; AMarginL, AMarginR, AMarginT, AMarginB: Double;
  ALinesPerInch: Integer; ALinesPerPage: Integer; ATitle: PChar; ACodePage: Integer): Integer; stdcall;

function winPrint_PrinterSetupDlg(ADrukarka: PChar): Integer; stdcall;

implementation

uses
  ConversionUnit, Graphics, Printers, PrintStringsUnit, Dialogs,
  PrintersDlgs;

var
  PrintFont: TFont = nil;
  SL: TStringList = nil;

function winPrint_PrinterSetupDlg(ADrukarka: PChar): Integer; stdcall;
var
  PSD: TPrinterSetupDialog;
  I: Integer;
begin
  Result := 0;
  I := Printer.Printers.IndexOf(ADrukarka);
  if I >= 0 then
  begin
    Printer.PrinterIndex := I;
    PSD := TPrinterSetupDialog.Create(nil);
    PSD.Execute;
    PSD.Free;
    Result := 1;
  end;
end;

procedure ReadANDConvert2(CodePage: TCodePage;  //CodePage index
                            InputData: RawByteString;     //input file
                              var SL: TStringList;//output strings
            UseCustomConversionTable: boolean;
                     ConversionItems: TConversionItems);
var
  FS: TStringStream;
  Buffer, BR: RawByteString;
  Count,i: integer;
  SS: TStringStream;
  XLATTable: array[char] of char;
  UTF8Table: array[char] of string;

  ci: TConversionItem;
begin
  for i:=0 to 255 do XLATTable[char(i)]:=char(i);
  if (CodePageInfo[CodePage].CpNr=65001)
        and (CodePageInfo[CodePage].UTF8<>nil)then begin
     for i:=0 to 127 do UTF8Table[char(i)]:=char(i);
     for i:=128 to 255 do UTF8Table[char(i)]:=CodePageInfo[CodePage].UTF8^[i];
  end;
  if UseCustomConversionTable then begin
    Count:=ConversionItems.Count;
    if Count>0 then
       for i:=0 to Count-1 do begin
         ci:=ConversionItems.Items[i];
         if ci<>nil then XLATTable[char(ci.Incode)]:=char(ci.Outcode);
       end;
  end;
  FS:=TStringStream.CreateRaw(InputData);
  try
    SetLength(Buffer,1024);
    SS:=TStringStream.Create('', CP_NONE);
    try
      while (FS.Position<FS.Size) do
      begin
        Count:=FS.Read(Buffer[1],1024);
        if (CodePageInfo[CodePage].CpNr=65001)
        and (CodePageInfo[CodePage].UTF8<>nil)then begin
          for i:=1 to Count do
              SS.WriteString(UTF8Table[XLATTable[Buffer[i]]]);
        end
        else begin
          for i:=1 to Count do
            Buffer[i]:=XLATTable[Buffer[i]];
          BR := copy(Buffer,1,Count);
          SS.WriteBuffer(BR[1], Count);
        end;
      end;
    finally
      SS.Seek(0,soFromBeginning);
//      SL.LoadFromStream(SS);
      LoadFromStreamMy(SL,SS); //New function those accepted #0 char
    end;
  finally
    FS.Free;
  end;
end;

function winPrint_Print(ADataToPrint: PChar; APrinterName: PChar; ACopies: Integer;
  AOrientation: Integer; AFontName: PChar; AFontSize: Integer; AMarginL, AMarginR, AMarginT, AMarginB: Double;
  ALinesPerInch: Integer; ALinesPerPage: Integer; ATitle: PChar; ACodePage: Integer): Integer; stdcall;
const
  TAB_ORINT: array[1..2] of TPrinterOrientation = (poPortrait, poLandscape);
var
  I: Integer;
begin
  if ACopies <= 0 then
    Exit(0);
  if not AOrientation in [1,2] then
    AOrientation := 1;
  if not Assigned(PrintFont) then
    PrintFont := TFont.Create;
  PrintFont.Name := AFontName;
  PrintFont.Size := AFontSize;
  if not Assigned(SL) then
    SL := TStringList.Create;
  ReadANDConvert2(TCodePage(ACodePage), RawByteString(ADataToPrint), SL, false, nil);
  Printer.Refresh;
  for I := 1 to ACopies do
  begin
    Result := PrintStrings(ATitle, SL, CodePageInfo[TCodePage(ACodePage)].CpNr, Printer.Printers.IndexOf(APrinterName), AMarginL/25.4, AMarginR/25.4,
      AMarginT/25.4, AMarginB/25.4, TAB_ORINT[AOrientation], ALinesPerInch,
      ALinesPerPage, true, PrintFont, nil, nil, 0, 0, False, [12,26], False,
      nil, nil);
    if Result = 0 then
      Break;
  end;
  SL.Clear;
end;

initialization
  LoadUnicode;

finalization
  if Assigned(PrintFont) then
    FreeAndNil(PrintFont);
  if Assigned(SL) then
    FreeAndNil(SL);

end.

