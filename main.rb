#!/usr/bin/env ruby
# main.rb
require 'json'
require_relative 'ui/menu_system'
require_relative 'config/database'

# 메인 실행 부분
begin
  menu_system = MenuSystem.new
  menu_system.run
rescue Interrupt
  puts "\n\n👋 프로그램이 중단되었습니다."
rescue StandardError => e
  puts "❌ 오류가 발생했습니다: #{e.message}"
  puts "스택 트레이스:"
  puts e.backtrace
end