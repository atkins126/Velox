unit Principal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, System.Sensors, UTM_WGS84,
  System.Sensors.Components, System.DateUtils;

type
  TPosicion = record
    X,Y: Single;
    CG: TLocationCoord2D;
  end;
  TRegistro = record
    PosInicial,
    PosFinal,
    PosAnterior,
    PosActual: TPosicion;
    Rumbo: string;
    DistRecorrida,
    Velocidad,
    Tiempo: single;
    TiempoAnterior,
    TiempoActual: TTime;
    EstaIniciando: boolean;
  end;
  TFPrinc = class(TForm)
    LayTop: TLayout;
    LayBot: TLayout;
    BInicio: TButton;
    SBSalir: TSpeedButton;
    SBAcerca: TSpeedButton;
    BLimpiar: TButton;
    VertScrollBox1: TVertScrollBox;
    LayPosAct: TLayout;
    LayDistRec: TLayout;
    LayVel: TLayout;
    Layout1: TLayout;
    Layout2: TLayout;
    Layout3: TLayout;
    Layout4: TLayout;
    Layout5: TLayout;
    Layout6: TLayout;
    LaySep01: TLayout;
    Layout7: TLayout;
    Layout8: TLayout;
    Layout9: TLayout;
    Layout10: TLayout;
    Layout11: TLayout;
    Layout12: TLayout;
    Layout13: TLayout;
    Layout14: TLayout;
    Layout15: TLayout;
    Label1: TLabel;
    LPosIni: TLabel;
    Label3: TLabel;
    LPosFin: TLabel;
    LEste: TLabel;
    LNorte: TLabel;
    LRumbo: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    LDistRec: TLabel;
    Label11: TLabel;
    LVelocidad: TLabel;
    Layout16: TLayout;
    Layout17: TLayout;
    Layout18: TLayout;
    LctSensor: TLocationSensor;
    procedure SBSalirClick(Sender: TObject);
    procedure BLimpiarClick(Sender: TObject);
    procedure BInicioClick(Sender: TObject);
    procedure LctSensorLocationChanged(Sender: TObject; const OldLocation,
      NewLocation: TLocationCoord2D);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SBAcercaClick(Sender: TObject);
  private
    { Private declarations }
    procedure ValInicio;
    procedure MostrarDatos;
  public
    { Public declarations }
  end;

var
  FPrinc: TFPrinc;
  Reg: TRegistro;
  Separador: char;

implementation

{$R *.fmx}
{$R *.SmXhdpiPh.fmx ANDROID}

/// Utilidades de la app: ///

procedure CargarCoordenadas(CoordGPS: TLocationCoord2D; var CoordPos: TPosicion);
var
  LatLon: TRecLatLon;
  UTM: TRecUTM;
begin
  LatLon.Lat:=CoordGPS.Latitude;
  LatLon.Lon:=CoordGPS.Longitude;
  LatLon_To_UTM(LatLon,UTM);
  CoordPos.CG:=CoordGPS;
  CoordPos.X:=UTM.X;
  CoordPos.Y:=UTM.Y;
end;

function CalcularDistancia(X1,Y1,X2,Y2: double): double;
begin
  Result:=Sqrt(Sqr(Abs(X1-X2))+Sqr(Abs(Y1-Y2)));
end;

function Sentido(Este1,Norte1,Este2,Norte2: Double): string;
var
  Cad: string;
begin
  if (Norte1<Norte2) and (Este1=Este2) then Cad:='Norte';
  if (Norte1>Norte2) and (Este1=Este2) then Cad:='Sur';
  if (Norte1=Norte2) and (Este1<Este2) then Cad:='Este';
  if (Norte1=Norte2) and (Este1>Este2) then Cad:='Oeste';
  if (Norte1<Norte2) and (Este1<Este2) then Cad:='Noreste';
  if (Norte1<Norte2) and (Este1>Este2) then Cad:='Noroeste';
  if (Norte1>Norte2) and (Este1<Este2) then Cad:='Sureste';
  if (Norte1>Norte2) and (Este1>Este2) then Cad:='Suroeste';
  Result:=Cad;
end;

function MetrosToKm(DistMetros: single): single;
begin
  Result:=DistMetros/1000;
end;

function SegundosToHoras(TmpSegs: single): single;
begin
  Result:=TmpSegs/3600;
end;

procedure TFPrinc.ValInicio;
begin
  BInicio.Text:='Inicio';
  LPosIni.Text:='- - -';
  LPosFin.Text:='- - -';
  LEste.Text:='Este (X): - - -';
  LNorte.Text:='Norte (Y): - - -';
  LRumbo.Text:='Rumbo: - - -';
  LDistRec.Text:='0.00';
  LVelocidad.Text:='0.00';
  //se limpia el registro:
  Reg.PosInicial.X:=0;
  Reg.PosInicial.Y:=0;
  Reg.PosInicial.CG.Latitude:=0;
  Reg.PosInicial.CG.Longitude:=0;
  Reg.PosFinal.X:=0;
  Reg.PosFinal.Y:=0;
  Reg.PosFinal.CG.Latitude:=0;
  Reg.PosFinal.CG.Longitude:=0;
  Reg.PosAnterior.X:=0;
  Reg.PosAnterior.Y:=0;
  Reg.PosAnterior.CG.Latitude:=0;
  Reg.PosAnterior.CG.Longitude:=0;
  Reg.PosActual.X:=0;
  Reg.PosActual.Y:=0;
  Reg.PosActual.CG.Latitude:=0;
  Reg.PosActual.CG.Longitude:=0;
  Reg.Rumbo:='';
  Reg.DistRecorrida:=0;
  Reg.Velocidad:=0;
  Reg.Tiempo:=0;
  Reg.EstaIniciando:=true;
end;

procedure TFPrinc.MostrarDatos;
begin
  LPosIni.Text:=FormatFloat('0.00',Reg.PosInicial.X)+' , '+FormatFloat('0.00',Reg.PosInicial.Y);
  LEste.Text:='Este (X): '+FormatFloat('0.00',Reg.PosActual.X);
  LNorte.Text:='Norte (Y): '+FormatFloat('0.00',Reg.PosActual.Y);
  LRumbo.Text:='Rumbo: '+Reg.Rumbo;
  LDistRec.Text:=FormatFloat('#,##0.00',Reg.DistRecorrida);
  LVelocidad.Text:=FormatFloat('0.00',Reg.Velocidad);
end;

/// Eventos de la app: ///

procedure TFPrinc.FormCreate(Sender: TObject);
begin
  Separador:=FormatSettings.DecimalSeparator;
  FormatSettings.DecimalSeparator:='.';
  ValInicio;
end;

procedure TFPrinc.FormDestroy(Sender: TObject);
begin
  FormatSettings.DecimalSeparator:=Separador;
end;

procedure TFPrinc.LctSensorLocationChanged(Sender: TObject; const OldLocation,
  NewLocation: TLocationCoord2D);
var
  Distancia,IntTiempo: single;
begin
  Reg.TiempoActual:=Now;
  //se obtienen las coordenadas (geográficas y UTM):
  CargarCoordenadas(OldLocation,Reg.PosAnterior);
  CargarCoordenadas(NewLocation,Reg.PosActual);
  if Reg.EstaIniciando then
  begin
    Reg.PosInicial:=Reg.PosActual;
    Reg.PosAnterior:=Reg.PosActual;
    Reg.EstaIniciando:=false;
  end;
  Reg.Rumbo:=Sentido(Reg.PosAnterior.X,Reg.PosAnterior.Y,
                     Reg.PosActual.X,Reg.PosActual.Y);
  //se obtiene la distancia inmediata de los dos últimos puntos:
  Distancia:=MetrosToKm(CalcularDistancia(Reg.PosAnterior.X,Reg.PosAnterior.Y,
                                          Reg.PosActual.X,Reg.PosActual.Y));
  Reg.DistRecorrida:=Reg.DistRecorrida+Distancia;
  //se obtiene el intervalo de tiempo de recorrido entre los 2 puntos:
  IntTiempo:=SecondSpan(Reg.TiempoAnterior,Reg.TiempoActual);
  //se calcula la velocidad en km/h:
  Reg.Velocidad:=Distancia/SegundosToHoras(IntTiempo);
  //se muestran los datos:
  MostrarDatos;
  Reg.TiempoAnterior:=Reg.TiempoActual;
end;

procedure TFPrinc.BInicioClick(Sender: TObject);
begin
  LctSensor.Active:=BInicio.Text='Inicio';
  BLimpiar.Visible:=not LctSensor.Active;
  if BInicio.Text='Inicio' then
  begin
    BInicio.Text:='Fin';
    BInicio.TintColor:=TAlphaColorRec.Red;
    //aquí arranca el proceso:
    Reg.TiempoAnterior:=Now;
    Reg.DistRecorrida:=0;
  end
  else
  begin
    BInicio.Text:='Inicio';
    BInicio.TintColor:=TAlphaColorRec.Springgreen;
    //aquí se detiene el proceso:
    Reg.PosFinal:=Reg.PosActual;
    LPosFin.Text:=FormatFloat('0.00',Reg.PosFinal.X)+' , '+
                  FormatFloat('0.00',Reg.PosFinal.Y);
  end;
end;

procedure TFPrinc.BLimpiarClick(Sender: TObject);
begin
  ValInicio;
end;

procedure TFPrinc.SBAcercaClick(Sender: TObject);
begin
  ShowMessage('Velox'+#13#10+'v1.0'+#13#10#13#10+'Autor: Ing. Francisco J. Sáez S.'+
              #13#13#10+'Calabozo, 3 de julio de 2021');
end;

procedure TFPrinc.SBSalirClick(Sender: TObject);
begin
  Application.Terminate;
end;

end.
