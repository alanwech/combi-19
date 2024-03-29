class UsuariosController < ApplicationController

	def index
		@usuarios = Usuario.all
	end

	def choferes_index
		@choferes = Usuario.where(rol:"chofer")
	end

	def edit
		@usuario = Usuario.find(params[:id])
		#if @usuario.rol == "chofer" and (not @usuario.viajes.empty?)
		#	redirect_back(fallback_location: root_path, notice: "El chofer tiene viajes asignados.")
		#end 
	end

	def update	
		@usuario = Usuario.find(params[:id])
	    if @usuario.update params.require(:usuario).permit(:rol)
		  redirect_to usuarios_path, notice: "El rol se actualizó correctamente"
	    else
	      flash[:error] = "Hubo un error al modificar el rol"
	      render :edit
	    end
	end

	def show
		@usuario = Usuario.find(params[:id])
		@viajes_cancelados = []
		@viajes_pendientes = []
		@viajes_realizados = []
		@viajes_no_realizados = []

		if @usuario.rol == "cliente"
			@usuario.pasajes.each do |pasaje|
				@viaje = Viaje.find(pasaje.viaje_id)
				if not @viaje.cancelado?
					if pasaje.default?	
						if @viaje.programado?
							@viajes_pendientes << @viaje
						end
					elsif pasaje.aceptado?
						if @viaje.finalizado?
							@viajes_realizados << @viaje
						elsif @viaje.en_curso?
							@viaje_en_curso = @viaje
						end
					else 
						
						# pasaje rechazado o cancelado
						@viajes_no_realizados << @viaje
					end
				else
					@viajes_cancelados << @viaje
				end 
			end
		elsif @usuario.rol == "chofer"
			@viajes_cancelados = Viaje.where(chofer_id: @usuario.id).cancelado
			@viajes_pendientes = Viaje.where(chofer_id: @usuario.id).programado
			@viajes_realizados = Viaje.where(chofer_id: @usuario.id).finalizado
			if @usuario.current_viaje != 0
				@viaje_en_curso = Viaje.find(@usuario.current_viaje)
			end
		end
	end

	def chofer_dar_de_baja
		usuario=Usuario.find(params[:id])
		if  (usuario.viajes.finalizado.count + usuario.viajes.cancelado.count) == usuario.viajes.count
			usuario.borrado = true;
			usuario.save
			redirect_to choferes_index_path
		else
			redirect_to choferes_index_path , notice: "No se pudo eliminar el chofer porque está asignado a un viaje sin finalizar."
		end
	end

	def mostrar_formulario_covid
		@usuario = Usuario.find(params[:id])
		@viajeID = params[:viaje_id]
		if @usuario.formulario_covid != nil
			redirect_to formulario_covid_path(@usuario.formulario_covid.id, params[:viaje_id])
		else
			redirect_to request.referrer
			flash[:notice] = "El usuario no ha cargado la declaración jurada"
		end
	end

	def eliminar_cuenta
		@usuario = Usuario.find(params[:id])
		if (@usuario.pasajes.default.size + @usuario.pasajes.aceptado.size) == 0
			@usuario.borrado = true
			@usuario.generate_email
			@usuario.save
			redirect_to root_path, notice: "¡Adiós! Tu cuenta fue cancelada. Esperamos volver a verte pronto"
		elsif @usuario.pasajes.aceptado.size == 0 and @usuario.pasajes.default.size != 0
			redirect_to viajes_a_cancelar_path , notice: "Atencion! Todavía tiene viajes programados"
		else
			redirect_to root_path , notice: "No podes eliminar tu cuenta mientras estás viajando"
		end
	end

	def eliminar_cuenta_con_pasajes
		usuarioID = current_usuario.id
		current_usuario.viajes.programado.each do |viaje| # Cancelo pasaje por pasaje de los viajes programados
			pasaje = viaje.pasajes.find_by(usuario_id: usuarioID)
			pasaje.estado = "cancelado"
			viaje.disponibilidad = "disponible"
			pasaje.save
    		viaje.save
    	end
    	current_usuario.borrado = true
		current_usuario.generate_email
		current_usuario.save
  		redirect_to root_path, notice: "¡Adiós! Tu cuenta fue cancelada. Esperamos volver a verte pronto"
	end
end