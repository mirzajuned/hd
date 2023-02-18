module LanguageHelper
  def self.translation(word, language)
    Global.send('translate_language').send(word)[language]
  end
end
