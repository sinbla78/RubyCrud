class User
  attr_accessor :id, :name, :email, :age, :created_by, :created_at, :updated_at
  
  def initialize(id: nil, name:, email:, age:, created_by:, created_at: nil, updated_at: nil)
    @id = id
    @name = name
    @email = email
    @age = age
    @created_by = created_by
    @created_at = created_at
    @updated_at = updated_at
  end
  
  def to_s
    "ID: #{@id}, 이름: #{@name}, 이메일: #{@email}, 나이: #{@age}"
  end
  
  def valid?
    !@name.nil? && !@name.empty? && 
    !@email.nil? && !@email.empty? && @email.include?('@') &&
    @age.is_a?(Integer) && @age > 0 && @age < 150 &&
    !@created_by.nil?
  end
  
  def to_hash
    {
      id: @id,
      name: @name,
      email: @email,
      age: @age,
      created_by: @created_by,
      created_at: @created_at,
      updated_at: @updated_at
    }
  end
end