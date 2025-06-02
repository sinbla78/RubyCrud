class AuthUser
    attr_accessor :id, :username, :email, :password_hash, :created_at, :updated_at
    
    def initialize(id: nil, username:, email:, password_hash:, created_at: nil, updated_at: nil)
      @id = id
      @username = username
      @email = email
      @password_hash = password_hash
      @created_at = created_at
      @updated_at = updated_at
    end
    
    def to_s
      "ID: #{@id}, 사용자명: #{@username}, 이메일: #{@email}"
    end
    
    def valid?
      !@username.nil? && !@username.empty? && @username.length >= 3 &&
      !@email.nil? && !@email.empty? && @email.include?('@') &&
      !@password_hash.nil? && !@password_hash.empty?
    end
    
    def to_hash
      {
        id: @id,
        username: @username,
        email: @email,
        created_at: @created_at,
        updated_at: @updated_at
      }
    end
  end
  