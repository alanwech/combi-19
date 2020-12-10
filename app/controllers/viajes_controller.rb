class ViajesController < ApplicationController
  def index
    @ciudadOrigen = search_params.dig(:ciudadOrigen)
    @ciudadDestino = search_params.dig(:ciudadDestino)

    @fecha_viaje_preparse = search_params.dig(:fecha_viaje)
    @fecha_viaje = (@fecha_viaje_preparse.to_s).to_datetime
    @fecha_checked = search_params.dig(:fecha_checked)

    if (not usuario_signed_in?) or current_usuario.rol == "cliente"
      @estado = "programado"
      @estado_checked = true
      @disponibilidad = "disponible"
      @disponibilidad_checked = true
    else
      @estado = search_params.dig(:estado)
      @estado_checked = search_params.dig(:estado_checked)

      @disponibilidad = search_params.dig(:disponibilidad)
      @disponibilidad_checked = search_params.dig(:disponibilidad_checked)
    end

    #byebug #DEBUG

    # FILTRADO POR CIUDAD DE ORIGEN Y DESTINO
    if (@ciudadOrigen.present? and @ciudadDestino.present?) # Si estan en Nil da false, sino da true
      @ruta = Ruta.where(ciudadOrigen: @ciudadOrigen).where(ciudadDestino: @ciudadDestino)
      @viajes = Viaje.where(ruta: @ruta).order(fecha_hora: :asc)
    elsif(@ciudadOrigen.present?)
      @ruta = Ruta.where(ciudadOrigen: @ciudadOrigen)
      @viajes = Viaje.where(ruta: @ruta).order(fecha_hora: :asc)
    elsif(@ciudadDestino.present?)
      @ruta = Ruta.where(ciudadDestino: @ciudadDestino)
      @viajes = Viaje.where(ruta: @ruta).order(fecha_hora: :asc)
    else
      @viajes = Viaje.order(fecha_hora: :asc).all
    end
    #@ruta = Ruta.where(ciudadOrigen: @ciudadOrigen).where(ciudadDestino: @ciudadDestino)
    #@viajes = Viaje.where(ruta: @ruta).where(disponibilidad: @disponibilidad).where(estado: @estado)

    #UNUSED @viajes = @viajes.where("fecha_hora >": @fecha_viaje) si la fecha pasada es menor que la de la db

    # FILTRADO POR FECHA
    if (@fecha_checked and (not @estado_checked) and (not @disponibilidad_checked))
      temp = []

      @viajes.each do |viaje|
        if (viaje.fecha_hora.year == @fecha_viaje.year and
          viaje.fecha_hora.yday == @fecha_viaje.yday) # yday = dia del año (1 a 365)

        temp << viaje # Los viajes que caen en ese dia se agregan a temp
        end
      @viajes = temp # Muestro solo los viajes de temp
      end
    end


    # FILTRADO POR ESTADO
    if (@estado_checked) 
      @viajes = @viajes & Viaje.where(estado: @estado).order(fecha_hora: :asc)
    end

    # FILTRADO POR DISPONIBILIDAD
    if (@disponibilidad_checked)
      @viajes = @viajes & Viaje.where(disponibilidad: @disponibilidad).order(fecha_hora: :asc)
    end

    @combis = Combi.all
    @ciudades = Ciudad.all
  end

  def search_params
    #params.permit(search: {})
    params.permit(:ciudadOrigen, :ciudadDestino,
                  :fecha_viaje, :fecha_checked,
                  :estado, :estado_checked,
                  :disponibilidad, :disponibilidad_checked)
  end

  def new
    @viaje = Viaje.new
    @rutas = Ruta.all
    @combis = Combi.all.where(borrado: false)
    @choferes = Usuario.where(rol: "chofer").where(borrado: false)
  end

  def create
    @rutas = Ruta.all
    @combis = Combi.all.where(borrado: false)
    @choferes = Usuario.where(rol: "chofer").where(borrado: false)
    @viaje = Viaje.new(viaje_params)

    if @viaje.fecha_hora - Time.now > 1.days
      if @viaje.save
        @viaje.agregar_viaje_a_chofer
        redirect_to viajes_path, notice: "El viaje fue creado"
      else
        flash[:notice] = "Ha habido un problema al crear el viaje"
        render :new
      end
    else
      @viaje.errors.add(:fecha_hora, "El horario del viaje debe ser al menos 24hs desde ahora")
      render :new
    end
  end

  def show
    @viaje = Viaje.find(params[:id])
    @chofer = Usuario.find(@viaje.chofer_id)

    @tiene_viaje = current_usuario.viaje_ids.include?(@viaje.id)
    
    @comentarios = @viaje.comentarios.order(created_at: :desc)
    @comentario = Comentario.new
  end

  def update
    @rutas = Ruta.all
    @combis = Combi.all.where(borrado: false)
    @choferes = Usuario.where(rol: "chofer").where(borrado: false)
    @viaje = Viaje.find(params[:id])
    
    @choferID = @viaje.chofer_id

    if @viaje.update(viaje_params)
      # me fijo si cambió de chofer
      if @viaje.chofer_id != @choferID
        Usuario.find(@choferID).viajes.destroy(@viaje)
        @viaje.agregar_viaje_a_chofer
      end
      redirect_to viajes_path, notice: "El viaje fue modificado"
    else
      flash[:notice] = "Ha habido un problema al modificar el viaje"
      render :edit
    end
  end

  def edit
    @viaje = Viaje.find(params[:id])
    @rutas = Ruta.all
    @combis = Combi.all.where(borrado: false)
    @choferes = Usuario.where(rol: "chofer").where(borrado: false)
  end

  def destroy
    @viaje = Viaje.find(params[:id])
    if DateTime.now.between?(@viaje.fecha_hora, @viaje.fecha_hora_llegada)
      flash[:notice] = "No se puede eliminar un viaje en curso."
    else
      @chofer = Usuario.find(@viaje.chofer_id)
      @chofer.viajes.destroy(@viaje)
      @viaje.combi.viajes.destroy(@viaje)
      @viaje.destroy
      flash[:notice] = "El viaje fue eliminado."
    end
    redirect_to viajes_path
  end

  def comprar
      params.permit(:tarjeta, :adicionales)
      @viaje = Viaje.find(params[:id])
      @tarjeta = params[:tarjeta]
      @adicionales = params.dig(:adicionales,:ids)
      @clave = params[:clave]
      @commit = params[:commit]
      if @commit.present?
        if @tarjeta.present? and @clave.present?
          if @viaje.usuarios.size <= @viaje.combi.asientos
            p=Pasaje.new
            if @adicionales.present?
              for i in 1..@adicionales.size-1 do
                a = Adicional.find(@adicionales[i].to_i)
                p.adicionales << a
              end
            end
            p.usuario_id = current_usuario.id
            p.viaje_id = params[:id]
            p.save
            @viaje.usuarios << current_usuario
            if @viaje.usuarios.size == @viaje.combi.asientos
              @viaje.disponibilidad = "completo"
              @viaje.save
            end
            redirect_to viajes_path, notice:"La compra se concreto correctamente"
          else
            redirect_to viajes_path, notice:"Ya no quedan pasajes disponibles"
          end
        else
          redirect_to comprar_viaje_path(@viaje), notice: "Ingrese una tarjeta y su clave correspondiente"
        end
      end
  end
  
  def cambiar_estado
    @viaje = Viaje.find(params[:id])
    @chofer = Usuario.find(@viaje.chofer_id)
    if @viaje.programado?
      @viaje.estado = "en_curso"
    elsif @viaje.en_curso?
      @viaje.estado = "finalizado"
    end
    if not @viaje.save
      flash[:notice] = "Hubo un error al procesar la solicitud."
    end
    redirect_to viaje_path(@viaje)
  end

  def aceptar_pasajero
    @viaje = Viaje.find(params[:viaje_id])
    @pasaje = @viaje.pasajes.find_by(usuario_id: params[:usuario_id])
    @pasaje.estado = "aceptado"
    if @pasaje.save
      flash[:notice] = "Usuario aceptado"
    else
      flash[:notice] = "Hubo un error al aceptar el pasajero."
    end
    redirect_to viaje_path(@viaje)
  end

  def motivo_rechazo_pasajero
    # GET
    @viaje = Viaje.find(params[:viaje_id])
    @pasaje = @viaje.pasajes.find_by(usuario_id: params[:usuario_id])
  end

  def rechazar_pasajero
    # POST
    @viaje = Viaje.find(params[:viaje_id])
    @usuarioID = params[:usuario_id]
    @pasaje = @viaje.pasajes.find_by(usuario_id: @usuarioID)

    @pasaje.estado = params[:estado]
    if @pasaje.save
      MensajesMailer.with(pasaje_id: @pasaje.id).pasajero_rechazado_email.deliver_now
      flash[:notice] = "Usuario rechazado"
      redirect_to viaje_path(@viaje.id)
    else
      flash[:notice] = "Hubo un error al rechazar el pasajero."
      redirect_to viaje_path(@viaje.id)
    end
  end

  private
  def viaje_params
    params.require(:viaje).permit(:ruta_id, :combi_id, :chofer_id, :precio, :fecha_hora)

    #DEBUG
    #params.require(:viaje).permit(:ruta_id, :combi_id, :chofer_id, :precio)
    #DEBUG
  end

end
