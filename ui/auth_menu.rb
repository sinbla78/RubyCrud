require_relative '../services/auth_service'

class AuthMenu
  def self.show
    loop do
      puts "\n" + "=" * 50
      puts "🔐 Ruby CRUD 인증 시스템"
      puts "=" * 50
      puts "1. 회원가입"
      puts "2. 로그인"
      puts "3. 시스템 통계"
      puts "4. 종료"
      puts "=" * 50
      print "선택하세요 (1-4): "
      
      choice = gets.chomp.to_i
      
      case choice
      when 1
        register
      when 2
        user = login
        return user if user  # 로그인 성공시 사용자 반환
      when 3
        AuthService.get_user_stats
      when 4
        puts "👋 프로그램을 종료합니다."
        exit(0)
      else
        puts "❌ 잘못된 선택입니다. 1-4 사이의 숫자를 입력하세요."
      end
      
      wait_for_user
    end
  end
  
  private
  
  def self.register
    puts "\n📝 회원가입"
    puts "-" * 30
    
    print "사용자명 (3자 이상): "
    username = gets.chomp
    
    print "이메일: "
    email = gets.chomp
    
    puts "\n"
    PasswordHelper.password_requirements
    print "비밀번호: "
    password = gets.chomp
    
    print "비밀번호 확인: "
    password_confirm = gets.chomp
    
    if password != password_confirm
      puts "❌ 비밀번호가 일치하지 않습니다."
      return
    end
    
    AuthService.register(username, email, password)
  end
  
  def self.login
    puts "\n🔑 로그인"
    puts "-" * 30
    
    print "사용자명: "
    username = gets.chomp
    
    print "비밀번호: "
    password = gets.chomp
    
    AuthService.login(username, password)
  end
  
  def self.wait_for_user
    puts "\n계속하려면 Enter를 누르세요..."
    gets
  end
end