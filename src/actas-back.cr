require "kemal"
require "csv"
require "json"
require "./utils"

alias DataCSV = NamedTuple(codigo: String, estado: String, codigo_municipio: String, municipio: String, codigo_parroquia: String, parroquia: String, centro: String, mesa: String, votos_validos: String, votos_nulos: String, eg: String, nm: String, url: String)

page_cached = Hash(Int16, Array(Array(DataCSV))).new

before_all do |env|
  env.response.content_type = "application/json"
end

get "/" do
  {response: "hello"}.to_json
end

get "/lista" do
  File.read(File.join([Kemal.config.public_folder, "venezuela.json"]))
end

get "/actas/search" do |ctx|
  csv_data = Utils.getData

  estados = [] of String
  data = [] of DataCSV
  codigo : String?
  codigo_mun : String?
  codigo_par : String?
  unless ctx.params.query.empty?
    if ctx.params.query.size >= 1
      codigo = ctx.params.query["cod_estado"]
    end

    if ctx.params.query.size >= 2
      codigo_mun = ctx.params.query["cod_mun"]
    end

    if ctx.params.query.size >= 3
      codigo_par = ctx.params.query["cod_par"]
    end
  end

  while csv_data.next
    unless codigo.nil?
      if csv_data["COD_EDO"] != codigo
        next
      end
      unless codigo_mun.nil?
        if csv_data["COD_MUN"] != codigo_mun
          next
        end
        unless codigo_par.nil?
          if csv_data["COD_PAR"] != codigo_par
            next
          end
        end
      end
    end
    data << {
      codigo:           csv_data["COD_EDO"],
      estado:           csv_data["EDO"],
      codigo_municipio: csv_data["COD_MUN"],
      municipio:        csv_data["MUN"],
      codigo_parroquia: csv_data["COD_PAR"],
      parroquia:        csv_data["PAR"],
      centro:           csv_data["CENTRO"],
      mesa:             csv_data["MESA"],
      votos_validos:    csv_data["VOTOS_VALIDOS"],
      votos_nulos:      csv_data["VOTOS_NULOS"],
      eg:               csv_data["EG"],
      nm:               csv_data["NM"],
      url:              csv_data["URL"],
    }
  end

  data.to_json
end

get "/actas" do |ctx|
  size_page = ctx.params.query["limit"].to_i16 - 1
  page = ctx.params.query["page"].to_i16 - 1

  if page_cached.has_key?(size_page)
    next page_cached[size_page][page].to_json
  end

  data = [[] of DataCSV] of Array(DataCSV)

  csv_data = Utils.getData

  current_page = 0
  next_page = false

  if page <= 0
    page = 0
  end

  while csv_data.next
    if next_page
      current_page += 1
      next_page = false
      data << [] of DataCSV
    end

    data[current_page] << {
      codigo:           csv_data["COD_EDO"],
      estado:           csv_data["EDO"],
      codigo_municipio: csv_data["COD_MUN"],
      municipio:        csv_data["MUN"],
      codigo_parroquia: csv_data["COD_PAR"],
      parroquia:        csv_data["PAR"],
      centro:           csv_data["CENTRO"],
      mesa:             csv_data["MESA"],
      votos_validos:    csv_data["VOTOS_VALIDOS"],
      votos_nulos:      csv_data["VOTOS_NULOS"],
      eg:               csv_data["EG"],
      nm:               csv_data["NM"],
      url:              csv_data["URL"],
    }

    if data[current_page].size >= size_page
      next_page = true
    end
  end
  page_cached[size_page] = data
  data[page].to_json
end

Kemal.run
