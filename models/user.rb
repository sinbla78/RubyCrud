class User
    attr_accessor :id, :name, :email, :age
    
    def initialize(id, name, email, age)
      @id = id
      @name = name
      @email = email
      @age = age
    end
    
    def to_s
      "ID: #{@id}, 이름: #{@name}, 이메일: #{@email}, 나이: #{@age}"
    end
    
    # 유효성 검사
    def valid?
      !@name.nil? && !@name.empty? && 
      !@email.nil? && !@email.empty? && 
      @email.include?('@') &&
      @age.is_a?(Integer) && @age > 0
    end
    
    # 해시로 변환
    def to_hash
      {
        id: @id,
        name: @name,
        email: @email,
        age: @age
      }
    end
  end