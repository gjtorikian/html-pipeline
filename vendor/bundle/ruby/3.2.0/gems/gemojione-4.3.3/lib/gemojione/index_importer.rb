class IndexImporter
  SOURCE = 'https://raw.githubusercontent.com/joypixels/emojione/master/emoji.json'

  def self.import_from_emojione
    new.import_from_emojione
  end

  def import_from_emojione
    count = 0

    mojis.each do |array|
      unicode = array[0].upcase
      hash = array[1]

      unless index.find_by_unicode(unicode)
        count += 1
        add_moji(
          hash['shortname'].gsub(':', ''),
          unicode,
          hash['name'],
          hash['category'],
          hash['code_points']['fully_qualified'].split('-').map { |u| u.downcase.to_i(16) }.pack('U*'),
          hash['shortname_alternates']
        )
      end
    end

    puts "Added #{count} emojis to the index"
  end

  private

  def mojis
    @mojis ||= JSON.parse(HTTParty.get(SOURCE).body)
  end

  def index
    @index ||= Gemojione::Index.new
  end

  def add_moji(name, unicode, description, category, moji, aliases)
    file = File.absolute_path(File.dirname(__FILE__) + '/../../config/index.json')
    emoji_list ||= begin
      emoji_json = File.read(file)
      JSON.parse(emoji_json)
    end

    emoji_list[name] = {
      'unicode'            => unicode,
      'name'               => description,
      'shortname'          => ":#{name}:",
      'category'           => category,
      'moji'               => moji,
      'unicode_alternates' => [],
      'aliases'            => aliases,
      'aliases_ascii'      => [],
      'keywords'           => []
    }

    File.open(file, 'w') do |f|
      f.write(JSON.pretty_generate(emoji_list))
    end
  end

  def self.prettyify_index
    file = File.absolute_path(File.dirname(__FILE__) + '/../config/index.json')
    emoji_list ||= begin
      emoji_json = File.read(file)
      JSON.parse(emoji_json)
    end

     File.open(file, 'w') do |f|
      f.write(JSON.pretty_generate(emoji_list))
    end
  end

  def self.add_alias(moji, new_alias)
    file = File.absolute_path(File.dirname(__FILE__) + '/../config/index.json')
    emoji_list ||= begin
      emoji_json = File.read(file)
      JSON.parse(emoji_json)
    end

     index = Index.new
    return if index.find_by_moji(moji).nil?

     name = index.find_by_moji(moji)['name']
    emoji_list[name]['aliases'] << ":#{new_alias}:"

     File.open(file, 'w') do |f|
      f.write(JSON.pretty_generate(emoji_list))
    end
  end
end
