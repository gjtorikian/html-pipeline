require "bundler/gem_tasks"
require 'rake/testtask'
 
Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end
 
task :default => :test

task :resprite do
  require 'sprite_factory'
  require 'rmagick'

  base_selector = 'emojione'
  separator = '-'

  SpriteFactory.run!('assets/png', layout: 'packed', selector: 'emojione', nocomments: true) do |images|
    rules = [".#{base_selector} { text-indent: -9999em;image-rendering: optimizeQuality;font-size: inherit;height: 64px;width: 64px;top: -3px;position: relative;display: inline-block;margin: 0 .15em;line-height: normal;vertical-align: middle;background-image: url(image-path('emojione.sprites.png'));background-repeat: no-repeat}"]
    images.each_pair do |key, val|
      cssx = "#{val[:cssx] == 0 ? 0 : '-'+val[:cssx].to_s+'px'}"
      cssy = "#{val[:cssy] == 0 ? 0 : '-'+val[:cssy].to_s+'px'}"

      rules << ".#{base_selector}#{separator}#{key.to_s.downcase}{background-position: #{cssx} #{cssy};}"
    end
    rules.join("\n")
  end

  FileUtils.mv('assets/png.css', "assets/sprites/emojione.sprites.scss", verbose: true)
  #Optimize png sprite
  if system("which pngcrush")
    system('pngcrush', '-q', '-rem alla', '-reduce', '-brute', 'assets/png.png', 'assets/sprites/emojione.sprites.png')
    FileUtils.rm "assets/png.png"
  else
    FileUtils.mv('assets/png.png', "assets/sprites/emojione.sprites.png", verbose: true)
  end
end