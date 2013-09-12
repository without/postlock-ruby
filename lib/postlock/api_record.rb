module ApiRecord
  class Base
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

    def attributes
      self.class._attributes
    end

    def assign(values_hash)
      values_hash.each {|k, v| send "#{k}=", v }
    end

    def attributes_hash(options = {})
      hash = {}.tap do |h|
        attributes.each {|attr| h[attr] = send(attr) }
        if except = options[:except]
          except = [except] unless except.respond_to? :each
          except.each {|attr| h.delete attr }
        end
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

    def self.all(token, parent = nil) # index
      if parent
        get_all token, "#{parent.member_path}/base_collection_path"
      else
        get_all token, collection_path
      end
    end

    def self.find(token, id) # show
      new token, token.get(member_path id).parsed[values_key]
    end

    def self.create(token, values_hash)
      new(token, values_hash).tap {|m| m.save }
    end

    def save
      ro_attributes = read_only_attributes
      ro_attributes << :id
      attrs = attributes_hash(except: ro_attributes)
      assign((if mp = member_path
        put mp, attrs
      else
        post collection_path, attrs
      end)[values_key])
      true
    end

    def destroy
      assign delete(mp).parsed[values_key] if mp = member_path
    end

    def reload
      assign get(member_path).parsed
    end

    private

    def self.get_all(token, path)
      [].tap do |members|
        token.get(path).parsed.each {|object_hash| members << new(token, object_hash[values_key]) }
      end
    end

    def get(path, params = {})
      @token.get(path, params).parsed
    end

    def put(path, params)
      @token.put(path, params).parsed
    end

    def post(path, params)
      @token.post(path, params).parsed
    end

    def delete(path, params)
      @token.delete(path, params).parsed
    end
  end
end
