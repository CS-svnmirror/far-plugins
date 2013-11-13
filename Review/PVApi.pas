{$I Defines.inc}

unit PVApi;

// ��������� PVD ��������-���������, v1.0 / v2.0
// v1.0: ��������� ���� ���������� �����: UTF-8.

// Copyright (c) Skakov Pavel

// Copyright (c) Maximus5,
// http://code.google.com/p/conemu-maximus5

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
  PVD_IP_DECODE     = 1;         // ������� (��� ������ 1)
  PVD_IP_TRANSFORM  = 2;         // �������� ������� ��� Lossless transform (��������� � ����������)
  PVD_IP_DISPLAY    = 4;         // ����� ���� ����������� ������ ���������� � PicView ��������� DX (��������� � ����������)
  PVD_IP_PROCESSING = 8;         // PostProcessing operations (��������� � ����������)

  PVD_IP_MULTITHREAD   = $100;   // ������� ����� ���������� ������������ � ������ �����
  PVD_IP_ALLOWCACHE    = $200;   // PicView ����� ���������� ����� �� �������� pvdFileClose2 ��� ����������� �������������� �����������
  PVD_IP_CANREFINE     = $400;   // ������� ������������ ���������� ��������� (��������)
  PVD_IP_CANREFINERECT = $800;   // ������� ������������ ���������� ��������� (��������) ��������� �������
  PVD_IP_CANREDUCE     = $1000;  // ������� ����� ��������� ������� ����������� � ����������� ���������
  PVD_IP_NOTERMINAL    = $2000;  // ���� ������ ������� ������ ������������ � ������������ ��������
  PVD_IP_PRIVATE       = $4000;  // ����� ����� ������ � ��������� (PVD_IP_DECODE|PVD_IP_DISPLAY).
                                 // ���� ��������� �� ����� ���� ����������� ��� ������������� ������ ������
                                 // �� ����� ���������� ������ ��, ��� ����������� ���
  PVD_IP_DIRECT        = $8000;  // "�������" ������ ������. ��������, ����� ����� DirectX.
  PVD_IP_FOLDER        = $10000; // ������ ����� ���������� Thumbnail ��� ����� (a'la ��������� Windows � ������ �������)
  PVD_IP_CANDESCALE    = $20000; // �������������� ��������� � ������ ����������
  PVD_IP_CANUPSCALE    = $40000; // �������������� ��������� � ������ ����������

  // Review: �� ��������� ��������������� ����������� ����� - ������ ��� ������ ���
  PVD_IP_NEEDFILE    = $1000000;

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

  // Review: ����� ����. nPages �������� ������������ ����� � ��.
  PVD_IIF_MOVIE = $1000;


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


{pvdColorModel}
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

{pvdOrientation}
const
  PVD_Ornt_Default      = 0;
  PVD_Ornt_TopLeft      = 1; // The 0th row is at the visual top of the image, and the 0th column is the visual left-hand side.
  PVD_Ornt_TopRight     = 2; // The 0th row is at the visual top of the image, and the 0th column is the visual right-hand side.
  PVD_Ornt_BottomRight  = 3; // The 0th row is at the visual bottom of the image, and the 0th column is the visual right-hand side.
  PVD_Ornt_BottomLeft   = 4; // The 0th row is at the visual bottom of the image, and the 0th column is the visual left-hand side.
  PVD_Ornt_LeftTop      = 5; // The 0th row is the visual left-hand side of the image, and the 0th column is the visual top.
  PVD_Ornt_RightTop     = 6; // The 0th row is the visual right-hand side of the image, and the 0th column is the visual top.
  PVD_Ornt_RightBottom  = 7; // The 0th row is the visual right-hand side of the image, and the 0th column is the visual bottom.
  PVD_Ornt_LeftBottom   = 8; // The 0th row is the visual left-hand side of the image, and the 0th column is the visual bottom.


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

  BOOL (__stdcall* CallSehed)(pvdCallSehedProc2 CalledProc, LONG_PTR Param1, LONG_PTR Param2, LONG_PTR* Result);
  int (__stdcall* SortExtensions)(wchar_t* pszExtensions);
  int (__stdcall* MulDivI32)(int a, int b, int c);  // (__int64)a * b / c;
  UINT (__stdcall* MulDivU32)(UINT a, UINT b, UINT c);  // (uint)((unsigned long long)(a)*(b)/(c))
  UINT (__stdcall* MulDivU32R)(UINT a, UINT b, UINT c);  // (uint)(((unsigned long long)(a)*(b) + (c)/2)/(c))
  int (__stdcall* MulDivIU32R)(int a, UINT b, UINT c);  // (int)(((long long)(a)*(b) + (c)/2)/(c))
//PRAGMA_ERROR("�������� ������� ������������� PNG. ����� ��������� ����� �� ICO.PVD �� � �� ������������ gdi+ ��� �������� CMYK");
  UINT32 Flags;                // [IN] ��������� �����: PVD_IPF_xxx
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

    CallSehed :Pointer;
    SortExtensions :Pointer;
    MulDivI32 :Pointer;
    MulDivU32 :Pointer;
    MulDivU32R :Pointer;
    MulDivIU32R :Pointer;

    Flags :UINT;
  end;


(*
// pvdInfoPlugin - ���������� � �������
struct pvdInfoPlugin
{
  UINT32 Priority;          // ��������� �������; ���� 0, �� ������ �� ����� ���������� � �������� �����������������
  const char *pName;        // ��� �������
  const char *pVersion;     // ������ �������
  const char *pComments;    // ����������� � �������: ��� ���� ������������, ��� ����� �������, ...
};
*)
type
  PPVDInfoPlugin = ^TPVDInfoPlugin;
  TPVDInfoPlugin = record
    Priority :UINT;
    pName :PAnsiChar;
    pVersion :PAnsiChar;
    pComments :PAnsiChar;
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
struct pvdFormats2
{
  UINT32 cbSize;		 // [IN]  ������ ��������� � ������
  const wchar_t *pActive;	 // [OUT] ������ �������� ���������� ����� �������.
				 //	  ��� ����������, ������� ������ ����� "������" ���������.
				 //       ����� ����������� �������� "*" ����������, ���
				 //       ��������� �������� �������������.
				 //       ���� ��� ������������� �� ���� �� ����������� �� ������� �� ���������� -
				 //       PicView ��� ����� ���������� ������� ���� �����������, ���� ����������
				 //       �� ������� � ������ ��� �����������.
   const wchar_t *pForbidden;	 // [OUT] ������ ������������ ���������� ����� �������.
				 //       ��� ������ � ���������� ������������ ��������� ��
				 //       ����� ���������� ������. ������� "." ��� �������������
				 //       ������ ��� ����������.
   const wchar_t *pInactive;	 // [OUT] ������ ���������� ���������� ����� �������.
				 //       ����� ����������� ����������, ������� ������ ����� �������
				 //       "� ��������", �� ��������, � ����������.
   // !!! ������ �������� "����������". ������������ ����� ������������� ������ ����������.
};
*)
type
  PPVDFormats2 = ^TPVDFormats2;
  TPVDFormats2 = record
    cbSize :UINT;
    pSupported :PWideChar;
    pIgnored :PWideChar;
    pInactive :PWideChar;
  end;


(*
// pvdInfoImage - ���������� � �����
struct pvdInfoImage
{
  UINT32 nPages;            // ���������� ������� �����������
  UINT32 Flags;             // ��������� �����: PVD_IIF_ANIMATED
  const char *pFormatName;  // �������� ������� �����
  const char *pCompression; // �������� ������
  const char *pComments;    // ��������� ����������� � �����
};
*)
type
  PPVDInfoImage = ^TPVDInfoImage;
  TPVDInfoImage = record
    nPages :UINT;
    Flags :UINT;
    pFormatName :PAnsiChar;
    pCompression :PAnsiChar;
    pComments :PAnsiChar;
  end;

(*
struct pvdInfoImage2
{
  UINT32 cbSize;               // [IN]  ������ ��������� � ������
  void   *pImageContext;       // [IN]  ��� ������ �� pvdFileOpen2 ����� ���� �� NULL,
                               //       ���� ������ ������������ ������� pvdFileDetect2
                               // [OUT] ��������, ������������ ��� ��������� � �����
  UINT32 nPages;               // [OUT] ���������� ������� �����������
                               //       ��� ������ �� pvdFileDetect2 ���������� �������������
  UINT32 Flags;                // [OUT] ��������� �����: PVD_IIF_xxx
                               //       ��� ������ �� pvdFileDetect2 �������� ���� PVD_IIF_FILE_REQUIRED
  const wchar_t *pFormatName;  // [OUT] �������� ������� �����
                               //       ��� ������ �� pvdFileDetect2 ���������� �������������, �� ����������
  const wchar_t *pCompression; // [OUT] �������� ������
                               //       ��� ������ �� pvdFileDetect2 ���������� �������������
  const wchar_t *pComments;    // [OUT] ��������� ����������� � �����
                               //       ��� ������ �� pvdFileDetect2 ���������� �������������
  DWORD  nErrNumber;           // [OUT] ���������� �� ������ �������������� ������� �����
                               //       ���������� ���������� �������������� ������� pvdTranslateError2
                               //       ��� �������� ���� (< 0x7FFFFFFF) PicView ������� ���
                               //       ���������� ������ ���������� ���� ������ �����. PicView
                               //       �� ����� ���������� ��� ������ ������������, ���� ������
                               //       ������� ���� �����-�� ������ �����������-���������.
  DWORD nReserved, nReserver2;
};

// pvdFileOpen - �������� �����: ��������� ������, ����� �� �� ������������ ����, � ��������� ����� ���������� � �����
//  ����������: ��� �������� �����
//  ���������:
//   pFileName   - ��� ������������ �����
//   lFileSize   - ����� ������������ ����� � ������. ���� 0, �� ���� �����������, � ���������� ���������� pBuf �����
//                 �������� ��� ��������� ������ � ����� �������� ������ �� ������ pvdFileClose.
//   pBuf        - �����, ���������� ������ ������������ �����
//   lBuf        - ����� ������ pBuf � ������. ������������� ������������� �� ����� 16 ��.
//   pImageInfo  - ��������� �� ��������� � ����������� � ����� ��� ���������� �����������, ���� �� ����� ������������ ����
//   ppImageContext - ��������� �� ��������. ����� ���� �������� ��������� ����� ������� �������� - ������������ ��������,
//                 ������� ����� ������������ ��� ��� ������ ������ ������� ������ � ������ ������. ������� ����� �
//                 ����, ��� ����� ����������� ������� � ���� ������ ������� ����� �������������� ��������� ������,
//                 ������� ������������� ������������ ��������, � �� ���������� ���������� ���������� �������.
//  ������������ ��������: TRUE - ���� ��������� ����� ������������ ��������� ����; ����� - FALSE

BOOL __stdcall pvdFileOpen2(void *pContext, const wchar_t *pFileName, INT64 lFileSize, const BYTE *pBuf, UINT32 lBuf, pvdInfoImage2 *pImageInfo);
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
// pvdInfoPage - ���������� � �������� �����������
struct pvdInfoPage
{
  UINT32 lWidth;            // ������ ��������
  UINT32 lHeight;           // ������ ��������
  UINT32 nBPP;              // ���������� ��� �� ������� (������ �������������� ���� - � ��������� �� ������������)
  UINT32 lFrameTime;        // ��� ������������� ����������� - ������������ ����������� �������� � �������� �������;
                            // ����� - �� ������������
};
*)
type
  PPVDInfoPage = ^TPVDInfoPage;
  TPVDInfoPage = record
    lWidth :UINT;
    lHeight :UINT;
    nBPP :UINT;
    lFrameTime :UINT;
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


(*
// pvdInfoDecode - ���������� � �������������� �����������
struct pvdInfoDecode
{
  BYTE   *pImage;            // ��������� �� ������ ����������� � ������� RGB
  UINT32 *pPalette;          // ��������� �� ������� �����������, ������������ � �������� 8 � ������ ��� �� �������
  UINT32 Flags;              // ��������� �����: PVD_IDF_READONLY
  UINT32 nBPP;               // ���������� ��� �� ������� � �������������� �����������
  UINT32 nColorsUsed;        // ���������� ������������ ������ � �������; ���� 0, �� ������������ ��� ��������� �����
  INT32  lImagePitch;        // ������ - ����� ������ ��������������� ����������� � ������;
                             // ������������� �������� - ������ ���� ������ ����, ������������� - ����� �����
};
*)
type
  PPVDInfoDecode = ^TPVDInfoDecode;
  TPVDInfoDecode = record
    pImage :Pointer;
    pPalette :Pointer;
    Flags :UINT;
    nBPP :UINT;
    nColorsUsed :UINT;
    lImagePitch :Integer;
  end;

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
  UINT32 lSrcWidth,          // [OUT] ������� ����� �������� ������ ��������� �����������. ������ ���� ������
         lSrcHeight;         // [OUT] ����� ������� � ��������� ���� (����� TitleTemplate). ���� ��������� ��
                             //       �� ��������� - ����������� {0,0}.
};

// pvdPageDecode - ������������� �������� �����������
//  ����������: ����� ������� pvdFileOpen � pvdFileClose
//  ���������:
//   pImageContext  - ��������, ������������ ����������� � pvdFileOpen
//   iPage          - ����� �������� ����������� (��������� ���������� � 0)
//   pDecodeInfo    - ��������� �� ��������� � ����������� � �������������� ����������� ��� ���������� �����������
//   DecodeCallback - ��������� �� �������, ����� ������� ��������� ����� ������������� ���������� ��������� � ����
//                    �������������; NULL, ���� ����� ������� �� ���������������
//   pDecodeCallbackContext - ��������, ������������ � DecodeCallback
//  ������������ ��������: TRUE - ��� �������� ����������; ����� - FALSE
//  �������������� ��������� ������ 2:
//   pContext      - ��������, ������������ ����������� � pvdInit2
//   pImageContext - ��������, ������������ ����������� � pvdFileOpen2
BOOL __stdcall pvdPageDecode2(void *pContext, void *pImageContext, pvdInfoDecode2 *pDecodeInfo, 
							  pvdDecodeCallback2 DecodeCallback, void *pDecodeCallbackContext);
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
    lSrcWidth :UINT;
    lSrcHeight :UINT;
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
// pvdDecodeCallback - �������, ��������� �� ������� ��������� � pvdPageDecode
//  ����������: �������� �� pvdPageDecode
//   �� �����������, �� ������������� ������������ ��������, ���� ������������� ����� ������ ���������� �����.
//  ���������:
//   pDecodeCallbackContext - ��������, ���������� ��������������� ���������� pvdPageDecode
//   iStep  - ����� �������� ���� ������������� (��������� �� 0 �� nSteps - 1)
//   nSteps - ����� ���������� ����� �������������
//  ������������ ��������: TRUE - ����������� �������������; FALSE - ������������� ������� ��������
typedef BOOL (__stdcall *pvdDecodeCallback)(void *pDecodeCallbackContext, UINT32 iStep, UINT32 nSteps);
typedef BOOL (__stdcall *pvdDecodeCallback2)(void *pDecodeCallbackContext2, UINT32 iStep, UINT32 nSteps, pvdInfoDecodeStep2* pImagePart);
*)
type
  {!!!}
  TPVDDecodeCallback = pointer;
  TPVDDecodeCallback2 = pointer;


type
// pvdInit - ������������� �������
//  ����������: ���� ��� - ����� ����� �������� �������
//  ������������ ��������: ������ ���������� �������
//   ���� ��� ����� �� ���������� ���������� ���������, �� ��������� pvdExit � ������ ����� ��������.
//   �� ����� ������������ ��� -1. ����� ����� 1. ������������� ������������ ���������������� PVD_CURRENT_INTERFACE_VERSION
//   0 - ������ ��������/������������� �������.

//UINT32 __stdcall pvdInit(void);
  TpvdInit = function() :integer; stdcall;

// pvdExit - ���������� ������ � ��������
//  ����������: ���� ��� - ��������������� ����� ��������� �������

//void __stdcall pvdExit(void);
  TpvdExit = procedure(); stdcall;

// pvdPluginInfo - ����� ���������� � �������
//  ����������: ����� ������
//  ���������:
//   pPluginInfo - ��������� �� ��������� � ����������� � ������� ��� ���������� ��������

//void __stdcall pvdPluginInfo(pvdInfoPlugin *pPluginInfo);
  TpvdPluginInfo = procedure(pPluginInfo :PPVDInfoPlugin); stdcall;

// pvdFileOpen - �������� �����: ������ ������, ����� �� �� ������������ ����, � ��������� ����� ���������� � �����
//  ����������: ��� �������� �����
//  ���������:
//   pFileName   - ��� ������������ �����
//   lFileSize   - ����� ������������ ����� � ������. ���� 0, �� ���� �����������, � ���������� ���������� pBuf �����
//                 �������� ��� ��������� ������ � ����� �������� ������ �� ������ pvdFileClose.
//   pBuf        - �����, ���������� ������ ������������ �����
//   lBuf        - ����� ������ pBuf � ������. ������������� ������������� �� ����� 16 ��.
//   pImageInfo  - ��������� �� ��������� � ����������� � ����� ��� ���������� ��������, ���� �� ����� ������������ ����
//   ppContext   - ��������� �� ��������. ����� ���� �������� ������ ����� ������� �������� - ������������ ��������,
//                 ������� ����� ������������ ��� ��� ������ ������ ������� ������ � ������ ������. ������� ����� �
//                 ����, ��� ����� ����������� ������� � ���� ������ ������� ����� �������������� ��������� ������,
//                 ������� ������������� ������������ ��������, � �� ���������� ���������� ���������� �������.
//  ������������ ��������: TRUE - ���� ������ ����� ������������ ��������� ����; ����� - FALSE

//BOOL __stdcall pvdFileOpen(const char *pFileName, INT64 lFileSize, const BYTE *pBuf, UINT32 lBuf, pvdInfoImage *pImageInfo, void **ppContext);
  TpvdFileOpen = function(pFileName :PAnsiChar; lFileSize :Int64; pBuf :Pointer; lBuf :UINT; pImageInfo :PPVDInfoImage; var pContext :Pointer) :BOOL; stdcall;

// pvdPageInfo - ���������� � �������� �����������
//  ����������: ����� ������� pvdFileOpen � pvdFileClose
//  ���������:
//   pContext    - ��������, ������������ �������� � pvdFileOpen
//   iPage       - ����� �������� ����������� (��������� ���������� � 0)
//   pPageInfo   - ��������� �� ��������� � ����������� � �������� ����������� ��� ���������� ��������
//  ������������ ��������: TRUE - ��� �������� ����������; ����� - FALSE

//BOOL __stdcall pvdPageInfo(void *pContext, UINT32 iPage, pvdInfoPage *pPageInfo);
  TpvdPageInfo = function(pContext :Pointer; iPage :UINT; pPageInfo :PPVDInfoPage) :BOOL; stdcall;

// pvdPageDecode - ������������� �������� �����������
//  ����������: ����� ������� pvdFileOpen � pvdFileClose
//  ���������:
//   pContext       - ��������, ������������ �������� � pvdFileOpen
//   iPage          - ����� �������� ����������� (��������� ���������� � 0)
//   pDecodeInfo    - ��������� �� ��������� � ����������� � �������������� ����������� ��� ���������� ��������
//   DecodeCallback - ��������� �� �������, ����� ������� ������ ����� ������������� ���������� ��������� � ����
//                    �������������; NULL, ���� ����� ������� �� ���������������
//   pDecodeCallbackContext - ��������, ������������ � DecodeCallback
//  ������������ ��������: TRUE - ��� �������� ����������; ����� - FALSE

//BOOL __stdcall pvdPageDecode(void *pContext, UINT32 iPage, pvdInfoDecode *pDecodeInfo, pvdDecodeCallback DecodeCallback, void *pDecodeCallbackContext);
  TpvdPageDecode = function(pContext :Pointer; iPage :UINT; pDecodeInfo :PPVDInfoDecode; DecodeCallback :TPVDDecodeCallback; pDecodeCallbackContext :Pointer) :BOOL; stdcall;


// pvdPageFree - ������������ ��������������� �����������
//  ����������: ����� �������� pvdPageDecode, ����� �������������� ����������� ������ �� �����
//  ���������:
//   pContext    - ��������, ������������ �������� � pvdFileOpen
//   pDecodeInfo - ��������� �� ��������� � ����������� � �������������� �����������, ����������� � pvdPageDecode

//void __stdcall pvdPageFree(void *pContext, pvdInfoDecode *pDecodeInfo);
  TpvdPageFree = procedure(pContext :Pointer; pDecodeInfo :PPVDInfoDecode); stdcall;


// pvdFileClose - �������� �����
//  ����������: ����� �������� pvdFileOpen, ����� ���� ������ �� �����
//  ���������:
//   pContext    - ��������, ������������ �������� � pvdFileOpen

//void __stdcall pvdFileClose(void *pContext);
  TpvdFileClose = procedure(pContext :Pointer); stdcall;


type
  TpvdInit2 = function(pInit :PpvdInitPlugin2) :integer; stdcall;
  TpvdExit2 = procedure(pContext :Pointer); stdcall;
  TpvdPluginInfo2 = procedure(pPluginInfo :PPVDInfoPlugin2); stdcall;
  TpvdReloadConfig2 = procedure(pContext :Pointer); stdcall;

  TpvdGetFormats2 = procedure(pContext :Pointer; pFormats :PPVDFormats2); stdcall;
  TpvdFileOpen2 = function(pContext :Pointer; pFileName :PWideChar; lFileSize :Int64; pBuf :Pointer; lBuf :UINT; pImageInfo :PPVDInfoImage2) :BOOL; stdcall;
  TpvdPageInfo2 = function(pContext :Pointer; pImageContext :Pointer; pPageInfo :PPVDInfoPage2) :BOOL; stdcall;
  TpvdPageDecode2 = function(pContext :Pointer; pImageContext :Pointer; pDecodeInfo :PPVDInfoDecode2; DecodeCallback :TPVDDecodeCallback2; pDecodeCallbackContext :Pointer) :BOOL; stdcall;
  TpvdPageFree2 = procedure(pContext :Pointer; pImageContext :Pointer; pDecodeInfo :PPVDInfoDecode2); stdcall;
  TpvdFileClose2 = procedure(pContext :Pointer; pImageContext :Pointer); stdcall;

  TpvdDisplayInit2 = function(pContext :Pointer; pDisplayInit :PPVDInfoDisplayInit2) :BOOL; stdcall;
  TpvdDisplayAttach2 = function(pContext :Pointer; pDisplayAttach :PPVDInfoDisplayAttach2) :BOOL; stdcall;
  TpvdDisplayCreate2 = function(pContext :Pointer; pDisplayCreate :PPVDInfoDisplayCreate2) :BOOL; stdcall;
  TpvdDisplayPaint2 = function(pContext :Pointer; pDisplayContext :Pointer; pDisplayPaint :PPVDInfoDisplayPaint2) :BOOL; stdcall;
  TpvdDisplayClose2 = procedure(pContext :Pointer; pDisplayContext :Pointer); stdcall;
  TpvdDisplayExit2 = procedure(pContext :Pointer); stdcall;


{------------------------------------------------------------------------------}
{ PVD_IIF_MOVIE                                                                }

const
  PVD_PC_Play      = 1;
  PVD_PC_Pause     = 2;
  PVD_PC_Stop      = 3;
  PVD_PC_GetState  = 4;
  PVD_PC_GetPos    = 5;
  PVD_PC_SetPos    = 6;
  PVD_PC_GetVolume = 7;
  PVD_PC_SetVolume = 8;
  PVD_PC_Mute      = 9;

type
  TpvdPlayControl = function(pContext :Pointer; pImageContext :Pointer; aCmd :Integer; pInfo :Pointer) :Integer; stdcall;


{******************************************************************************}
{******************************} implementation {******************************}
{******************************************************************************}


end.

