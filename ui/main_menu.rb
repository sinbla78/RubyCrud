require_relative '../services/user_service'

class MainMenu
  def initialize(current_user)
    @current_user = current_user
  end
  
  def show
    loop do
      display_menu
      choice = gets.chomp.to_i
      
      case choice
      when 1
        create_user_interactive
      when 2
        UserService.get_all_users(@current_user.id)
      when 3
        search_user_interactive
      when 4
        update_user_interactive
      when 5
        delete_user_interactive
      when 6
        search_by_name_interactive
      when 7
        UserService.get_user_stats(@current_user.id)
      when 8
        export_data
      when 9
        puts "👋 로그아웃되었습니다."
        break
      else
        puts "❌ 잘못된 선택입니다. 1-9 사이의 숫자를 입력하세요."
      end
      
      wait_for_user
    end
  end
  
  private
  
  def display_menu
    puts "\n" + "=" * 50
    puts "🏠 사용자 관리 시스템 (#{@current_user.username}님)"
    puts "=" * 50
    puts "1. 사용자 생성"
    puts "2. 모든 사용자 조회"
    puts "3. 사용자 검색 (ID)"
    puts "4. 사용자 수정"
    puts "5. 사용자 삭제"
    puts "6. 이름으로 검색"
    puts "7. 통계 보기"
    puts "8. 데이터 내보내기"
    puts "9. 로그아웃"
    puts "=" * 50
    print "메뉴를 선택하세요 (1-9): "
  end
  
  def create_user_interactive
    puts "\n📝 새 사용자 생성"
    puts "-" * 30
    
    print "이름을 입력하세요: "
    name = gets.chomp
    
    print "이메일을 입력하세요: "
    email = gets.chomp
    
    print "나이를 입력하세요: "
    age = gets.chomp.to_i
    
    UserService.create_user(name, email, age, @current_user.id)
  end
  
  def search_user_interactive
    puts "\n🔍 사용자 검색"
    print "검색할 사용자 ID를 입력하세요: "
    id = gets.chomp.to_i
    UserService.get_user_by_id(id, @current_user.id)
  end
  
  def update_user_interactive
    puts "\n✏️ 사용자 정보 수정"
    print "수정할 사용자 ID를 입력하세요: "
    id = gets.chomp.to_i
    
    user = UserService.get_user_by_id(id, @current_user.id)
    return unless user
    
    puts "\n현재 정보: #{user}"
    puts "변경하지 않을 항목은 Enter를 누르세요."
    
    print "새 이름 (현재: #{user.name}): "
    name = gets.chomp
    name = name.empty? ? nil : name
    
    print "새 이메일 (현재: #{user.email}): "
    email = gets.chomp
    email = email.empty? ? nil : email
    
    print "새 나이 (현재: #{user.age}): "
    age_input = gets.chomp
    age = age_input.empty? ? nil : age_input.to_i
    
    UserService.update_user(id, @current_user.id, name: name, email: email, age: age)
  end
  
  def delete_user_interactive
    puts "\n🗑️ 사용자 삭제"
    print "삭제할 사용자 ID를 입력하세요: "
    id = gets.chomp.to_i
    
    user = UserService.get_user_by_id(id, @current_user.id)
    return unless user
    
    puts "정말 삭제하시겠습니까? (y/N): "
    confirm = gets.chomp.downcase
    
    if confirm == 'y' || confirm == 'yes'
      UserService.delete_user(id, @current_user.id)
    else
      puts "❌ 삭제가 취소되었습니다."
    end
  end
  
  def search_by_name_interactive
    puts "\n🔍 이름으로 검색"
    print "검색할 이름을 입력하세요: "
    name = gets.chomp
    UserService.search_users_by_name(name, @current_user.id)
  end
  
  def export_data
    puts "\n📤 데이터 내보내기"
    users = UserService.get_all_users(@current_user.id)
    
    if users.empty?
      puts "내보낼 데이터가 없습니다."
      return
    end
    
    puts "사용자 데이터 (JSON 형식):"
    require 'json'
    data = users.map(&:to_hash)
    puts JSON.pretty_generate(data)
  end
  
  def wait_for_user
    puts "\n계속하려면 Enter를 누르세요..."
    gets
  end
end