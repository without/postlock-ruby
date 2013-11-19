module ApiRecord
  class InvalidObjectTypeError < Exception
  end

  class ArrayWrapper
    attr_accessor :url, :length, :element_class

    def initialize(token, element_class, array_hash)
      @token = token
      self.element_class = element_class
      self.url = array_hash['url']
      self.length = array_hash['count']
    end

    def all
      element_class.get_all(@token, url)
    end

    def [](*args)
      offset, count = case
        when args.length == 1 && (index = args.first).is_a?(Integer)
          [index, 1]
        when args.length == 1 && (range = args.first).is_a?(Range)
          [range.first, range.last - range.first + 1]
        when args.length == 2
          [args.first, args.last]
        else
          raise InvalidRangeError.new("Invalid range arguments: #{args}")
      end
      all[offset, count]
    end

    def each(&block)
      element_class.get_all.each(&block)
    end

    def map(&block)
      all.map &block
    end

    def create(attributes)
      element_class.create(@token, attributes, url)
    end
  end

  class ReadOnly
    def self.attributes(*attribs)
      attribs.each do |attr|
        attr_accessor attr
        _attributes << attr
      end
    end

    def self._attributes
      (@attributes ||= {})[name] ||= []
    end

    attributes :id

    def self.has_many(values, element_class)
      values = [values] unless values.respond_to? :each
      values.each do |v|
        attributes v
        attr_accessor "_#{v}"
        define_method(v) do
          ArrayWrapper.new @token, element_class, send("_#{v}")
        end
        define_method("#{v}=") do |value|
          send "_#{v}=", value
        end
      end
    end

    def attributes
      self.class._attributes
    end

    def read_only_attributes
      []
    end

    def assign(values_hash)
      values_hash.each {|k, v| send "#{k}=", v unless k.to_s == 'id' || read_only_attributes.include?(k.to_s) }
    end

    def attributes_hash(options = {})
      hash = {}.tap do |h|
        except = options[:except] || []
        except = [except] unless except.respond_to? :each
        attributes.each {|attr| h[attr] = send(attr) unless except.include?(attr) }
      end
    end

    def initialize(token, values_hash = {})
      @token = token
      assign(values_hash)
    end

    def self._base_collection_path
      @base_collection_path ||= {}
    end

    def self.base_collection_path
      _base_collection_path[self.name]
    end

    def self.collection_path(*collection_path)
      _base_collection_path[self.name] = collection_path.first unless collection_path.empty?
      "api/v1/#{base_collection_path}"
    end

    def self._values_key
      @_values_key ||= {}
    end

    def self.values_key(*values_key)
      _values_key[self.name] = values_key.first unless values_key.empty?
      _values_key[self.name]
    end

    def self.member_path(id)
      "#{collection_path}/#{id}"
    end
    
    def collection_path
      self.class.collection_path
    end

    def member_path
      self.class.member_path id if id
    end

    def values_key
      self.class.values_key
    end

    def self.all(token, url = nil) # index
      if url
        get_all token, url
      else
        get_all token, collection_path
      end
    end

    def self.strip_type(values_hash)
      values_hash.dup.tap do |vh|
        object_type = vh.delete 'object'
        raise InvalidObjectTypeError.new("Invalid object type returned: #{object_type}") unless object_type == values_key.to_s
      end
    end

    def self.new_from_server(token, values_hash)
      new(token, strip_type(values_hash)).tap {|m| m.assign_read_only values_hash }
    end

    def self.find(token, id) # show
      values_hash = token.get(member_path id).parsed
      new_from_server(token, values_hash)
    end

    def reload
      assign self.class.strip_type(get(member_path))
      self
    end

    def assign_read_only(values_hash)
      self.id = values_hash['id']
      read_only_attributes.each {|attr| send "#{attr}=", values_hash[attr.to_s] }
    end

    private

    def self.get_all(token, path)
      [].tap do |members|
        list_hash = token.get(path).parsed
        list_hash['data'].each do |values_hash|
          m = new_from_server token, values_hash
          m.assign_read_only values_hash
          members << m
        end
      end
    end

    def get(path, params = {})
      @token.get(path, body: params.to_json).parsed
    end

    def put(path, params = {})
      @token.put(path, body: params.to_json).parsed
    end

    def post(path, params = {})
      @token.post(path, body: params.to_json).parsed
    end

    def delete(path, params = {})
      @token.delete(path, body: params.to_json).parsed
    end
  end

  class ReadOnlyDeletable < ReadOnly
    def destroy
      assign self.class.strip_type(delete(member_path)) if member_path
    end
  end

  class Base < ReadOnlyDeletable
    def self.create(token, values_hash = {}, path = nil)
      new(token, values_hash).tap {|m| m.save(path) }
    end

    def save(path = nil)
      ro_attributes = read_only_attributes
      ro_attributes << :id
      attrs = attributes_hash(except: ro_attributes)
      values_hash = (case
        when path then post path, values_key => attrs
        when mp = member_path then put mp, values_key => attrs
        else post collection_path, values_key => attrs
      end)
      assign self.class.strip_type(values_hash)
      assign_read_only values_hash
      true
    end
  end
end
