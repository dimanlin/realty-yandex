# -*- coding: utf-8 -*-
namespace :spree_yandex_market do
  desc "Copies public assets of the Yandex Market to the instance public/ directory."
  task :update => :environment do
    is_svn_git_or_dir = proc { |path| path =~ /\.svn/ || path =~ /\.git/ || File.directory?(path) }
    Dir[YandexMarketExtension.root + "/public/**/*"].reject(&is_svn_git_or_dir).each do |file|
      path      = file.sub(YandexMarketExtension.root, '')
      directory = File.dirname(path)
      puts "Copying #{path}..."
      mkdir_p Rails.root + directory
      cp file, Rails.root + path
    end
  end

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
    `ln -sf "#{tfile.path}" "#{File.join(directory, "#{torgovaya_sistema}.xml")}"`

    # Удаляем лишнии файлы
    @config          = Spree::YandexMarket::Config.instance
    @number_of_files = @config.preferred_number_of_files

    @export_files    = Dir[File.join(directory, '**', '*')].
        map { |x| [File.basename(x), File.mtime(x)] }.
        sort { |x, y| y.last <=> x.last }
    e                =@export_files.find { |x| x.first == "#{torgovaya_sistema}.gz" }
    @export_files.reject! { |x| x.first == "#{torgovaya_sistema}.gz" }
    @export_files.unshift(e)

    @export_files[@number_of_files..-1] && @export_files[@number_of_files..-1].each do |x|
      if File.exist?(File.join(directory, x.first))
        Rails.logger.info "[ #{torgovaya_sistema} ] удаляем устаревший файл"
        Rails.logger.info "[ #{torgovaya_sistema} ] путь к файлу #{File.join(directory, x.first)}"
        File.delete(File.join(directory, x.first))
      end
    end
  end
end
