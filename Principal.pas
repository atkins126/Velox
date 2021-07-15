unit Principal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Objects, System.Sensors, UTM_WGS84,
  System.Sensors.Components, System.DateUtils, System.Math;

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
    TiempoInicio,
    TiempoFin,
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
    LayTop: TLayout;
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
    VertScrollBox: TVertScrollBox;
    LaySep02: TLayout;
    LaySep03: TLayout;
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
    PnlResumen: TPanel;
    Layout1: TLayout;
    Layout3: TLayout;
    Label1: TLabel;
    Layout4: TLayout;
    LPosIni: TLabel;
    Layout5: TLayout;
    Label3: TLabel;
    Layout6: TLayout;
    LPosFin: TLabel;
    Layout19: TLayout;
    Label7: TLabel;
    Layout20: TLayout;
    BResumen: TButton;
    SBAceptarRes: TSpeedButton;
    Layout21: TLayout;
    LTmpTransc: TLabel;
    Layout22: TLayout;
    Label12: TLabel;
    RBAPie: TRadioButton;
    RBVehiculo: TRadioButton;
    StyleBook: TStyleBook;
    Layout18: TLayout;
    Layout16: TLayout;
    Layout17: TLayout;
    Layout23: TLayout;
    Crcl: TCircle;
    Layout24: TLayout;
    LTotDistRec: TLabel;
    Layout25: TLayout;
    Label13: TLabel;
    Layout26: TLayout;
    Label10: TLabel;
    Layout27: TLayout;
    LVelProm: TLabel;
    procedure SBSalirClick(Sender: TObject);
    procedure BLimpiarClick(Sender: TObject);
    procedure BInicioClick(Sender: TObject);
    procedure LctSensorLocationChanged(Sender: TObject; const OldLocation,
      NewLocation: TLocationCoord2D);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SBAcercaClick(Sender: TObject);
    procedure SBAceptarClick(Sender: TObject);
    procedure BResumenClick(Sender: TObject);
    procedure SBAceptarResClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    procedure ValInicio;
    procedure MostrarDatos;
    procedure MostrarAcerca(Opc: boolean);
    procedure MostrarResumen(Opc: boolean);
  public
    { Public declarations }
  end;

var
  FPrinc: TFPrinc;
  Reg: TRegistro;
  Separador: char;

implementation

{$R *.fmx}

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

function Grados(Norte1,Norte2,DistH: double): double;
begin
  if DistH>0 then Result:=RadToDeg(ArcCos(Abs(Norte1-Norte2)/DistH))
             else Result:=0;
end;

//Grados(Y1,Y2,CalcularDistancia(X1,Y1,X2,Y2);

{function DecAGrados(Valor: Double): double;
var
  sGrad,sMin,sSeg: string;
  xMin,xSeg: Double;
begin
  xMin:=Frac(Valor)*60;
  xSeg:=Frac(xMin)*60;
  sGrad:=FloatToStr(Trunc(Valor));
  sMin:=FloatToStr(Trunc(xMin));
  sSeg:=FloatToStr(Trunc(xSeg));
  Result:=sGrad+'° '+sMin+''' '+sSeg+'"';
end;}

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
  LTmpTransc.Text:='00:00:00';
  LTotDistRec.Text:='- - -';
  LVelProm.Text:='- - -';
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
  LEste.Text:='Este (X): '+Round(Reg.PosActual.X).ToString;
  LNorte.Text:='Norte (Y): '+Round(Reg.PosActual.Y).ToString;
  LRumbo.Text:='Rumbo: '+Reg.Rumbo;
  LDistRec.Text:=FormatFloat('#,##0.00',Reg.DistRecorrida);
  LVelocidad.Text:=FormatFloat('0.00',Reg.Velocidad);
end;

procedure TFPrinc.MostrarAcerca(Opc: Boolean);
begin
  VertScrollBox.Visible:=not Opc;
  PnlAcerca.Visible:=Opc;
  BResumen.Visible:=not Opc;
end;

procedure TFPrinc.MostrarResumen(Opc: Boolean);
begin
  VertScrollBox.Visible:=not Opc;
  PnlResumen.Visible:=Opc;
  SBAcerca.Visible:=not Opc;
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

procedure TFPrinc.FormShow(Sender: TObject);
begin
  PnlAcerca.Visible:=false;
  PnlResumen.Visible:=false;
  {LayPrinc.Scale.X:=;
  LayPrinc.Scale.Y:=;}
end;

procedure TFPrinc.LctSensorLocationChanged(Sender: TObject; const OldLocation,
  NewLocation: TLocationCoord2D);
var
  Distancia,IntTiempo,VelMaxima: single;
begin
  Reg.TiempoActual:=Now;
  //se usa este primitivo método para filtrar posibles lecturas erróneas del GPS:
  if RBAPie.IsChecked then VelMaxima:=35
                      else VelMaxima:=220;
  //se obtienen las coordenadas (geográficas y UTM):
  CargarCoordenadas(OldLocation,Reg.PosAnterior);
  CargarCoordenadas(NewLocation,Reg.PosActual);
  if Reg.EstaIniciando then
  begin
    Reg.PosInicial:=Reg.PosActual;
    Reg.PosAnterior:=Reg.PosActual;
    Reg.EstaIniciando:=false;
  end;
  //se obtiene el intervalo de tiempo de recorrido entre los 2 puntos:
  IntTiempo:=SecondSpan(Reg.TiempoAnterior,Reg.TiempoActual);
  Reg.Tiempo:=Reg.Tiempo+IntTiempo;
  //se obtiene el rumbo:
  Reg.Rumbo:=Sentido(Reg.PosAnterior.X,Reg.PosAnterior.Y,
                     Reg.PosActual.X,Reg.PosActual.Y);
  Crcl.RotationAngle:=90-Grados(Reg.PosAnterior.Y,Reg.PosActual.Y,
                          CalcularDistancia(Reg.PosAnterior.X,Reg.PosAnterior.Y,
                                            Reg.PosActual.X,Reg.PosActual.Y));
  //se obtiene la distancia inmediata de los dos últimos puntos:
  Distancia:=MetrosToKm(CalcularDistancia(Reg.PosAnterior.X,Reg.PosAnterior.Y,
                                          Reg.PosActual.X,Reg.PosActual.Y));
  Reg.DistRecorrida:=Reg.DistRecorrida+Distancia;
  //se calcula la velocidad en km/h:
  Reg.Velocidad:=Distancia/SegundosToHoras(IntTiempo);
  //se muestran los datos:
  if Reg.Velocidad<=VelMaxima then MostrarDatos
  else Reg.DistRecorrida:=Abs(Reg.DistRecorrida-Distancia);
  Reg.TiempoAnterior:=Reg.TiempoActual;
end;

procedure TFPrinc.BInicioClick(Sender: TObject);
begin
  LctSensor.Active:=BInicio.Text='Inicio';
  BResumen.Visible:=not LctSensor.Active;
  BLimpiar.Visible:=BResumen.Visible;
  if BInicio.Text='Inicio' then
  begin
    BInicio.Text:='Fin';
    BInicio.TintColor:=TAlphaColorRec.Red;
    Reg.TiempoInicio:=Now;
    //aquí arranca el proceso:
    Reg.TiempoAnterior:=Now;
    Reg.DistRecorrida:=0;
  end
  else
  begin
    BInicio.Text:='Inicio';
    BInicio.TintColor:=TAlphaColorRec.Springgreen;
    Reg.TiempoFin:=Now;
    Reg.Tiempo:=Reg.TiempoFin-Reg.TiempoInicio;
    //aquí se detiene el proceso:
    Reg.PosFinal:=Reg.PosActual;
    LPosIni.Text:=Round(Reg.PosInicial.X).ToString+' - '+
                  Round(Reg.PosInicial.Y).ToString;
    LPosFin.Text:=Round(Reg.PosFinal.X).ToString+' - '+
                  Round(Reg.PosFinal.Y).ToString;
    LTotDistRec.Text:=FormatFloat('0.00',Reg.DistRecorrida)+' km';
    LTmpTransc.Text:=TimeToStr(FloatToDateTime(Reg.Tiempo));
    LVelProm.Text:=FormatFloat('0.00',Reg.DistRecorrida/SegundosToHoras(Reg.Tiempo))+
                   ' km/h';
  end;
end;

procedure TFPrinc.BLimpiarClick(Sender: TObject);
begin
  ValInicio;
end;

procedure TFPrinc.SBAcercaClick(Sender: TObject);
begin
  MostrarAcerca(true);
end;

procedure TFPrinc.SBAceptarClick(Sender: TObject);
begin
  MostrarAcerca(false);
end;

procedure TFPrinc.BResumenClick(Sender: TObject);
begin
  MostrarResumen(true);
end;

procedure TFPrinc.SBAceptarResClick(Sender: TObject);
begin
  MostrarResumen(false);
end;

procedure TFPrinc.SBSalirClick(Sender: TObject);
begin
  Application.Terminate;
end;

end.

{
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
  Reg.Tiempo:=Reg.Tiempo+IntTiempo;
  //se calcula la velocidad en km/h:
  Reg.Velocidad:=Distancia/SegundosToHoras(IntTiempo);
  //se muestran los datos:
  MostrarDatos;
  Reg.TiempoAnterior:=Reg.TiempoActual;
end;
}
