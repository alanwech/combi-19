class Adicional < ApplicationRecord
    self.table_name = "adicionales"

    has_and_belongs_to_many :rutas
    has_and_belongs_to_many :pasajes
end
