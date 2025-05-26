program zplangbuilder;

uses
  Forms,
  mainunit in 'mainunit.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
