class AddUsuarioRefToComentarios < ActiveRecord::Migration[6.0]
  def change
    add_reference :comentarios, :usuario, null: false, foreign_key: true
  end
end
