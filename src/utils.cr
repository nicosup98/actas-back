module Utils
  extend self

  def getData
    File.open(File.join([Kemal.config.public_folder, "resultados_elecciones_2024.csv"])) do |content|
      CSV.new(content.gets_to_end, headers: true)
    end
    
  end
end
