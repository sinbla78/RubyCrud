#!/usr/bin/env ruby
# main.rb - Ruby CRUD API 서버
require 'sinatra'
require 'json'
require 'digest'
require_relative 'config/database'
require_relative 'utils/password_helper'

# User와 AuthUser 클래스 정의 (임시)
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

class AuthUser
  attr_accessor :id, :username, :email, :password_hash, :created_at, :updated_at
  
  def initialize(id: nil, username:, email:, password_hash:, created_at: nil, updated_at: nil)
    @id = id
    @username = username
    @email = email
    @password_hash = password_hash
    @created_at = created_at
    @updated_at = updated_at
  end
  
  def to_s
    "ID: #{@id}, 사용자명: #{@username}, 이메일: #{@email}"
  end
  
  def valid?
    !@username.nil? && !@username.empty? && @username.length >= 3 &&
    !@email.nil? && !@email.empty? && @email.include?('@') &&
    !@password_hash.nil? && !@password_hash.empty?
  end
  
  def to_hash
    {
      id: @id,
      username: @username,
      email: @email,
      created_at: @created_at,
      updated_at: @updated_at
    }
  end
end

# 데이터베이스 연결 초기화
def initialize_database
  puts "🔌 데이터베이스에 연결 중..."
  unless Database.test_connection
    puts "❌ 데이터베이스 연결에 실패했습니다."
    exit(1)
  end
  puts "✅ 데이터베이스 연결 성공!"
end

# UserManager 클래스 (메모리 기반)
class UserManager
  def initialize
    @users = []
    @next_id = 1
  end
  
  # Create - 새 사용자 생성 (API 버전)
  def create_user(name, email, age, created_by: "system")
    current_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    
    user = User.new(
      id: @next_id,
      name: name,
      email: email,
      age: age,
      created_by: created_by,
      created_at: current_time,
      updated_at: current_time
    )
    
    unless user.valid?
      return { success: false, error: "유효하지 않은 사용자 정보입니다.", data: nil }
    end
    
    @users << user
    @next_id += 1
    { success: true, message: "사용자가 성공적으로 생성되었습니다.", data: user.to_hash }
  end
  
  # Read - 모든 사용자 조회 (API 버전)
  def read_all_users
    {
      success: true,
      message: "모든 사용자 조회 완료",
      count: @users.length,
      data: @users.map(&:to_hash)
    }
  end
  
  # Read - 특정 사용자 조회 (ID로)
  def read_user_by_id(id)
    user = @users.find { |u| u.id == id }
    if user
      { success: true, message: "사용자를 찾았습니다.", data: user.to_hash }
    else
      { success: false, error: "ID #{id}인 사용자를 찾을 수 없습니다.", data: nil }
    end
  end
  
  # Update - 사용자 정보 수정
  def update_user(id, name: nil, email: nil, age: nil, updated_by: "system")
    user = @users.find { |u| u.id == id }
    
    if user.nil?
      return { success: false, error: "ID #{id}인 사용자를 찾을 수 없습니다.", data: nil }
    end
    
    # 업데이트할 필드들 설정
    user.name = name if name
    user.email = email if email
    user.age = age if age
    user.updated_at = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    
    unless user.valid?
      return { success: false, error: "수정된 정보가 유효하지 않습니다.", data: nil }
    end
    
    { success: true, message: "사용자 정보가 수정되었습니다.", data: user.to_hash }
  end
  
  # Delete - 사용자 삭제
  def delete_user(id)
    user_index = @users.find_index { |u| u.id == id }
    
    if user_index.nil?
      return { success: false, error: "ID #{id}인 사용자를 찾을 수 없습니다.", data: nil }
    end
    
    deleted_user = @users.delete_at(user_index)
    { success: true, message: "사용자가 삭제되었습니다.", data: deleted_user.to_hash }
  end
  
  # 검색 기능 - 이름으로 사용자 찾기
  def search_users_by_name(name)
    found_users = @users.select { |u| u.name.downcase.include?(name.downcase) }
    
    {
      success: true,
      message: "'#{name}'으로 검색 완료",
      count: found_users.length,
      data: found_users.map(&:to_hash)
    }
  end
  
  # 통계 정보
  def get_stats
    total_users = @users.length
    avg_age = total_users > 0 ? @users.sum(&:age) / total_users.to_f : 0
    
    {
      success: true,
      message: "통계 조회 완료",
      data: {
        total_users: total_users,
        average_age: avg_age.round(1)
      }
    }
  end
  
  # 사용자 존재 여부 확인
  def user_exists?(id)
    @users.any? { |u| u.id == id }
  end
end

# AuthUser 관리 클래스
class AuthUserManager
  def initialize
    @auth_users = []
    @next_id = 1
  end
  
  # 회원가입
  def register(username, email, password)
    # 이미 존재하는 사용자명/이메일 확인
    if @auth_users.any? { |u| u.username == username }
      return { success: false, error: "이미 존재하는 사용자명입니다.", data: nil }
    end
    
    if @auth_users.any? { |u| u.email == email }
      return { success: false, error: "이미 존재하는 이메일입니다.", data: nil }
    end
    
    # 비밀번호 해시화
    password_hash = PasswordHelper.hash_password(password)
    current_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    
    auth_user = AuthUser.new(
      id: @next_id,
      username: username,
      email: email,
      password_hash: password_hash,
      created_at: current_time,
      updated_at: current_time
    )
    
    unless auth_user.valid?
      return { success: false, error: "유효하지 않은 사용자 정보입니다.", data: nil }
    end
    
    @auth_users << auth_user
    @next_id += 1
    { success: true, message: "회원가입이 완료되었습니다.", data: auth_user.to_hash }
  end
  
  # 로그인
  def login(username, password)
    auth_user = @auth_users.find { |u| u.username == username }
    
    if auth_user && PasswordHelper.verify_password(password, auth_user.password_hash)
      { success: true, message: "로그인 성공", data: auth_user.to_hash }
    else
      { success: false, error: "잘못된 사용자명 또는 비밀번호입니다.", data: nil }
    end
  end
  
  # 모든 인증 사용자 조회 (관리자용)
  def get_all_auth_users
    {
      success: true,
      message: "모든 인증 사용자 조회 완료",
      count: @auth_users.length,
      data: @auth_users.map(&:to_hash)
    }
  end
  
  # 특정 인증 사용자 조회
  def get_auth_user_by_id(id)
    auth_user = @auth_users.find { |u| u.id == id }
    if auth_user
      { success: true, message: "사용자를 찾았습니다.", data: auth_user.to_hash }
    else
      { success: false, error: "ID #{id}인 사용자를 찾을 수 없습니다.", data: nil }
    end
  end
  
  # 사용자명으로 검색
  def find_by_username(username)
    auth_user = @auth_users.find { |u| u.username == username }
    if auth_user
      { success: true, message: "사용자를 찾았습니다.", data: auth_user.to_hash }
    else
      { success: false, error: "사용자명 '#{username}'을 찾을 수 없습니다.", data: nil }
    end
  end
  
  # 비밀번호 변경
  def change_password(username, old_password, new_password)
    auth_user = @auth_users.find { |u| u.username == username }
    
    if auth_user.nil? || !PasswordHelper.verify_password(old_password, auth_user.password_hash)
      return { success: false, error: "현재 비밀번호가 일치하지 않습니다.", data: nil }
    end
    
    auth_user.password_hash = PasswordHelper.hash_password(new_password)
    auth_user.updated_at = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    
    { success: true, message: "비밀번호가 성공적으로 변경되었습니다.", data: auth_user.to_hash }
  end
  
  # 계정 삭제
  def delete_auth_user(id)
    user_index = @auth_users.find_index { |u| u.id == id }
    
    if user_index.nil?
      return { success: false, error: "ID #{id}인 사용자를 찾을 수 없습니다.", data: nil }
    end
    
    deleted_user = @auth_users.delete_at(user_index)
    { success: true, message: "계정이 삭제되었습니다.", data: deleted_user.to_hash }
  end
end

# Sinatra API 애플리케이션
class RubyCrudAPI < Sinatra::Base
  
  def initialize
    super
    @user_manager = UserManager.new
    @auth_user_manager = AuthUserManager.new
    
    # 테스트용 더미 데이터 추가
    @user_manager.create_user("홍길동", "hong@example.com", 25, created_by: "admin")
    @user_manager.create_user("김영희", "kim@example.com", 30, created_by: "admin")
    
    # 테스트용 인증 사용자 추가
    @auth_user_manager.register("admin", "admin@example.com", "admin123")
    @auth_user_manager.register("testuser", "test@example.com", "test123")
    
    puts "🚀 Ruby CRUD API가 시작되었습니다!"
    puts "📊 테스트 데이터가 로드되었습니다."
  end
  
  # CORS 설정 (프론트엔드와 연동할 때 필요)
  before do
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    content_type :json
  end
  
  # OPTIONS 요청 처리 (CORS preflight)
  options '*' do
    200
  end
  
  # 에러 핸들링
  error do
    status 500
    { success: false, error: "서버 내부 오류가 발생했습니다." }.to_json
  end
  
  # GET / - API 정보
  get '/' do
    {
      success: true,
      message: "Ruby CRUD API",
      version: "1.0.0",
      description: "Ruby를 이용한 사용자 관리 및 인증 API",
      database: "Connected",
      endpoints: {
        # User Management
        "GET /users" => "모든 사용자 조회",
        "GET /users/:id" => "특정 사용자 조회",
        "POST /users" => "새 사용자 생성",
        "PUT /users/:id" => "사용자 정보 수정",
        "DELETE /users/:id" => "사용자 삭제",
        "GET /users/search/:name" => "이름으로 사용자 검색",
        "GET /stats" => "사용자 통계",
        
        # Authentication
        "POST /auth/register" => "회원가입",
        "POST /auth/login" => "로그인",
        "GET /auth/users" => "모든 인증 사용자 조회",
        "GET /auth/users/:id" => "특정 인증 사용자 조회",
        "GET /auth/username/:username" => "사용자명으로 검색",
        "PUT /auth/password" => "비밀번호 변경",
        "DELETE /auth/users/:id" => "계정 삭제"
      }
    }.to_json
  end
  
  # ==================== 사용자 관리 API ====================
  
  # GET /users - 모든 사용자 조회
  get '/users' do
    result = @user_manager.read_all_users
    status 200
    result.to_json
  end
  
  # GET /users/:id - 특정 사용자 조회
  get '/users/:id' do
    id = params[:id].to_i
    result = @user_manager.read_user_by_id(id)
    
    if result[:success]
      status 200
    else
      status 404
    end
    
    result.to_json
  end
  
  # POST /users - 새 사용자 생성
  post '/users' do
    begin
      # JSON 파싱
      request_payload = JSON.parse(request.body.read)
      name = request_payload['name']
      email = request_payload['email']
      age = request_payload['age']
      created_by = request_payload['created_by'] || 'api_user'
      
      result = @user_manager.create_user(name, email, age, created_by: created_by)
      
      if result[:success]
        status 201  # Created
      else
        status 400  # Bad Request
      end
      
      result.to_json
      
    rescue JSON::ParserError
      status 400
      { success: false, error: "잘못된 JSON 형식입니다." }.to_json
    end
  end
  
  # PUT /users/:id - 사용자 정보 수정
  put '/users/:id' do
    begin
      id = params[:id].to_i
      request_payload = JSON.parse(request.body.read)
      
      result = @user_manager.update_user(
        id,
        name: request_payload['name'],
        email: request_payload['email'],
        age: request_payload['age'],
        updated_by: request_payload['updated_by'] || 'api_user'
      )
      
      if result[:success]
        status 200
      else
        status 404
      end
      
      result.to_json
      
    rescue JSON::ParserError
      status 400
      { success: false, error: "잘못된 JSON 형식입니다." }.to_json
    end
  end
  
  # DELETE /users/:id - 사용자 삭제
  delete '/users/:id' do
    id = params[:id].to_i
    result = @user_manager.delete_user(id)
    
    if result[:success]
      status 200
    else
      status 404
    end
    
    result.to_json
  end
  
  # GET /users/search/:name - 이름으로 사용자 검색
  get '/users/search/:name' do
    name = params[:name]
    result = @user_manager.search_users_by_name(name)
    status 200
    result.to_json
  end
  
  # GET /stats - 사용자 통계
  get '/stats' do
    result = @user_manager.get_stats
    status 200
    result.to_json
  end
  
  # ==================== 인증 관련 API ====================
  
  # POST /auth/register - 회원가입
  post '/auth/register' do
    begin
      request_payload = JSON.parse(request.body.read)
      username = request_payload['username']
      email = request_payload['email']
      password = request_payload['password']
      
      result = @auth_user_manager.register(username, email, password)
      
      if result[:success]
        status 201
      else
        status 400
      end
      
      result.to_json
      
    rescue JSON::ParserError
      status 400
      { success: false, error: "잘못된 JSON 형식입니다." }.to_json
    end
  end
  
  # POST /auth/login - 로그인
  post '/auth/login' do
    begin
      request_payload = JSON.parse(request.body.read)
      username = request_payload['username']
      password = request_payload['password']
      
      result = @auth_user_manager.login(username, password)
      
      if result[:success]
        status 200
      else
        status 401  # Unauthorized
      end
      
      result.to_json
      
    rescue JSON::ParserError
      status 400
      { success: false, error: "잘못된 JSON 형식입니다." }.to_json
    end
  end
  
  # GET /auth/users - 모든 인증 사용자 조회 (관리자용)
  get '/auth/users' do
    result = @auth_user_manager.get_all_auth_users
    status 200
    result.to_json
  end
  
  # GET /auth/users/:id - 특정 인증 사용자 조회
  get '/auth/users/:id' do
    id = params[:id].to_i
    result = @auth_user_manager.get_auth_user_by_id(id)
    
    if result[:success]
      status 200
    else
      status 404
    end
    
    result.to_json
  end
  
  # GET /auth/username/:username - 사용자명으로 검색
  get '/auth/username/:username' do
    username = params[:username]
    result = @auth_user_manager.find_by_username(username)
    
    if result[:success]
      status 200
    else
      status 404
    end
    
    result.to_json
  end
  
  # PUT /auth/password - 비밀번호 변경
  put '/auth/password' do
    begin
      request_payload = JSON.parse(request.body.read)
      username = request_payload['username']
      old_password = request_payload['old_password']
      new_password = request_payload['new_password']
      
      result = @auth_user_manager.change_password(username, old_password, new_password)
      
      if result[:success]
        status 200
      else
        status 400
      end
      
      result.to_json
      
    rescue JSON::ParserError
      status 400
      { success: false, error: "잘못된 JSON 형식입니다." }.to_json
    end
  end
  
  # DELETE /auth/users/:id - 계정 삭제
  delete '/auth/users/:id' do
    id = params[:id].to_i
    result = @auth_user_manager.delete_auth_user(id)
    
    if result[:success]
      status 200
    else
      status 404
    end
    
    result.to_json
  end
end

# 메인 실행 부분
def main
  puts "🚀 Ruby CRUD API 서버를 시작합니다!"
  
  # 데이터베이스 초기화
  initialize_database
  
  begin
    # Sinatra 서버 실행
    RubyCrudAPI.run! host: 'localhost', port: 4567
    
  rescue Interrupt
    puts "\n\n👋 API 서버가 중단되었습니다."
  rescue StandardError => e
    puts "❌ 오류가 발생했습니다: #{e.message}"
    puts "스택 트레이스:"
    puts e.backtrace
  ensure
    Database.disconnect
    puts "🔌 데이터베이스 연결이 종료되었습니다."
  end
end

# 프로그램 실행
main if __FILE__ == $0