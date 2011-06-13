# -*- coding: utf-8 -*-
namespace :spree_yandex_market do
  desc "Copies public assets of the Yandex Realty to the instance public/ directory."

  desc "Generate Yandex.Realty export file"
  task :generate_r => :environment do
    generate_export_file 'yandex_realty'
  end

  def generate_export_file 
    directory = File.join(Rails.root, 'public', "#{realty_system}")
    mkdir_p directory unless File.exist?(directory)
    require File.expand_path(File.join(Rails.root, "config/environment"))
    require File.join(File.dirname(__FILE__), '..', "export/yandex_realty_exporter.rb")

    ::Time::DATE_FORMATS[:ym] = "%Y-%m-%d %H:%M"
    yml_xml = Export.const_get("YandexRealtyExporter").new.export
    puts 'saving file...'

    # Создаем файл, сохраняем в нужной папке,
    tfile_basename = "yandex_realty_#{Time.now.strftime("%Y_%m_%d__%H_%M")}"
    tfile          = File.new(File.join(directory, tfile_basename), "w+")
    tfile.write(yml_xml)
    tfile.close
    # пакуем в gz и делаем симлинк на ссылку файла yandex_market_last.gz
    `ln -sf "#{tfile.path}" "#{File.join(directory, "#{realty_yandex}.xml")}"`
  end
end
