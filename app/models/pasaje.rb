class Pasaje < ApplicationRecord
	has_and_belongs_to_many :adicionales
	belongs_to :usuario
	belongs_to :viaje

	enum estado: { 	default: "default", 
					aceptado: "aceptado",
					finalizado: "finalizado",
					rechazado_ausente: "rechazado por ausencia", 
					rechazado_covid: "rechazado por síntomas de coronavirus",
					cancelado: "cancelado" }

	def getEstado
		Pasaje.estados.fetch(estado)
	end
end
