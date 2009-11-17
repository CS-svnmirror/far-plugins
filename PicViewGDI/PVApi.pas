{$I Defines.inc}

unit PVApi;

interface

uses
  Windows;

const
  // ������ ���������� PVD, ����������� ���� ������������ ������.
  // ������ ��� �������� ������������� ���������� � pvdInit ��� �������� �������������.
  PVD_CURRENT_INTERFACE_VERSION = 1;
  // ������ ��� �������� ������������� ���������� � pvdInit2 ��� �������� �������������.
  PVD_UNICODE_INTERFACE_VERSION = 2;

const
  // ����� ������ ���������� (������ ������ 2 ����������)
  PVD_IP_DECODE     = 1;      // ������� (��� ������ 1)
  PVD_IP_TRANSFORM  = 2;      // �������� ������� ��� Lossless transform (��������� � ����������)
  PVD_IP_DISPLAY    = 4;      // ����� ���� ����������� ������ ���������� � PicView ��������� DX (��������� � ����������)
  PVD_IP_PROCESSING = 8;      // PostProcessing operations (��������� � ����������)

  PVD_IP_MULTITHREAD   = $100;  // ������� ����� ���������� ������������ � ������ �����
  PVD_IP_ALLOWCACHE    = $200;  // PicView ����� ���������� ����� �� �������� pvdFileClose2 ��� ����������� �������������� �����������
  PVD_IP_CANREFINE     = $400;  // ������� ������������ ���������� ��������� (��������)
  PVD_IP_CANREFINERECT = $800;  // ������� ������������ ���������� ��������� (��������) ��������� �������
  PVD_IP_CANREDUCE     = $1000; // ������� ����� ��������� ������� ����������� � ����������� ���������
  PVD_IP_NOTERMINAL    = $2000; // ���� ������ ������� ������ ������������ � ������������ ��������
  PVD_IP_PRIVATE       = $4000; // ����� ����� ������ � ��������� (PVD_IP_DECODE|PVD_IP_DISPLAY).
                                // ���� ��������� �� ����� ���� ����������� ��� ������������� ������ ������
                                // �� ����� ���������� ������ ��, ��� ����������� ���
  PVD_IP_DIRECT        = $8000; // "�������" ������ ������. ��������, ����� ����� DirectX.


const
  // ������������� ��������������� �����������
  PVD_IIF_ANIMATED   = 1;
  // ���� ������� ������������ ���������� ��������� (��������) ��������� �������
  PVD_IIF_CAN_REFINE = 2;
  // ��������������� ���������, ���� ��������� ������� ����������� ����� (� ������� ������� �������� �� �����)
  PVD_IIF_FILE_REQUIRED = 4;
  // ��������������� ����������� ������������ ����� ����� ��� �������
  // ������ ����� ������ �������� �������� �������, � ����� ������� ��������� (����� � ������ ��������)
  PVD_IIF_MAGAZINE = $100;

const
  // ������ ��������������� ����������� �������� ������ ��� ������
  PVD_IDF_READONLY          = 1;
  // **** ��������� ����� ������������ ������ �� 2-� ������ ����������
  // pImage �������� 32���� �� ������� � ������� ���� �������� ����� �������
  PVD_IDF_ALPHA             = 2;   // ��� ������� � �������� - ������� ���� ������� �� �������
  // ���� �� ������ (��������� ���������� ��� � pvdInfoDecode2.TransparentColor) ������� ���������� (������ ������ 2 ����������)
  PVD_IDF_TRANSPARENT       = 4;   // pvdInfoDecode2.TransparentColor �������� COLORREF ����������� �����
  PVD_IDF_TRANSPARENT_INDEX = 8;   // pvdInfoDecode2.TransparentColor �������� ������ ����������� �����
  PVD_IDF_ASDISPLAY         = 16;  // ��������� �������� �������� ������� ������ (����� �� ���������� ������ �����������)
  PVD_IDF_PRIVATE_DISPLAY   = 32;  // "����������" �������������, ������� ����� ���� ������������ ��� ������
                                   // ������ ���� �� ����������� (� ������� ������ ���� ���� PVD_IP_DISPLAY)
  PVD_IDF_COMPAT_MODE       = 64;  // ������ ������ ������ ������ � ������ ������������� � ������ (����� PVD1Helper.cpp)


(*
// pvdInitPlugin2 - ��������� ������������� ����������
struct pvdInitPlugin2
{
	UINT32 cbSize;               // [IN]  ������ ��������� � ������
	UINT32 nMaxVersion;          // [IN]  ������������ ������ ����������, ������� ����� ���������� PictureView
	const wchar_t *pRegKey;      // [IN]  ���� �������, � ������� ��������� ����� ������� ���� ���������.
	                             //       �������� ��� ���������� pvd_bmp.pvd ���� ���� ����� �����
	                             //       "Software\\Far2\\Plugins\\PictureView\\pvd_bmp.pvd"
	                             //       ����������� � HKEY_CURRENT_USER.
	                             //       ���������� ������������� ����� ������� ������������� �������� (����
	                             //       ��� ���� ��� �����������), ����� ��� PicView ��� ���� ������������
	                             //       ����������� ��������� ��� ��������.
	DWORD  nErrNumber;           // [OUT] ���������� (��� ����������) ��� ������ �������������
	                             //       ���������� ���������� �������������� ������� pvdTranslateError2
	void  *pContext;             // [OUT] ��������, ������������ ��� ��������� � ����������

	// Some helper functions
	void  *pCallbackContext;     // [IN]  ��� �������� ������ ���� �������� � �������, ������ ����
	// 0-����������, 1-��������������, 2-������
	void (__stdcall* MessageLog)(void *pCallbackContext, const wchar_t* asMessage, UINT32 anSeverity);
	// asExtList ����� ��������� '*' (����� ������ TRUE) ��� '.' (TRUE ���� asExt �����). ��������� �������������������
	BOOL (__stdcall* ExtensionMatch)(wchar_t* asExtList, const wchar_t* asExt);
	//
	HMODULE hModule;             // [IN]  HANDLE ����������� ����������
};
*)
type
  PPVDInitPlugin2 = ^TPVDInitPlugin2;
  TPVDInitPlugin2 = record
    cbSize :UINT;
    nMaxVersion :UINT;
    pRegKey :PWideChar;
    nErrNumber :DWORD;
    pContext :Pointer;
    pCallbackContext :Pointer;
    MessageLog :Pointer;
    ExtensionMatch :Pointer;
    hModule :THandle;
  end;

(*
struct pvdInfoPlugin2
{
	UINT32 cbSize;               // [IN]  ������ ��������� � ������
	UINT32 Flags;                // [OUT] ��������� ����� PVD_IP_xxx
	const wchar_t *pName;        // [OUT] ��� ����������
	const wchar_t *pVersion;     // [OUT] ������ ����������
	const wchar_t *pComments;    // [OUT] ����������� � ����������: ��� ���� ������������, ��� ����� ����������, ...
	UINT32 Priority;             // [OUT] ��������� ����������; ������������ ������ ��� ����� ����������� ��� ������������
	                             //       ������ ���������. ��� ���� Priority ��� ���� � ������ �� ����� ��������.
	HMODULE hModule;             // [IN]  HANDLE ����������� ����������
};
*)
type
  PPVDInfoPlugin2 = ^TPVDInfoPlugin2;
  TPVDInfoPlugin2 = record
    cbSize :UINT;
    Flags :UINT;
    pName :PWideChar;
    pVersion :PWideChar;
    pComments :PWideChar;
    Priority :UINT;
    hModule :THandle;
  end;

(*
// pvdFormats2 - ������ �������������� ��������
struct pvdFormats2
{
    UINT32 cbSize;               // [IN]  ������ ��������� � ������
    const wchar_t *pSupported;   // [OUT] ������ �������������� ���������� ����� �������.
                                 //       ����� ����������� �������� "*" ����������, ���
                                 //       ��������� �������� �������������.
                                 //       ���� ��� ������������� �� ���� �� ����������� �� ������� �� ���������� -
                                 //       PicView ��� ����� ���������� ������� ���� �����������, ���� ����������
                                 //       �� ������� � ������ ��� ������������.
    const wchar_t *pIgnored;     // [OUT] ������ ������������ ���������� ����� �������.
                                 //       ��� ������ � ���������� ������������ ��������� ��
                                 //       ����� ���������� ������. ������� "." ��� �������������
	                             //       ������ ��� ����������.
    // !!! ������ �������� "����������". ������������ ����� ������������� ������ ����������.
};
*)
type
  PPVDFormats2 = ^TPVDFormats2;
  TPVDFormats2 = record
    cbSize :UINT;
    pSupported :PWideChar;
    pIgnored :PWideChar;
  end;

(*
struct pvdInfoImage2
{
	UINT32 cbSize;               // [IN]  ?????? ????????? ? ??????
	void   *pImageContext;       // [IN]  ??? ?????? ?? pvdFileOpen2 ????? ???? ?? NULL,
								 //       ???? ?????? ???????????? ??????? pvdFileDetect2
								 // [OUT] ????????, ???????????? ??? ????????? ? ?????
	UINT32 nPages;               // [OUT] ?????????? ??????? ???????????
								 //       ??? ?????? ?? pvdFileDetect2 ?????????? ?????????????
	UINT32 Flags;                // [OUT] ????????? ?????: PVD_IIF_xxx
								 //       ??? ?????? ?? pvdFileDetect2 ???????? ???? PVD_IIF_FILE_REQUIRED
	const wchar_t *pFormatName;  // [OUT] ???????? ??????? ?????
								 //       ??? ?????? ?? pvdFileDetect2 ?????????? ?????????????, ?? ??????????
	const wchar_t *pCompression; // [OUT] ???????? ??????
								 //       ??? ?????? ?? pvdFileDetect2 ?????????? ?????????????
	const wchar_t *pComments;    // [OUT] ????????? ??????????? ? ?????
								 //       ??? ?????? ?? pvdFileDetect2 ?????????? ?????????????
	//
	DWORD  nErrNumber;           // [OUT] ?????????? ?? ?????? ?????????????? ??????? ?????
	                             //       ?????????? ?????????? ?????????????? ??????? pvdTranslateError2
	                             //       ??? ???????? ???? (< 0x7FFFFFFF) PicView ??????? ???
	                             //       ?????????? ?????? ?????????? ???? ?????? ?????. PicView
	                             //       ?? ????? ?????????? ??? ?????? ????????????, ???? ??????
	                             //       ??????? ???? ?????-?? ?????? ???????????-?????????.

	DWORD nReserved, nReserver2;
};
*)
type
  PPVDInfoImage2 = ^TPVDInfoImage2;
  TPVDInfoImage2 = record
    cbSize :UINT;
    pImageContext :Pointer;
    nPages :UINT;
    Flags :UINT;
    pFormatName :PWideChar;
    pCompression :PWideChar;
    pComments :PWideChar;
    nErrNumber :DWORD;
    nReserverd, nReserverd2 :DWORD;
  end;

(*
struct pvdInfoPage2
{
	UINT32 cbSize;            // [IN]  ������ ��������� � ������
	UINT32 iPage;             // [IN]  ����� �������� (0-based)
	UINT32 lWidth;            // [OUT] ������ ��������
	UINT32 lHeight;           // [OUT] ������ ��������
	UINT32 nBPP;              // [OUT] ���������� ��� �� ������� (������ �������������� ���� - � �������� �� ������������)
	UINT32 lFrameTime;        // [OUT] ��� ������������� ����������� - ������������ ����������� �������� � �������� �������;
	                          //       ����� - �� ������������
	// Plugin output
	DWORD  nErrNumber;           // [OUT] ���������� �� ������
                                 //       ���������� ���������� �������������� ������� pvdTranslateError2
	UINT32 nPages;               // [OUT] 0, ��� ������ ����� ��������������� ���������� ������� �����������
	const wchar_t *pFormatName;  // [OUT] NULL ��� ������ ����� ��������������� �������� ������� �����
	const wchar_t *pCompression; // [OUT] NULL ��� ������ ����� ��������������� �������� ������
};
*)
type
  PPVDInfoPage2 = ^TPVDInfoPage2;
  TPVDInfoPage2 = record
    cbSize :UINT;
    iPage :UINT;
    lWidth :UINT;
    lHeight :UINT;
    nBPP :UINT;
    lFrameTime :UINT;
    nErrNumber :DWORD;
    nPages :UINT;
    pFormatName :PWideChar;
    pCompression :PWideChar;
  end;


const
  // ������ ��������� ������ "PVD_CM_BGR" � "PVD_CM_BGRA"
  PVD_CM_UNKNOWN =  0;  // -- ����� ����������� ������ ����� �� ����� �������� ��������
  PVD_CM_GRAY    =  1;  // "Gray scale"  -- UNSUPPORTED !!!
  PVD_CM_AG      =  2;  // "Alpha_Gray"  -- UNSUPPORTED !!!
  PVD_CM_RGB     =  3;  // "RGB"         -- UNSUPPORTED !!!
  PVD_CM_BGR     =  4;  // "BGR"
  PVD_CM_YCBCR   =  5;  // "YCbCr"       -- UNSUPPORTED !!!
  PVD_CM_CMYK    =  6;  // "CMYK"
  PVD_CM_YCCK    =  7;  // "YCCK"        -- UNSUPPORTED !!!
  PVD_CM_YUV     =  8;  // "YUV"         -- UNSUPPORTED !!!
  PVD_CM_BGRA    =  9;  // "BGRA"
  PVD_CM_RGBA    = 10;  // "RGBA"        -- UNSUPPORTED !!!
  PVD_CM_ABRG    = 11;  // "ABRG"        -- UNSUPPORTED !!!
  PVD_CM_PRIVATE = 12;  // ������ ���� �������==������� � ���� �� ������������

(*
struct pvdInfoDecode2
{
	UINT32 cbSize;             // [IN]  ������ ��������� � ������
	UINT32 iPage;              // [IN]  ����� ������������ �������� (0-based)
	UINT32 lWidth, lHeight;    // [IN]  ������������� ������ ��������������� ����������� (���� ������� ������������ ������������)
	                           // [OUT] ������ �������������� ������� (pImage)
	UINT32 nBPP;               // [IN]  PicView ����� ��������� ���������������� ������ (���� �� ������������)
	                           // [OUT] ���������� ��� �� ������� � �������������� �����������
	                           //       ��� ������������� 32 ��� ����� ���� ������ ���� PVD_IDF_ALPHA
                               //       PicView �� ���������� ��� �������� ������������ - � ��������� 
	                           //       ��������� pvdInfoPage2.nBPP, ��� ��� ����� �������� ������ ��������������
	INT32  lImagePitch;        // [OUT] ������ - ����� ������ ��������������� ����������� � ������;
	                           //       ������������� �������� - ������ ���� ������ ����, ������������� - ����� �����
	UINT32 Flags;              // [IN]  PVD_IDF_ASDISPLAY | PVD_IDF_COMPAT_MODE
	                           // [OUT] ��������� �����: PVD_IDF_*
	union {
	RGBQUAD TransparentColor;  // [OUT] if (Flags&PVD_IDF_TRANSPARENT) - �������� ����, ������� ��������� ����������
	DWORD  nTransparentColor;  //       if (Flags&PVD_IDF_TRANSPARENT_INDEX) - �������� ������ ����������� �����
	};                         // ��������! ��� �������� ����� PVD_IDF_ALPHA - Transparent ������������

	BYTE   *pImage;            // [OUT] ��������� �� ������ ����������� � ���������� �������
	                           //       ������ ������� �� nBPP
	                           //       1,4,8 ��� - ������ � ��������
	                           //       16 ��� - ������ ��������� ����� ������� �� 5 ��� (BGR)
	                           //       24 ��� - 8 ��� �� ��������� (BGR)
	                           //       32 ��� - 8 ��� �� ��������� (BGR ��� BGRA ��� �������� PVD_IDF_ALPHA)
	UINT32 *pPalette;          // [OUT] ��������� �� ������� �����������, ������������ � �������� 8 � ������ ��� �� �������
	UINT32 nColorsUsed;        // [OUT] ���������� ������������ ������ � �������; ���� 0, �� ������������ ��� ��������� �����
	                           //       (���� �� ������������, ������� ������ ��������� [1<<nBPP] ������)

	DWORD  nErrNumber;         // [OUT] ���������� �� ������ �������������
	                           //       ���������� ���������� �������������� ������� pvdTranslateError2

	LPARAM lParam;             // [OUT] ��������� ����� ������������ ��� ���� �� ���� ����������

	pvdColorModel  ColorModel; // [OUT] ������ �������������� ������ PVD_CM_BGR & PVD_CM_BGRA
	DWORD          Precision;  // [RESERVED] bits per channel (8,12,16bit)
	POINT          Origin;     // [RESERVED] m_x & m_y; Interface apl returns m_x=0; m_y=Ymax;
	float          PAR;        // [RESERVED] Pixel aspect ratio definition
	pvdOrientation Orientation;// [RESERVED]
	UINT32 nPages;             // [OUT] 0, ��� ������ ����� ��������������� ���������� ������� �����������
	const wchar_t *pFormatName;  // [OUT] NULL ��� ������ ����� ��������������� �������� ������� �����
	const wchar_t *pCompression; // [OUT] NULL ��� ������ ����� ��������������� �������� ������
	union {
		RGBQUAD BackgroundColor; // [IN] ������� ����� ������������ ��� ���� ��� ����������
		DWORD  nBackgroundColor; //      ���������� �����������
	};
};
*)
type
  PPVDInfoDecode2 = ^TPVDInfoDecode2;
  TPVDInfoDecode2 = packed record
    cbSize :UINT;
    iPage :UINT;
    lWidth :UINT;
    lHeight :UINT;
    nBPP :UINT;
    lImagePitch :Integer;
    Flags :UINT;
    nTransparentColor :DWORD;
    pImage :Pointer;
    pPalette :Pointer;
    nColorsUsed :UINT;
    nErrNumber :DWORD;
    lParam :LPARAM;
    ColorModel :byte; {PPVDColorModel}
    Precision :DWORD;
    Origin :TPoint;
    PAR :Extended; {???}
    Orientation :byte; {PPVDOrientation}
    nPages :UINT;
    pFormatName :PWideChar;
    pCompression :PWideChar;
    nBackgroundColor :DWORD;
  end;

(*
struct pvdInfoDisplayInit2
{
	UINT32 cbSize;               // [IN]  ������ ��������� � ������
	HWND hWnd;                   // [IN]
	DWORD nCMYKparts;
	DWORD *pCMYKpalette;
	DWORD nCMYKsize;
	DWORD uCMYK2RGB;
	DWORD nErrNumber;            // [OUT]
};
*)
type
  PPVDInfoDisplayInit2 = ^TPVDInfoDisplayInit2;
  TPVDInfoDisplayInit2 = record
    cbSize :UINT;
    hWnd :HWND;
    nCMYKparts :DWORD;
    pCMYKpalette :Pointer;
    nCMYKsize :DWORD;
    uCMYK2RGB :DWORD;
    nErrNumber :DWORD;
  end;

(*
struct pvdInfoDisplayAttach2
{
	UINT32 cbSize;               // [IN]  ������ ��������� � ������
	HWND hWnd;                   // [IN]  ���� ����� ���� �������� � �������� ������
	BOOL bAttach;                // [IN]  ����������� ��� ���������� �� hWnd
	DWORD nErrNumber;            // [OUT]
};
*)
type
  PPVDInfoDisplayAttach2 = ^TPVDInfoDisplayAttach2;
  TPVDInfoDisplayAttach2 = record
    cbSize :UINT;
    hWnd :HWND;
    bAttach :BOOL;
    nErrNumber :DWORD;
  end;

(*
struct pvdInfoDisplayCreate2
{
	UINT32 cbSize;               // [IN]  ������ ��������� � ������
	pvdInfoDecode2* pImage;      // [IN]
	DWORD BackColor;             // [IN]  RGB background
	void* pDisplayContext;       // [OUT]
	DWORD nErrNumber;            // [OUT]
	const wchar_t* pFileName;    // [IN]  Information only. Valid only in pvdDisplayCreate2
	UINT32 iPage;                // [IN]  Information only
};
*)
type
  PPVDInfoDisplayCreate2 = ^TPVDInfoDisplayCreate2;
  TPVDInfoDisplayCreate2 = record
    cbSize :UINT;
    pImage :PPVDInfoDecode2;
    BackColor :DWORD;
    pDisplayContext :Pointer;
    nErrNumber :DWORD;
    pFileName :PWideChar;
    iPage :UINT;
  end;


const
  PVD_IDP_BEGIN     = 1;
  PVD_IDP_PAINT     = 2;
  PVD_IDP_COLORFILL = 3;
  PVD_IDP_COMMIT    = 4;

(*
struct pvdInfoDisplayPaint2
{
	UINT32 cbSize;               // [IN]  ������ ��������� � ������
	DWORD Operation;  // PVD_IDP_*
	HWND hWnd;                   // [IN]  ��� ��������
	HWND hParentWnd;             // [IN]
	union {
	RGBQUAD BackColor;  //
	DWORD  nBackColor;  //
	};
	RECT ImageRect;
	RECT DisplayRect;

	LPVOID pDrawContext; // ��� ���� ����� �������������� ����������� ��� �������� "HDC". ����������� ������ ��������� �� ������� PVD_IDP_COMMIT

	//RECT ParentRect;
	////DWORD BackColor;             // [IN]  RGB background
	//BOOL bFreePosition;
	//BOOL bCorrectMousePos;
	//POINT ViewCenter;
	//POINT DragBase;
	//UINT32 Zoom;
	//RECT rcGlobal;               // [IN]  � ����� ����� ���� ����� �������� ����������� (��������� ���������� ����� BackColor)
	//RECT rcCrop;                 // [IN]  ������������� ��������� (���������� ����� ����)
	DWORD nErrNumber;            // [OUT]
	
	DWORD nZoom; // [IN] ���������� ������ ��� ����������. 0x10000 == 100%
	DWORD nFlags; // [IN] PVD_IDPF_*
	
	DWORD *pChessMate;
	DWORD uChessMateWidth;
	DWORD uChessMateHeight;
};
*)
type
  PPVDInfoDisplayPaint2 = ^TPVDInfoDisplayPaint2;
  TPVDInfoDisplayPaint2 = record
    cbSize :UINT;
    Operation :DWORD;
    hWnd :HWND;
    hParentWnd :HWND;
    nBackColor :DWORD;
    ImageRect :TRECT;
    DisplayRect :TRECT;
    pDrawContext :Pointer;
    nErrNumber :DWORD;
    nZoom :DWORD;
    nFlags :DWORD;
    pChessMate :Pointer;
    uChessMateWidth :DWORD;
    uChessMateHeight :DWORD;
  end;

(*
typedef BOOL (__stdcall *pvdDecodeCallback2)(void *pDecodeCallbackContext2, UINT32 iStep, UINT32 nSteps,
											 pvdInfoDecodeStep2* pImagePart);
*)
type
  {!!!}
  TPVDDecodeCallback2 = pointer;


{******************************************************************************}
{******************************} implementation {******************************}
{******************************************************************************}

end.

