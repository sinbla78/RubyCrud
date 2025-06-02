require 'bcrypt'

class PasswordHelper
  # 비밀번호 해시화
  def self.hash_password(password)
    BCrypt::Password.create(password)
  end
  
  # 비밀번호 검증
  def self.verify_password(password, hashed_password)
    BCrypt::Password.new(hashed_password) == password
  end
  
  # 비밀번호 강도 검사
  def self.password_strong?(password)
    return false if password.length < 8
    return false unless password.match(/[A-Z]/)  # 대문자 포함
    return false unless password.match(/[a-z]/)  # 소문자 포함
    return false unless password.match(/[0-9]/)  # 숫자 포함
    return false unless password.match(/[^A-Za-z0-9]/) # 특수문자 포함
    true
  end
  
  def self.password_requirements
    puts "📋 비밀번호 요구사항:"
    puts "- 최소 8자 이상"
    puts "- 대문자 포함"
    puts "- 소문자 포함"
    puts "- 숫자 포함"
    puts "- 특수문자 포함"
  end
end