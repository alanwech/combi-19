# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Ciudad.find_or_create_by(nombre: "Rosario")
Ciudad.find_or_create_by(nombre: "Córdoba")
Ciudad.find_or_create_by(nombre: "Retiro")
Ciudad.find_or_create_by(nombre: "Constitución")
Ciudad.find_or_create_by(nombre: "La Plata")
Ciudad.find_or_create_by(nombre: "Mar del Plata")

Ruta.find_or_create_by( nombre: "Constitución - Rosario",
                        ciudadOrigen: "Constitución",
                        ciudadDestino: "Rosario")

Ruta.find_or_create_by( nombre: "Retiro - La Plata",
                        ciudadOrigen: "Retiro",
                        ciudadDestino: "La Plata")

Adicional.find_or_create_by( nombre: "Café",
                             descripcion: "Café con leche",
                             precio: 99.9)

Adicional.find_or_create_by( nombre: "Medialuna",
                             descripcion: "Dos medialunas de grasa o manteca",
                             precio: 80)

Combi.find_or_create_by( patente: "AA123BB", 
                         asientos: 12,
                         modelo: "Mercedes")

Combi.find_or_create_by( patente: "CCC456",
                         asientos: 14,
                         modelo: "Ford")

Usuario.find_or_create_by( nombre: "Nombre", 
                           apellido: "Apellido",
                           dni: 9999,
                           email: "admin@admin.com",
                           fecha_nacimiento: Date.new(1960,10,30),
                           password: "asdasd",
                           rol: "admin")

Usuario.find_or_create_by( nombre: "Nombre", 
                           apellido: "Apellido",
                           dni: 9998,
                           email: "chofer@chofer.com",
                           fecha_nacimiento: Date.new(1960,10,30),
                           password: "asdasd",
                           rol: "chofer")

Usuario.find_or_create_by( nombre: "Nombre",
                           apellido: "Apellido",
                           dni: 9997,
                           email: "cliente@cliente.com",
                           fecha_nacimiento: Date.new(1960,10,30),
                           password: "asdasd",
                           rol: "cliente")
