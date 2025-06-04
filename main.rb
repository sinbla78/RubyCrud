#!/usr/bin/env ruby
# main.rb
require_relative 'config/database'
require_relative 'ui/auth_menu'
require_relative 'ui/main_menu'
require_relative 'utils/password_helper'  # 이 줄 추가


def main
  puts "🚀 Ruby CRUD 인증 시스템을 시작합니다!"
  puts "🔌 데이터베이스에 연결 중..."
  
  # 데이터베이스 연결 테스트
  unless Database.test_connection
    puts "❌ 데이터베이스 연결에 실패했습니다."
    exit(1)
  end
  
  begin
    # 인증 루프
    loop do
      current_user = AuthMenu.show
      
      if current_user
        # 메인 메뉴 진입
        main_menu = MainMenu.new(current_user)
        main_menu.show
      end
    end
    
  rescue Interrupt
    puts "\n\n👋 프로그램이 중단되었습니다."
  rescue StandardError => e
    puts "❌ 오류가 발생했습니다: #{e.message}"
    puts "스택 트레이스:"
    puts e.backtrace
  ensure
    Database.disconnect
  end
end

# 프로그램 실행
main if __FILE__ == $0