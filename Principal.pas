unit Principal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, System.Sensors, UTM_WGS84,
  System.Sensors.Components, System.DateUtils, FMX.Objects;

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
    LayPrinc: TLayout;
    LayBot: TLayout;
    SBSalir: TSpeedButton;
    SBAcerca: TSpeedButton;
    BLimpiar: TButton;
    Layout18: TLayout;
    LayTop: TLayout;
    Layout1: TLayout;
    Layout3: TLayout;
    Label1: TLabel;
    Layout4: TLayout;
    LPosIni: TLabel;
    Layout5: TLayout;
    Label3: TLabel;
    Layout6: TLayout;
    LPosFin: TLabel;
    Layout2: TLayout;
    BInicio: TButton;
    LctSensor: TLocationSensor;
    PnlAcerca: TPanel;
    Image1: TImage;
    Label2: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    SBAceptar: TSpeedButton;
    VertScrollBox1: TVertScrollBox;
    Layout16: TLayout;
    Layout17: TLayout;
    LayPosAct: TLayout;
    Layout7: TLayout;
    Label8: TLabel;
    Layout8: TLayout;
    Layout9: TLayout;
    LNorte: TLabel;
    Layout10: TLayout;
    LRumbo: TLabel;
    Layout11: TLayout;
    LEste: TLabel;
    LayDistRec: TLayout;
    Layout12: TLayout;
    Label9: TLabel;
    Layout13: TLayout;
    LDistRec: TLabel;
    LayVel: TLayout;
    Layout14: TLayout;
    Label11: TLabel;
    Layout15: TLayout;
    LVelocidad: TLabel;
    LaySep01: TLayout;
    procedure SBSalirClick(Sender: TObject);
    procedure BLimpiarClick(Sender: TObject);
    procedure BInicioClick(Sender: TObject);
    procedure LctSensorLocationChanged(Sender: TObject; const OldLocation,
      NewLocation: TLocationCoord2D);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SBAcercaClick(Sender: TObject);
    procedure SBAceptarClick(Sender: TObject);
  private
    { Private declarations }
    procedure ValInicio;
    procedure MostrarDatos;
    procedure MostrarAcerca(Opc: boolean);
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
  //LPosIni.Text:=FormatFloat('0.00',Reg.PosInicial.X)+','+FormatFloat('0.00',Reg.PosInicial.Y);
  LPosIni.Text:=Round(Reg.PosInicial.X).ToString+','+Round(Reg.PosInicial.Y).ToString;
  LEste.Text:='Este (X): '+Round(Reg.PosActual.X).ToString;
  LNorte.Text:='Norte (Y): '+Round(Reg.PosActual.Y).ToString;
  LRumbo.Text:='Rumbo: '+Reg.Rumbo;
  LDistRec.Text:=FormatFloat('#,##0.00',Reg.DistRecorrida);
  LVelocidad.Text:=FormatFloat('0.00',Reg.Velocidad);
end;

procedure TFPrinc.MostrarAcerca(Opc: Boolean);
begin
  LayTop.Visible:=not Opc;
  LayBot.Visible:=not Opc;
  LayPosAct.Visible:=not Opc;
  LayDistRec.Visible:=not Opc;
  LayVel.Visible:=not Opc;
  PnlAcerca.Visible:=Opc;
end;

/// Eventos de la app: ///

procedure TFPrinc.FormCreate(Sender: TObject);
begin
  Separador:=FormatSettings.DecimalSeparator;
  FormatSettings.DecimalSeparator:='.';
  PnlAcerca.Visible:=false;
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
    {LPosFin.Text:=FormatFloat('0.00',Reg.PosFinal.X)+','+
                  FormatFloat('0.00',Reg.PosFinal.Y); }
    LPosFin.Text:=Round(Reg.PosFinal.X).ToString+','+
                  Round(Reg.PosFinal.Y).ToString;
  end;
end;

procedure TFPrinc.BLimpiarClick(Sender: TObject);
begin
  ValInicio;
end;

procedure TFPrinc.SBAceptarClick(Sender: TObject);
begin
  MostrarAcerca(false);
end;

procedure TFPrinc.SBAcercaClick(Sender: TObject);
begin
  MostrarAcerca(true);
end;

procedure TFPrinc.SBSalirClick(Sender: TObject);
begin
  Application.Terminate;
end;

end.
