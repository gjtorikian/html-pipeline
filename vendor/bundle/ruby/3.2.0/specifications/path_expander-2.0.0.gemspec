# -*- encoding: utf-8 -*-
# stub: path_expander 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "path_expander".freeze
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "homepage_uri" => "https://github.com/seattlerb/path_expander" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ryan Davis".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDPjCCAiagAwIBAgIBCTANBgkqhkiG9w0BAQsFADBFMRMwEQYDVQQDDApyeWFu\nZC1ydWJ5MRkwFwYKCZImiZPyLGQBGRYJemVuc3BpZGVyMRMwEQYKCZImiZPyLGQB\nGRYDY29tMB4XDTI1MDEwNjIzMjcwMVoXDTI2MDEwNjIzMjcwMVowRTETMBEGA1UE\nAwwKcnlhbmQtcnVieTEZMBcGCgmSJomT8ixkARkWCXplbnNwaWRlcjETMBEGCgmS\nJomT8ixkARkWA2NvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALda\nb9DCgK+627gPJkB6XfjZ1itoOQvpqH1EXScSaba9/S2VF22VYQbXU1xQXL/WzCkx\ntaCPaLmfYIaFcHHCSY4hYDJijRQkLxPeB3xbOfzfLoBDbjvx5JxgJxUjmGa7xhcT\noOvjtt5P8+GSK9zLzxQP0gVLS/D0FmoE44XuDr3iQkVS2ujU5zZL84mMNqNB1znh\nGiadM9GHRaDiaxuX0cIUBj19T01mVE2iymf9I6bEsiayK/n6QujtyCbTWsAS9Rqt\nqhtV7HJxNKuPj/JFH0D2cswvzznE/a5FOYO68g+YCuFi5L8wZuuM8zzdwjrWHqSV\ngBEfoTEGr7Zii72cx+sCAwEAAaM5MDcwCQYDVR0TBAIwADALBgNVHQ8EBAMCBLAw\nHQYDVR0OBBYEFEfFe9md/r/tj/Wmwpy+MI8d9k/hMA0GCSqGSIb3DQEBCwUAA4IB\nAQAC0WQJcPOWPFwkojhzweilRVjTJ19UiLhiBTw3C1wJO3LVdBkWDmnnhAmKuX4D\nr7vjQvESlABGIPdutI1Yl7mrHQzTkfLfXvNN6MT0nLChPyIYauT6SZZxubwJrUfA\n7R0c2CJTIboZ0XaGpLsXqHEF1c29H7TV1QvVuqKAN2mCjh4N82QVn+ZKtys28AwT\n6GfQX2fqLoi4KSc7xIzHKaNzqxeOICmJofk9w5VZ2rRN6yes8jvFYwz9HR41wdj8\nbwfinv7Yp5fA6AysuZLhCykyfDuZVRrUp0Vb68YCKsLjJly/Theak+euNTxvHsB+\nal9oSgPPHICMEX65qvLywitx\n-----END CERTIFICATE-----\n".freeze]
  s.date = "1980-01-02"
  s.description = "PathExpander helps pre-process command-line arguments expanding\ndirectories into their constituent files. It further helps by\nproviding additional mechanisms to make specifying subsets easier\nwith path subtraction and allowing for command-line arguments to be\nsaved in a file.\n\nNOTE: this is NOT an options processor. It is a path processor\n(basically everything else besides options). It does provide a\nmechanism for pre-filtering cmdline options, but not with the intent\nof actually processing them in PathExpander. Use OptionParser to\ndeal with options either before or after passing ARGV through\nPathExpander.".freeze
  s.email = ["ryand-ruby@zenspider.com".freeze]
  s.extra_rdoc_files = ["History.rdoc".freeze, "Manifest.txt".freeze, "README.rdoc".freeze]
  s.files = ["History.rdoc".freeze, "Manifest.txt".freeze, "README.rdoc".freeze]
  s.homepage = "https://github.com/seattlerb/path_expander".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.rubygems_version = "3.4.6".freeze
  s.summary = "PathExpander helps pre-process command-line arguments expanding directories into their constituent files".freeze

  s.installed_by_version = "3.4.6" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.21"])
  s.add_development_dependency(%q<hoe>.freeze, ["~> 4.3"])
end
