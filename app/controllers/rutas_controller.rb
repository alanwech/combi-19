class RutasController < ApplicationController
  def index
    @rutas = Ruta.all
  end

  def new
    @ruta = Ruta.new
    @ciudades = Ciudad.all
    @adicionales = Adicional.all
  end

  def create
    @ciudades = Ciudad.all
    @adicionales = Adicional.all
    @ruta = Ruta.create(params.require(:ruta).permit(:nombre, :ciudadOrigen, :ciudadDestino, :adicional_ids => []))
    if @ruta.save
      redirect_to rutas_path, notice: "La ruta fue creada"
    else
      flash[:error] = "Ha habido un problema al crear la ruta"
      render :new
    end
  end

  def edit
    @ruta = Ruta.find(params[:id])
    @ciudades = Ciudad.all
    @adicionales = Adicional.all
  end

  def show
    @ruta = Ruta.find(params[:id])
  end

  def update
    @ciudades = Ciudad.all
    @adicionales = Adicional.all
    @ruta = Ruta.find(params[:id])
    if @ruta.update(params.require(:ruta).permit(:nombre, :ciudadOrigen, :ciudadDestino, :adicional_ids => []))
      redirect_to rutas_path, notice: "La ruta fue modificada."
    else
      flash[:error] = "Ha habido un problema al crear la ruta."
      render :edit
    end
  end

  def destroy
    Ruta.find(params[:id]).destroy
    redirect_to rutas_path
  end
end
