# -*- coding: utf-8 -*-
module PickleI18n
  autoload :Parser, 'pickle_i18n/parser'
  autoload :Session, 'pickle_i18n/session'

  class << self
    def model_translations
      @model_translations ||= {}
    end

    def model_attribute_translations
      @model_attribute_translations ||= {}
    end

    def translate(pickle_config, locale)
      Pickle::Parser.send(:include, PickleI18n::Parser)
      Pickle::Session.send(:include, PickleI18n::Session)

      # pickle_config.factories の中身はこんな感じ
      #   {"product"=>#<Pickle::Adapter::FactoryGirl:0x00000102b0b618 @klass=Product(id: integer, name: string, price: decimal, created_at: datetime, updated_at: datetime), @name="product">}
      # モデルの日本語名についてもfactoryを設定します
      # pickle_config.factories['商品'] = pickle_config.factories['product']

      [:activemodel, :activerecord, :mongoid].each do |scope|
        catch(:exception) do
          begin
            models_hash = I18n.config.backend.translate(locale, :models, :scope => scope)
            model_translations.update(models_hash.stringify_keys.invert)

            model_to_attr_hash = I18n.config.backend.translate(locale, :attributes, :scope => scope)
            model_to_attr_hash.each do |model_name, attr_hash|
              model_attribute_translations[model_name.to_s] = attr_hash.stringify_keys.invert
            end
          rescue I18n::MissingTranslationData
            # 翻訳が見つからない場合はスルーします
          end
        end
      end

      model_translations.each do |key, value|
        pickle_config.factories[key] = pickle_config.factories[value]
      end
    end

  end
end
