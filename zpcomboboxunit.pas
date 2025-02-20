unit zpcomboboxunit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, StdCtrls,
  ExtCtrls, tntclasses, TntStdCtrls;

type
  TBetterComboBox = class;

  { TDropDownForm is a borderless popup form that contains a TListBox to display the items. }
  TDropDownForm = class(TForm)
  private
    FOwnerCombo: TBetterComboBox;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMActivate(var Msg: TWMActivate); message WM_ACTIVATE;
  public
    ListBox: TTNTListBox;
    FIgnoreNextClick   : PBoolean;
    FIgnoreNextClickTS : PInt64;
    constructor CreatePopup(AOwnerCombo: TBetterComboBox);
    procedure ListBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ListBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ListBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OpenAt(const X, Y, AWidth, AHeight: Integer);
    procedure CloseUp;
  end;

  { TBetterComboBox is a drop-down list control (csDropDownList style only)
    that uses an internal TStringList (FItems) to store items.}
  TBetterComboBox = class(TCustomControl)
  private
    FItems: TTNTStrings;
    FItemIndex: Integer;
    FDropDown: TDropDownForm;
    FHasFocus: Boolean;
    FItemHeight: Integer;
    FDropDownCount: Integer;
    FSuppressChangeEvent: Boolean;
    FOnChange: TNotifyEvent;
    function  GetStyle: TComboBoxStyle;
    procedure SetStyle(Value: TComboBoxStyle);
    function  GetItemHeight: Integer;
    procedure SetItemHeight(Value: Integer);
    procedure SetItems(Value: TTNTStrings);
    procedure SetItemIndex(Value: Integer);
    function  GetText: widestring;
    procedure SetText(const Value: widestring);
    function  DropDownVisible: Boolean;
    { Message handlers }
    procedure CMEnter(var Message: TCMEnter); message CM_ENTER;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMGetDlgCode(var Msg: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMKeyDown(var Message: TWMKeyDown); message WM_KEYDOWN;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure ShowDropDown;
    procedure HideDropDown(Accept: Boolean);
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  public
    FIgnoreNextClick   : Boolean;
    FIgnoreNextClickTS : Int64;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
  published
    // Drop-in published properties:
    property Items: TTNTStrings read FItems write SetItems;
    property ItemIndex: Integer read FItemIndex write SetItemIndex default -1;
    property Text: widestring read GetText write SetText;
    property DropDownCount: Integer read FDropDownCount write FDropDownCount default 8;
    property ItemHeight: Integer read GetItemHeight write SetItemHeight default 18;
    property Style: TComboBoxStyle read GetStyle write SetStyle default csDropDownList;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    // Standard published properties
    property Enabled;
    property Align;
    property Anchors;
    property Color;
    property Font;
    property ParentColor;
    property ParentFont;
    property TabOrder;
    property TabStop default True;
    property Visible;
  end;


procedure Register;


implementation

var
  TickCount64Last      : DWORD = 0;
  TickCount64Base      : Int64 = 0;


function GetTickCount64 : Int64;
begin
  Result := GetTickCount;
  If Result < TickCount64Last then
    TickCount64Base := TickCount64Base+$100000000;
  TickCount64Last := Result;
  Result := Result+TickCount64Base;
end;


procedure Register;
begin
  RegisterComponents('Samples', [TBetterComboBox]);
end;

{ TDropDownForm }

constructor TDropDownForm.CreatePopup(AOwnerCombo: TBetterComboBox);
begin
  inherited CreateNew(nil);
  BorderStyle := bsNone;
  FormStyle := fsStayOnTop;
  FOwnerCombo := AOwnerCombo;
  ListBox := TTNTListBox.Create(Self);
  ListBox.Parent := Self;
  ListBox.Align := alClient;
  ListBox.OnMouseMove := ListBoxMouseMove;  // Add this line
  ListBox.OnMouseUp   := ListBoxMouseUp;
  ListBox.OnKeyDown   := ListBoxKeyDown;  // Assign the key handler
  FIgnoreNextClick    := @AOwnerCombo.FIgnoreNextClick;
  FIgnoreNextClickTS  := @AOwnerCombo.FIgnoreNextClickTS;
    {Parent      := AOwnerCombo.Parent;
  Top         := AOwnerCombo.Top+AOwnerCombo.Height;
  Left        := AOwnerCombo.Left;}
end;


procedure TDropDownForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // Create as a popup
  Params.Style := WS_POPUP;
  Params.ExStyle := Params.ExStyle {or WS_EX_NOACTIVATE }or WS_EX_TOOLWINDOW;
  Params.WndParent := GetDesktopWindow;
  {Params.WndParent := FOwnerCombo.Parent.Handle;}
end;


procedure TDropDownForm.OpenAt(const X, Y, AWidth, AHeight: Integer);
begin
  SetBounds(X, Y, AWidth, AHeight);
  Show;
end;


procedure TDropDownForm.CloseUp;
begin
  Hide;
end;


procedure TDropDownForm.ListBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  index: Integer;
begin
  index := ListBox.ItemAtPos(Point(X, Y), True);
  if index <> -1 then
    ListBox.ItemIndex := index;
end;


procedure TDropDownForm.ListBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  // Commit selection on mouse up if an item is selected.
  if ListBox.ItemIndex <> -1 then
    FOwnerCombo.ItemIndex := ListBox.ItemIndex;
  CloseUp;
  FIgnoreNextClick^ := False;
end;


procedure TDropDownForm.ListBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      begin
        if ListBox.ItemIndex <> -1 then
          FOwnerCombo.ItemIndex := ListBox.ItemIndex;
        Key := 0;
        CloseUp;
        FIgnoreNextClick^ := False;
      end;
    VK_ESCAPE:
      begin
        Key := 0;
        CloseUp;
        FIgnoreNextClick^ := False;
      end;
    // You can optionally handle additional keys if needed.
  end;
end;

{ TBetterComboBox }

constructor TBetterComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSuppressChangeEvent := True;
  ControlStyle := [csCaptureMouse, csClickEvents, csDoubleClicks];
  Width := 121;
  Height := 21;
  FItems := TTNTStringList.Create;
  FItemIndex := -1;
  FItemHeight := 18;
  FDropDownCount := 8;
  TabStop := True;
  FIgnoreNextClick   := False;
  FIgnoreNextClickTS := -1;
end;


destructor TBetterComboBox.Destroy;
begin
  FItems.Free;
  if Assigned(FDropDown) then
    FDropDown.Free;
  inherited Destroy;
end;


procedure TBetterComboBox.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style or WS_TABSTOP;
end;


function TBetterComboBox.GetStyle: TComboBoxStyle;
begin
  Result := csDropDownList;
end;


procedure TBetterComboBox.SetStyle(Value: TComboBoxStyle);
begin
  // Ignoring, we only support csDropDownList
end;


procedure TDropDownForm.WMActivate(var Msg: TWMActivate);
begin
  inherited;
  // If the drop-down is being deactivated, close it.
  if Msg.Active = WA_INACTIVE then
  Begin
    FIgnoreNextClick^   := True;
    FIgnoreNextClickTS^ := GetTickCount64;
    CloseUp;
  End;  
end;


function TBetterComboBox.GetItemHeight: Integer;
begin
  Result := FItemHeight;
end;


procedure TBetterComboBox.SetItemHeight(Value: Integer);
begin
  if Value <= 0 then Exit;
  FItemHeight := Value;
  if Assigned(FDropDown) then
    FDropDown.ListBox.ItemHeight := Value;
  Invalidate;
end;

procedure TBetterComboBox.SetItems(Value: TTNTStrings);
begin
  FItems.Assign(Value);
  if FItemIndex >= FItems.Count then
    FItemIndex := -1;
  Invalidate;
end;


procedure TBetterComboBox.SetItemIndex(Value: Integer);
begin
  if Value <> FItemIndex then
  begin
    if (Value < -1) or (Value >= FItems.Count) then
      Value := -1;
    FItemIndex := Value;
    Invalidate;
    if Assigned(FOnChange) and not FSuppressChangeEvent then
      FOnChange(Self);
  end;
end;


function TBetterComboBox.GetText: widestring;
begin
  if (FItemIndex >= 0) and (FItemIndex < FItems.Count) then
    Result := FItems[FItemIndex]
  else
    Result := '';
end;


procedure TBetterComboBox.SetText(const Value: widestring);
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    if WideCompareText(FItems[I], Value) = 0 then
    begin
      ItemIndex := I;
      Exit;
    end;
  ItemIndex := -1;
end;


function TBetterComboBox.DropDownVisible: Boolean;
begin
  Result := Assigned(FDropDown) and FDropDown.Visible;
end;


procedure TBetterComboBox.CMEnter(var Message: TCMEnter);
begin
  inherited;
  FHasFocus := True;
  Invalidate;
end;


procedure TBetterComboBox.CMExit(var Message: TCMExit);
begin
  inherited;
  FHasFocus := False;
  HideDropDown(False);
  Invalidate;
end;


procedure TBetterComboBox.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  Invalidate;
end;


procedure TBetterComboBox.WMGetDlgCode(var Msg: TWMGetDlgCode);
begin
  inherited;
  Msg.Result := Msg.Result or DLGC_WANTARROWS;
end;


procedure TBetterComboBox.WMKeyDown(var Message: TWMKeyDown);
begin
  if DropDownVisible and FDropDown.ListBox.Focused then
    Exit; // Let the list box process arrow keys

  if DropDownVisible then
  begin
    case Message.CharCode of
      VK_DOWN:
        if FDropDown.ListBox.ItemIndex < FItems.Count - 1 then
          FDropDown.ListBox.ItemIndex := FDropDown.ListBox.ItemIndex + 1;
      VK_UP:
        if FDropDown.ListBox.ItemIndex > 0 then
          FDropDown.ListBox.ItemIndex := FDropDown.ListBox.ItemIndex - 1;
      VK_RETURN:
        begin
          HideDropDown(True);
          Message.Result := 0;
          Exit;
        end;
      VK_ESCAPE:
        begin
          HideDropDown(False);
          Message.Result := 0;
          Exit;
        end;
    else
      inherited;
    end;
  end
  else
  begin
    case Message.CharCode of
      VK_DOWN:
        ShowDropDown;
    else
      inherited;
    end;
  end;
end;


procedure TBetterComboBox.Paint;
var
  R, ArrowRect: TRect;
  s: widestring;
  margin: Integer;
  comboBorder: TColor;
  iButtonWidth: Integer;
  BkgColor, TxtColor: TColor;
begin
  inherited Paint;

  if FSuppressChangeEvent = True then
    FSuppressChangeEvent := False;

  Canvas.Font  := Self.Font;
  iButtonWidth := Trunc(Height*0.75);

  if Enabled = False then
  begin
    // Use a disabled appearance.
    BkgColor := clScrollbar;
    TxtColor := clGrayText;
  end
    else
  begin
    BkgColor := Color;
    TxtColor := Font.Color;
  end;

  R := ClientRect;
  if DropDownVisible then
    Canvas.Brush.Color := clBtnFace
  else
    Canvas.Brush.Color := BkgColor;
  Canvas.FillRect(R);
  if FHasFocus then
    comboBorder := clHighlight
  else
    comboBorder := clScrollbar;
  Canvas.Pen.Color := comboBorder;
  Canvas.Rectangle(R);
  if FHasFocus then
  begin
    InflateRect(R, -3, -3);
    Dec(R.Right,iButtonWidth);
    Canvas.DrawFocusRect(R);
  end;

  ArrowRect := ClientRect;
  ArrowRect.Left := ArrowRect.Right - iButtonWidth;

  DrawFrameControl(Canvas.Handle, ArrowRect, DFC_SCROLL,
    DFCS_SCROLLCOMBOBOX or DFCS_FLAT or DFCS_TRANSPARENT);

  R := ClientRect;
  R.Right := R.Right - iButtonWidth;
  margin := 4;
  InflateRect(R, -margin, 0);
  if (FItemIndex >= 0) and (FItemIndex < FItems.Count) then
    s := FItems[FItemIndex]
  else
    s := '';
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Color := TxtColor;  
  DrawTextW(Canvas.Handle, PWideChar(s), Length(s), R, DT_SINGLELINE or DT_VCENTER or DT_LEFT);
end;


procedure TBetterComboBox.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (FIgnoreNextClick = True) and (GetTickCount64 - FIgnoreNextClickTS < 100) then
  begin
    FIgnoreNextClick := False;
    Exit;
  end;
  FIgnoreNextClickTS := -1;

  inherited MouseDown(Button, Shift, X, Y);

  if DropDownVisible then
  Begin
    HideDropDown(False);
  End
    else
  Begin
    SetFocus;
    ShowDropDown;
  End;
end;


procedure TBetterComboBox.ShowDropDown;
var
  P: TPoint;
  DropHeight, CountToShow: Integer;
  TM: TTextMetric;
begin
  if FItems.Count = 0 then Exit;
  if not Assigned(FDropDown) then
    FDropDown := TDropDownForm.CreatePopup(Self);
  FDropDown.ListBox.Font.Assign(Font);
  FDropDown.ListBox.Items.Assign(FItems);
  FDropDown.ListBox.ItemIndex := FItemIndex;
  FDropDown.ListBox.ItemHeight := FItemHeight;
  CountToShow := FItems.Count;

  if CountToShow > FDropDownCount then CountToShow := FDropDownCount;

  SelectObject(FDropDown.ListBox.Canvas.Handle, Font.Handle);
  GetTextMetrics(FDropDown.ListBox.Canvas.Handle, TM);

  DropHeight := TM.tmHeight * CountToShow + (FDropDown.ListBox.Height-FDropDown.ListBox.ClientHeight);

  P := ClientToScreen(Point(0, Height));
  FDropDown.OpenAt(P.X, P.Y, Width, DropHeight);
  FDropDown.ListBox.SetFocus;  // Transfer focus so arrow keys work.

  Invalidate;
end;


procedure TBetterComboBox.HideDropDown(Accept: Boolean);
begin
  if DropDownVisible then
  begin
    if Accept and (FDropDown.ListBox.ItemIndex <> -1) then
      ItemIndex := FDropDown.ListBox.ItemIndex;
    FDropDown.CloseUp;
    Invalidate;
  end;
end;


procedure TBetterComboBox.Clear;
begin
  FItems.Clear;
  FItemIndex := -1;
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;


procedure TBetterComboBox.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;  // Force a repaint when Enabled changes
end;


end.

