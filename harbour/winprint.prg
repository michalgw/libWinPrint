#include "winprint.ch"
#include "hbdyn.ch"

STATIC nLibWinPrintHandle := NIL

FUNCTION WinPrintInit( cLibFile )

   hb_default( @cLibFile, LIB_WIN_PRINT )

   nLibWinPrintHandle := hb_libLoad( cLibFile )

   RETURN ! Empty( nLibWinPrintHandle )

/*----------------------------------------------------------------------*/

FUNCTION WinPrintPrint( cDataToPrint, cPrinterName, nCopies, nOrientation, ;
   cFontName, nFontSize, nMarginL, nMarginR, nMarginT, nMarginB, ;
   nLinesPerInch, nLinesPerPage, cTitle, nCodePage )

   IF ! Empty( nLibWinPrintHandle )
      RETURN hb_DynCall( { 'winPrint_Print', nLibWinPrintHandle, ;
         hb_bitOr( HB_DYN_CTYPE_INT, HB_DYN_CALLCONV_STDCALL ), ;
         HB_DYN_CTYPE_CHAR_PTR, HB_DYN_CTYPE_CHAR_PTR, HB_DYN_CTYPE_INT, ;
         HB_DYN_CTYPE_INT, HB_DYN_CTYPE_CHAR_PTR, HB_DYN_CTYPE_INT, ;
         HB_DYN_CTYPE_DOUBLE, HB_DYN_CTYPE_DOUBLE, HB_DYN_CTYPE_DOUBLE, ;
         HB_DYN_CTYPE_DOUBLE, HB_DYN_CTYPE_INT, HB_DYN_CTYPE_INT, ;
         HB_DYN_CTYPE_CHAR_PTR, HB_DYN_CTYPE_INT }, cDataToPrint, ;
         cPrinterName, nCopies, nOrientation, cFontName, nFontSize, ;
         nMarginL, nMarginR, nMarginT, nMarginB, nLinesPerInch, ;
         nLinesPerPage, cTitle, nCodePage )
   ENDIF

   RETURN 0

/*----------------------------------------------------------------------*/

FUNCTION WinPrintPrinterSetupDlg( cPrinterName )

   IF ! Empty( nLibWinPrintHandle ) .AND. ! Empty( cPrinterName )
      RETURN hb_DynCall( { 'winPrint_PrinterSetupDlg', nLibWinPrintHandle, ;
         hb_bitOr( HB_DYN_CTYPE_INT, HB_DYN_CALLCONV_STDCALL ), ;
         HB_DYN_CTYPE_CHAR_PTR }, cPrinterName ) 
   ENDIF

   RETURN 0

/*----------------------------------------------------------------------*/

PROCEDURE WinPrintDone()

   IF ! Empty( nLibWinPrintHandle )
      hb_libFree( nLibWinPrintHandle )
      nLibWinPrintHandle := NIL
   ENDIF

   RETURN

/*----------------------------------------------------------------------*/

