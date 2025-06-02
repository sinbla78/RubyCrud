require_relative '../models/user'
require_relative '../config/database'

class UserService
  def self.create_user(name, email, age, created_by)
    user = User.new(
      name: name,
      email: email,
      age: age,
      created_by: created_by
    )
    
    unless user.valid?
      puts "❌ 유효하지 않은 사용자 정보입니다."
      return nil
    end
    
    result = Database.execute(
      "INSERT INTO users (name, email, age, created_by) VALUES ($1, $2, $3, $4) RETURNING id, created_at",
      [name, email, age, created_by]
    )
    
    if result && result.ntuples > 0
      row = result[0]
      user.id = row['id'].to_i
      user.created_at = row['created_at']
      
      puts "✅ 사용자가 성공적으로 생성되었습니다: #{user}"
      user
    else
      puts "❌ 사용자 생성 중 오류가 발생했습니다."
      nil
    end
  end
  
  def self.get_all_users(created_by)
    result = Database.execute(
      "SELECT id, name, email, age, created_at FROM users WHERE created_by = $1 ORDER BY created_at DESC",
      [created_by]
    )
    
    if result && result.ntuples > 0
      users = result.map do |row|
        User.new(
          id: row['id'].to_i,
          name: row['name'],
          email: row['email'],
          age: row['age'].to_i,
          created_by: created_by,
          created_at: row['created_at']
        )
      end
      
      puts "📋 모든 사용자 목록 (#{users.length}명):"
      puts "-" * 60
      users.each { |user| puts user }
      puts "-" * 60
      
      users
    else
      puts "📋 등록된 사용자가 없습니다."
      []
    end
  end
  
  def self.get_user_by_id(id, created_by)
    result = Database.execute(
      "SELECT id, name, email, age, created_at FROM users WHERE id = $1 AND created_by = $2",
      [id, created_by]
    )
    
    if result && result.ntuples > 0
      row = result[0]
      user = User.new(
        id: row['id'].to_i,
        name: row['name'],
        email: row['email'],
        age: row['age'].to_i,
        created_by: created_by,
        created_at: row['created_at']
      )
      
      puts "🔍 사용자 찾음: #{user}"
      user
    else
      puts "❌ ID #{id}인 사용자를 찾을 수 없습니다."
      nil
    end
  end
  
  def self.update_user(id, created_by, name: nil, email: nil, age: nil)
    # 먼저 사용자가 존재하는지 확인
    existing_user = get_user_by_id(id, created_by)
    return nil unless existing_user
    
    # 업데이트할 필드들 준비
    updates = []
    params = []
    param_index = 1
    
    if name
      updates << "name = $#{param_index}"
      params << name
      param_index += 1
    end
    
    if email
      updates << "email = $#{param_index}"
      params << email
      param_index += 1
    end
    
    if age
      updates << "age = $#{param_index}"
      params << age
      param_index += 1
    end
    
    if updates.empty?
      puts "❌ 수정할 내용이 없습니다."
      return existing_user
    end
    
    updates << "updated_at = CURRENT_TIMESTAMP"
    params << id
    params << created_by
    
    query = "UPDATE users SET #{updates.join(', ')} WHERE id = $#{param_index} AND created_by = $#{param_index + 1} RETURNING id, name, email, age, updated_at"
    
    result = Database.execute(query, params)
    
    if result && result.ntuples > 0
      row = result[0]
      updated_user = User.new(
        id: row['id'].to_i,
        name: row['name'],
        email: row['email'],
        age: row['age'].to_i,
        created_by: created_by,
        updated_at: row['updated_at']
      )
      
      puts "✅ 사용자 정보가 수정되었습니다: #{updated_user}"
      updated_user
    else
      puts "❌ 사용자 정보 수정 중 오류가 발생했습니다."
      nil
    end
  end
  
  def self.delete_user(id, created_by)
    # 먼저 사용자가 존재하는지 확인
    existing_user = get_user_by_id(id, created_by)
    return false unless existing_user
    
    result = Database.execute(
      "DELETE FROM users WHERE id = $1 AND created_by = $2",
      [id, created_by]
    )
    
    if result && result.cmd_tuples > 0
      puts "🗑️ 사용자가 삭제되었습니다: #{existing_user}"
      true
    else
      puts "❌ 사용자 삭제 중 오류가 발생했습니다."
      false
    end
  end
  
  def self.search_users_by_name(name, created_by)
    result = Database.execute(
      "SELECT id, name, email, age, created_at FROM users WHERE name ILIKE $1 AND created_by = $2 ORDER BY name",
      ["%#{name}%", created_by]
    )
    
    if result && result.ntuples > 0
      users = result.map do |row|
        User.new(
          id: row['id'].to_i,
          name: row['name'],
          email: row['email'],
          age: row['age'].to_i,
          created_by: created_by,
          created_at: row['created_at']
        )
      end
      
      puts "🔍 '#{name}'으로 검색된 사용자들 (#{users.length}명):"
      users.each { |user| puts user }
      users
    else
      puts "🔍 '#{name}'과 일치하는 사용자를 찾을 수 없습니다."
      []
    end
  end
  
  def self.get_user_stats(created_by)
    result = Database.execute(
      "SELECT COUNT(*) as total, AVG(age) as avg_age FROM users WHERE created_by = $1",
      [created_by]
    )
    
    if result && result.ntuples > 0
      row = result[0]
      total_users = row['total'].to_i
      avg_age = row['avg_age'] ? row['avg_age'].to_f : 0
      
      puts "📊 사용자 통계:"
      puts "전체 사용자 수: #{total_users}"
      puts "평균 나이: #{'%.1f' % avg_age}세" if total_users > 0
      
      { total: total_users, average_age: avg_age }
    else
      puts "📊 통계 정보를 가져올 수 없습니다."
      { total: 0, average_age: 0 }
    end
  end
end