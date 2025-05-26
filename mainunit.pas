unit mainunit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, TntStdCtrls;

type
  TMainForm = class(TForm)
    LabelEnglishDialog: TTntLabel;
    InEnglishEdit: TTntEdit;
    LabelTransDialog: TTntLabel;
    InTransEdit: TTntEdit;
    LabelOutputDialog: TTntLabel;
    OutTransEdit: TTntEdit;
    ButtonRebuild: TTntButton;
    ListBoxDebug: TTntListBox;
    procedure ButtonRebuildClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure DebugMsg(S : WideString);
    procedure ReconstructLanguageFile(inFileEnglish,inFileTrans,outFile : WideString);
    procedure LoadConfig;
    procedure SaveConfig;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses TNTClasses, StrUtils;

const
  RegKeyPath  : HKEY        = HKEY_CURRENT_USER;
  RegPath     : AnsiString  = 'Software\VirtuaMedia\ZPLangBuilder';


function UTF8StringToWideString(Const S : UTF8String) : WideString;
var
  iLen : Integer;
  sw   : WideString;
begin
  If Length(S) = 0 then
  Begin
    Result := '';
    Exit;
  End
    else
  Begin
    iLen := MultiByteToWideChar(CP_UTF8,0,PAnsiChar(s),-1,nil,0);
    SetLength(sw,iLen);
    MultiByteToWideChar(CP_UTF8,0,PAnsiChar(s),-1,PWideChar(sw),iLen);
    iLen := Pos(#0,sw);
    If iLen > 0 then SetLength(sw,iLen-1);
    Result := sw;
  End;
end;


function WideStringToUTF8String(const Source: WideString): AnsiString;
var
  Size: Integer;
begin
  Result := '';
  If Source = '' then Exit;

  // Calculate the required size for the buffer
  Size := WideCharToMultiByte(CP_UTF8, 0, PWideChar(Source), Length(Source), nil, 0, nil, nil);
  SetLength(Result, Size);

  // Perform the conversion
  WideCharToMultiByte(CP_UTF8, 0, PWideChar(Source), Length(Source), PAnsiChar(Result), Size, nil, nil);
end;


procedure FixLength(var sSource : String; bSize : Integer);
begin
  If sSource[bSize] = #0 then SetLength(sSource,bSize-1) else SetLength(sSource,bSize);
end;


procedure TMainForm.DebugMsg(S : WideString);
begin
  ListBoxDebug.Items.Add(S);
  Application.ProcessMessages;
end;


procedure TMainForm.ReconstructLanguageFile(inFileEnglish,inFileTrans,outFile : WideString);
var
  I           : Integer;
  iIndex      : Integer;
  lIndex      : Integer;
  inListEng   : TTNTStringList;
  inListTrans : TTNTStringList;
  outList     : TTNTStringList;
  tagPos      : Integer;
  tagPos2     : Integer;
  iCountEng   : Integer;
  iCountTrans : Integer;
  S           : WideString;

  function FindTranslatedIndex(sEntry : WideString) : Integer;
  var
    iLoop : Integer;
  begin
    Result := -1;
    For iLoop := 0 to inListTrans.Count-1 do
      If Pos(sEntry,inListTrans[iLoop]) = 1 then
    Begin
      Result := iLoop;
      Break;
    End;
  end;


begin
  ListBoxDebug.Clear;
  Application.ProcessMessages;

  DebugMsg('Debug messages :');
  DebugMsg('');

  inListEng   := TTNTStringList.Create;
  inListTrans := TTNTStringList.Create;
  outList     := TTNTStringList.Create;

  Try
    inListEng.LoadFromFile(inFileEnglish);
  Except
    DebugMsg('Error opening input file "'+inFileEnglish+'"');
  End;

  Try
    inListTrans.LoadFromFile(inFileTrans);
  Except
    DebugMsg('Error opening input file "'+inFileTrans+'"');
  End;

  If (inListEng.Count > 0) and (inListTrans.Count > 0) then
  Begin
    // Copy over comments
    For lIndex := 0 to inListTrans.Count-1 do
    Begin
      If (inListTrans[lIndex] = '') or (inListTrans[lIndex][1] = '#') then
        outList.Add(inListTrans[lIndex]) else
        Break;
    End;

    // Start the rebuild process
    iIndex := 0;
    While (iIndex < inListEng.Count) do
    Begin
      If Length(inListEng[iIndex]) > 3 then
      Begin
        If inListEng[iIndex][3] = ':' then
        Begin
          // New element found
          Case inListEng[iIndex][2] of
            'F' : // Form caption
            Begin
              lIndex  := FindTranslatedIndex(Copy(inListEng[iIndex],1,3));
              If lIndex = -1 then
              Begin
                outList.Add(inListEng[iIndex]);
                DebugMsg('Missing form title "'+inListEng[iIndex]+'" in translated file, adding English version at output line "'+IntToStr(outList.Count)+'"');
              End
              Else outList.Add(inListTrans[lIndex]);

              Inc(iIndex);
            End;
            'L',  // TTNTLabel
            'B',  // TTNTButton
            'S',  // TTNTSpeedButton
            'V',  // TBeveles
            'G',  // TTNTGroupBox
            'C',  // TTNTCheckBox
            'A' : // TTNTRadioButton
            Begin
              tagPos := Pos('|',inListEng[iIndex]);
              If tagPos > 0 then
              Begin
                lIndex := FindTranslatedIndex(Copy(inListEng[iIndex],1,tagPos));
                If lIndex = -1 then
                Begin
                  outList.Add(inListEng[iIndex]);
                  DebugMsg('Missing object "'+inListEng[iIndex]+'" in translated file, adding English version at output line "'+IntToStr(outList.Count)+'"');
                End
                Else outList.Add(inListTrans[lIndex]);
              End
              Else DebugMsg('Bad formatting on "'+inListEng[iIndex]+'"');
              Inc(iIndex);
            End;
            'I',  // TTNTListBox
            'T',  // TTNTTabControl
            'P',  // TTNTPageControl
            'O',  // TTNTCheckListBox
            'X',  // TTNTComboBox
            'R' : // TTNTRadioGroup
            Begin
              tagPos := Pos('|',inListEng[iIndex]);
              If tagPos > 0 then
              Begin
                iCountEng := StrToIntDef(Copy(inListEng[iIndex],tagPos+1,3),-1);

                If iCountEng > -1 then
                Begin
                  lIndex := FindTranslatedIndex(Copy(inListEng[iIndex],1,tagPos));
                  If lIndex = -1 then
                  Begin
                    DebugMsg('Missing object "'+inListEng[iIndex]+'" in translated file, adding English version starting at output line "'+IntToStr(outList.Count)+'"');
                    outList.Add(inListEng[iIndex]);
                    For I := 0 to iCountEng-1 do
                    Begin
                      Inc(iIndex);
                      outList.Add(inListEng[iIndex]);
                    End;
                  End
                    else
                  Begin
                    iCountTrans := StrToIntDef(Copy(inListTrans[lIndex],tagPos+1,3),-1);

                    If iCountTrans > -1 then
                    Begin
                      If iCountTrans = iCountEng then
                      Begin
                        outList.Add(inListTrans[lIndex]);
                        // Count match, just copy over all the translated text
                        For I := 0 to iCountTrans-1 do
                        Begin
                          Inc(lIndex);
                          outList.Add(inListTrans[lIndex]);
                        End;
                        Inc(iIndex,iCountEng);
                      End
                        else
                      If iCountEng > iCountTrans then
                      Begin
                        // English count is larger than translated text, copy translated text and top it off with the english texts
                        DebugMsg(IntToStr(iCountEng-iCountTrans)+' sub-items missing "'+inListTrans[lIndex]+'", adding missing entries from English version starting at output line "'+IntToStr(outList.Count)+'"');

                        // Delete old count
                        S := inListTrans[lIndex];
                        Delete(S,tagPos+1,3);
                        // Insert new count
                        Insert(Copy(inListEng[iIndex],tagPos+1,3),S,tagPos+1);
                        inListTrans[lIndex] := S;
                        outList.Add(inListTrans[lIndex]);

                        For I := 0 to iCountTrans-1 do
                        Begin
                          Inc(lIndex);
                          outList.Add(inListTrans[lIndex]);
                        End;
                        Inc(iIndex,iCountTrans);
                        For I := iCountTrans to iCountEng-1 do
                        Begin
                          Inc(iIndex);
                          outList.Add(inListEng[iIndex]);
                        End;
                      End
                        else
                      If iCountEng < iCountTrans then
                      Begin
                        // Translated count is larger than english count, copy translated text, but only according to the number of English items
                        DebugMsg(IntToStr(iCountTrans-iCountEng)+' too many sub-items on "'+inListTrans[lIndex]+'", review proper translation at output line "'+IntToStr(outList.Count)+'"');

                        // Delete old count
                        S := inListTrans[lIndex];
                        Delete(S,tagPos+1,3);
                        // Insert new count
                        Insert(Copy(inListEng[iIndex],tagPos+1,3),S,tagPos+1);
                        inListTrans[lIndex] := S;
                        outList.Add(inListTrans[lIndex]);
                        For I := 0 to iCountEng-1 do
                        Begin
                          Inc(lIndex);
                          outList.Add(inListTrans[lIndex]);
                        End;
                        Inc(iIndex,iCountEng);
                      End;
                    End
                      else
                    Begin
                      DebugMsg('Invalid translated sub-item count on "'+inListTrans[lIndex]+'", adding English version at output line "'+IntToStr(outList.Count)+'"');
                      outList.Add(inListEng[iIndex]);
                      For I := 0 to iCountEng-1 do
                      Begin
                        Inc(iIndex);
                        outList.Add(inListEng[iIndex]);
                      End;
                    End;
                  End;
                End
                Else DebugMsg('Invalid sub-item count on "'+inListEng[iIndex]+'" in English source line "'+IntToStr(iIndex)+'"');
              End
              Else DebugMsg('Bad formatting on "'+inListEng[iIndex]+'" in English source line "'+IntToStr(iIndex)+'"');
              Inc(iIndex);
            End;
            // Case Else
            else
            Begin
              DebugMsg('Unknown Object type "'+inListEng[iIndex]+'" in English source line "'+IntToStr(iIndex)+'"');
              Inc(iIndex);
            End;
          End;
        End
        Else Inc(iIndex);
      End
      Else Inc(iIndex);
    End;

    If outList.Count > 0 then
    Try
      outList.SaveToFile(outFile);
    Except
      DebugMsg('Error creating output file "'+outFile+'"');
    End;
  End;

  DebugMsg('');
  DebugMsg('Operation complete');

  outList.Free;
  inListTrans.Free;
  inListEng.Free;
end;


procedure TMainForm.ButtonRebuildClick(Sender: TObject);
begin
  ReconstructLanguageFile(InEnglishEdit.Text,InTransEdit.Text,OutTransEdit.Text);
end;


procedure TMainForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  If Key = #27 then
  Begin
    Key := #0;
    Close;
  End;
end;


procedure TMainForm.FormResize(Sender: TObject);
begin
  ListBoxDebug.Width  := clientWidth-(ListBoxDebug.Left*2);
  ListBoxDebug.Height := clientHeight-(ListBoxDebug.Top+(InEnglishEdit.Top));
  InEnglishEdit.Width := clientWidth-(InEnglishEdit.Left+ButtonRebuild.Width+InEnglishEdit.Top*2);
  InTransEdit.Width   := InEnglishEdit.Width;
  OutTransEdit.Width  := InEnglishEdit.Width;
  ButtonRebuild.Left  := (ListBoxDebug.Left+ListBoxDebug.Width)-ButtonRebuild.Width;
end;


procedure TMainForm.LoadConfig;
var
  RegHandle : HKey;
  ErrCode   : Integer;
  RegType   : LPDWord;
  BufSize   : LPDWord;
  S         : AnsiString;
begin
  ErrCode := RegOpenKeyEx(RegKeyPath,PChar(RegPath),0,KEY_ALL_ACCESS,RegHandle);
  If ErrCode = ERROR_SUCCESS then
  Begin
    New(RegType);
    New(BufSize);

    RegType^ := Reg_SZ;

    SetLength(S,4096);
    BufSize^ := 4096;
    If RegQueryValueEx(RegHandle,'OPEnglishFile',nil,RegType,@S[1],BufSize) = ERROR_SUCCESS then
    Begin
      If BufSize^ > 0 then FixLength(S,BufSize^) else S := '';
      InEnglishEdit.Text := UTF8StringToWideString(S);
    End;

    SetLength(S,4096);
    BufSize^ := 4096;
    If RegQueryValueEx(RegHandle,'OPTransFile',nil,RegType,@S[1],BufSize) = ERROR_SUCCESS then
    Begin
      If BufSize^ > 0 then FixLength(S,BufSize^) else S := '';
      InTransEdit.Text := UTF8StringToWideString(S);
    End;

    SetLength(S,4096);
    BufSize^ := 4096;
    If RegQueryValueEx(RegHandle,'OPOutputFile',nil,RegType,@S[1],BufSize) = ERROR_SUCCESS then
    Begin
      If BufSize^ > 0 then FixLength(S,BufSize^) else S := '';
      OutTransEdit.Text := UTF8StringToWideString(S);
    End;

    Dispose(RegType);
    Dispose(BufSize);
  End;
end;


procedure TMainForm.SaveConfig;
var
  RegHandle : HKey;
  I         : Integer;
  ErrCode   : Integer;
  S         : AnsiString;
begin
  ErrCode := RegCreateKeyEx(RegKeyPath,PChar(RegPath),0,nil,REG_OPTION_NON_VOLATILE,KEY_ALL_ACCESS,nil,RegHandle,@I);
  If ErrCode = ERROR_SUCCESS then
  Begin
    If InEnglishEdit.Text = '' then S := #0 else S := WideStringToUTF8String(InEnglishEdit.Text);
    RegSetValueEx(RegHandle,'OPEnglishFile',0,REG_SZ,@S[1],Length(S));

    If InTransEdit.Text = '' then S := #0 else S := WideStringToUTF8String(InTransEdit.Text);
    RegSetValueEx(RegHandle,'OPTransFile',0,REG_SZ,@S[1],Length(S));

    If OutTransEdit.Text = '' then S := #0 else S := WideStringToUTF8String(OutTransEdit.Text);
    RegSetValueEx(RegHandle,'OPOutputFile',0,REG_SZ,@S[1],Length(S));
  End;
end;


procedure TMainForm.FormShow(Sender: TObject);
begin
  LoadConfig;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveConfig;
end;

end.
