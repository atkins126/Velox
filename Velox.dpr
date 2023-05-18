program Velox;

uses
  System.StartUpCopy, System.SysUtils,
  Androidapi.JNI.App,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.Helpers,
  FMX.Forms,
  Principal in 'Principal.pas' {FPrinc};

{$R *.res}

begin
  Application.Initialize;
  TAndroidHelper.Activity.getWindow.addFlags(
    TJWindowManager_LayoutParams.JavaClass.FLAG_KEEP_SCREEN_ON);
  Application.CreateForm(TFPrinc, FPrinc);
  Application.Run;
end.
