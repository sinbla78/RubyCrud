require_relative '../managers/user_manager'

class MenuSystem
  def initialize
    @user_manager = UserManager.new
  end
  
  def display_menu
    puts "\n" + "=" * 40
    puts "🏠 사용자 관리 시스템"
    puts "=" * 40
    puts "1. 사용자 생성"
    puts "2. 모든 사용자 조회"
    puts "3. 사용자 검색 (ID)"
    puts "4. 사용자 수정"
    puts "5. 사용자 삭제"
    puts "6. 이름으로 검색"
    puts "7. 통계 보기"
    puts "8. 데이터 내보내기"
    puts "9. 종료"
    puts "=" * 40
    print "메뉴를 선택하세요 (1-9): "
  end
  
  def run
    load_sample_data
    
    loop do
      display_menu
      choice = gets.chomp.to_i
      
      case choice
      when 1
        create_user_interactive
      when 2
        @user_manager.read_all_users
      when 3
        search_user_interactive
      when 4
        update_user_interactive
      when 5
        delete_user_interactive
      when 6
        search_by_name_interactive
      when 7
        @user_manager.get_stats
      when 8
        export_data
      when 9
        puts "👋 프로그램을 종료합니다."
        break
      else
        puts "❌ 잘못된 선택입니다. 1-9 사이의 숫자를 입력하세요."
      end
      
      wait_for_user
    end
  end
  
  private
  
  def create_user_interactive
    puts "\n📝 새 사용자 생성"
    print "이름을 입력하세요: "
    name = gets.chomp
    print "이메일을 입력하세요: "
    email = gets.chomp
    print "나이를 입력하세요: "
    age = gets.chomp.to_i
    
    @user_manager.create_user(name, email, age)
  end
  
  def search_user_interactive
    puts "\n🔍 사용자 검색"
    print "검색할 사용자 ID를 입력하세요: "
    id = gets.chomp.to_i
    @user_manager.read_user_by_id(id)
  end
  
  def update_user_interactive
    puts "\n✏️ 사용자 정보 수정"
    print "수정할 사용자 ID를 입력하세요: "
    id = gets.chomp.to_i
    
    user = @user_manager.read_user_by_id(id)
    return if user.nil?
    
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
    
    @user_manager.update_user(id, name: name, email: email, age: age)
  end
  
  def delete_user_interactive
    puts "\n🗑️ 사용자 삭제"
    print "삭제할 사용자 ID를 입력하세요: "
    id = gets.chomp.to_i
    
    if @user_manager.user_exists?(id)
      user = @user_manager.read_user_by_id(id)
      puts "정말 삭제하시겠습니까? (y/N): "
      confirm = gets.chomp.downcase
      
      if confirm == 'y' || confirm == 'yes'
        @user_manager.delete_user(id)
      else
        puts "❌ 삭제가 취소되었습니다."
      end
    else
      puts "❌ 해당 ID의 사용자가 존재하지 않습니다."
    end
  end
  
  def search_by_name_interactive
    puts "\n🔍 이름으로 검색"
    print "검색할 이름을 입력하세요: "
    name = gets.chomp
    @user_manager.search_users_by_name(name)
  end
  
  def export_data
    puts "\n📤 데이터 내보내기"
    data = @user_manager.export_users
    
    if data.empty?
      puts "내보낼 데이터가 없습니다."
      return
    end
    
    puts "사용자 데이터 (JSON 형식):"
    puts JSON.pretty_generate(data)
  end
  
  def load_sample_data
    puts "🚀 Ruby CRUD 애플리케이션을 시작합니다!"
    puts "✨ 샘플 데이터를 로드합니다..."
    
    @user_manager.create_user("홍길동", "hong@example.com", 25)
    @user_manager.create_user("김영희", "kim@example.com", 30)
    @user_manager.create_user("이철수", "lee@example.com", 28)
    
    puts "✅ 샘플 데이터가 로드되었습니다!"
  end
  
  def wait_for_user
    puts "\n계속하려면 Enter를 누르세요..."
    gets
  end
end