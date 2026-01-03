namespace :gemojione do
  desc "Install Emoji Image Assets"
  task :install_assets do
    target_dir = ENV['TARGET'] ||= File.join(Rails.root, 'app/assets/images/emoji')
    source_dir = File.absolute_path(File.dirname(__FILE__) + '/../../../assets')

    puts "===================================================================="
    puts "= emoji image assets install"
    puts "= Target: #{target_dir}"
    puts "= Source: #{source_dir}"
    puts "===================================================================="

    unless File.exists?(target_dir)
      puts "- Creating #{target_dir}..."
      FileUtils.mkdir_p(target_dir)
    end

    puts "- Installing assets..."
    Dir.glob("#{source_dir}/*").entries.each do |asset|
      FileUtils.cp_r(asset, target_dir, verbose: true, preserve: false)
    end
  end

end
