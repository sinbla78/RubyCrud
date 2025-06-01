require_relative '../models/user'

class UserManager
  def initialize
    @users = []
    @next_id = 1
  end
  
  # Create - 새 사용자 생성
  def create_user(name, email, age)
    user = User.new(@next_id, name, email, age)
    
    unless user.valid?
      puts "❌ 유효하지 않은 사용자 정보입니다."
      return nil
    end
    
    @users << user
    @next_id += 1
    puts "✅ 사용자가 성공적으로 생성되었습니다: #{user}"
    user
  end
  
  # Read - 모든 사용자 조회
  def read_all_users
    if @users.empty?
      puts "📋 등록된 사용자가 없습니다."
      return []
    end
    
    puts "📋 모든 사용자 목록:"
    puts "-" * 50
    @users.each { |user| puts user }
    puts "-" * 50
    @users
  end
  
  # Read - 특정 사용자 조회 (ID로)
  def read_user_by_id(id)
    user = @users.find { |u| u.id == id }
    if user
      puts "🔍 사용자 찾음: #{user}"
    else
      puts "❌ ID #{id}인 사용자를 찾을 수 없습니다."
    end
    user
  end
  
  # Update - 사용자 정보 수정
  def update_user(id, name: nil, email: nil, age: nil)
    user = @users.find { |u| u.id == id }
    
    if user.nil?
      puts "❌ ID #{id}인 사용자를 찾을 수 없습니다."
      return nil
    end
    
    user.name = name if name
    user.email = email if email
    user.age = age if age
    
    unless user.valid?
      puts "❌ 수정된 정보가 유효하지 않습니다."
      return nil
    end
    
    puts "✅ 사용자 정보가 수정되었습니다: #{user}"
    user
  end
  
  # Delete - 사용자 삭제
  def delete_user(id)
    user_index = @users.find_index { |u| u.id == id }
    
    if user_index.nil?
      puts "❌ ID #{id}인 사용자를 찾을 수 없습니다."
      return false
    end
    
    deleted_user = @users.delete_at(user_index)
    puts "🗑️ 사용자가 삭제되었습니다: #{deleted_user}"
    true
  end
  
  # 검색 기능 - 이름으로 사용자 찾기
  def search_users_by_name(name)
    found_users = @users.select { |u| u.name.downcase.include?(name.downcase) }
    
    if found_users.empty?
      puts "🔍 '#{name}'과 일치하는 사용자를 찾을 수 없습니다."
    else
      puts "🔍 '#{name}'으로 검색된 사용자들:"
      found_users.each { |user| puts user }
    end
    
    found_users
  end
  
  # 통계 정보
  def get_stats
    total_users = @users.length
    avg_age = total_users > 0 ? @users.sum(&:age) / total_users.to_f : 0
    
    puts "📊 사용자 통계:"
    puts "전체 사용자 수: #{total_users}"
    puts "평균 나이: #{'%.1f' % avg_age}세"
    
    { total: total_users, average_age: avg_age }
  end
  
  # 데이터 내보내기
  def export_users
    @users.map(&:to_hash)
  end
  
  # 사용자 존재 여부 확인
  def user_exists?(id)
    @users.any? { |u| u.id == id }
  end
end